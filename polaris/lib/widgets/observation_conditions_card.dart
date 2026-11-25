import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/result.dart';
import '../models/observation_location.dart';
import '../models/weather_model.dart';
import '../models/weather_snapshot.dart';
import 'manual_location_dialog.dart';

class ObservationConditionsCard extends StatefulWidget {
  const ObservationConditionsCard({super.key});

  @override
  State<ObservationConditionsCard> createState() =>
      _ObservationConditionsCardState();
}

class _ObservationConditionsCardState extends State<ObservationConditionsCard> {
  GoRouter? _router;
  bool _expanded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final router = GoRouter.of(context);
    if (identical(router, _router)) {
      return;
    }
    _router?.routerDelegate.removeListener(_handleRouteChange);
    _router = router;
    _router!.routerDelegate.addListener(_handleRouteChange);
    _expanded = false;
  }

  @override
  void dispose() {
    _router?.routerDelegate.removeListener(_handleRouteChange);
    super.dispose();
  }

  void _handleRouteChange() {
    if (_expanded) {
      setState(() {
        _expanded = false;
      });
    }
  }

  Future<void> _refreshLocation(BuildContext context) async {
    final model = context.read<WeatherModel>();
    final locationResult = await model.refreshLocation();
    if (!context.mounted) {
      return;
    }
    if (locationResult case Err()) {
      return;
    }
    await model.refreshWeather();
  }

  Future<void> _editLocation(BuildContext context) async {
    final location = await showManualLocationDialog(context);
    if (location == null || !context.mounted) {
      return;
    }
    final model = context.read<WeatherModel>();
    final result = await model.saveLocation(location);
    if (!context.mounted) {
      return;
    }
    if (result case Ok()) {
      await model.refreshWeather();
    }
  }

  Future<void> _openSettings(BuildContext context) async {
    final result = await context.read<WeatherModel>().openLocationSettings();
    if (!context.mounted) {
      return;
    }
    if (result case Err(msg: final message)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  String _summary(
    ObservationLocation? location,
    WeatherSnapshot? weather, {
    required bool isRefreshingLocation,
    required bool isRefreshingWeather,
    required String? weatherErrorMessage,
  }) {
    if (location == null) {
      return isRefreshingLocation
          ? 'Определяем местоположение...'
          : 'Добавьте точку наблюдения';
    }

    final parts = <String>[
      '${location.latitude.toStringAsFixed(2)}°, '
          '${location.longitude.toStringAsFixed(2)}°',
    ];
    if (weather?.temperatureC case final temperature?) {
      parts.add('${temperature.toStringAsFixed(0)} °C');
    }
    if (weather?.cloudCover case final cloudCover?) {
      parts.add('облачность ${cloudCover.toStringAsFixed(0)}%');
    }
    if (weather == null) {
      parts.add(
        isRefreshingWeather
            ? 'загружаем погоду'
            : weatherErrorMessage == null
            ? 'погода не загружена'
            : 'погода недоступна',
      );
    }
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<WeatherModel>();
    final location = model.location;
    final weather = model.currentWeather;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _expanded = !_expanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    location == null
                        ? Icons.location_searching
                        : Icons.location_on_outlined,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Точка и условия наблюдения',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _summary(
                            location,
                            weather,
                            isRefreshingLocation: model.isRefreshingLocation,
                            isRefreshingWeather: model.isRefreshingWeather,
                            weatherErrorMessage: model.weatherErrorMessage,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (location == null && model.isRefreshingLocation)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      color: scheme.onSurfaceVariant,
                    ),
                ],
              ),
            ),
          ),
          if (!_expanded && location == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: model.isRefreshingLocation
                        ? null
                        : () => _refreshLocation(context),
                    icon: const Icon(Icons.my_location),
                    label: const Text('Получить GPS'),
                  ),
                  TextButton(
                    onPressed: () => _editLocation(context),
                    child: const Text('Ввести координаты'),
                  ),
                ],
              ),
            ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            alignment: Alignment.topCenter,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        Text(
                          'Место наблюдения',
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 6),
                        if (location == null)
                          const Text('Местоположение пока не задано.')
                        else ...[
                          Text(
                            'Широта ${location.latitude.toStringAsFixed(5)}°, '
                            'долгота ${location.longitude.toStringAsFixed(5)}°',
                          ),
                          if (location.altitude != null)
                            Text(
                              'Высота: ${location.altitude!.toStringAsFixed(1)} м',
                            ),
                          if (location.accuracy != null)
                            Text(
                              'Точность GPS: '
                              '${location.accuracy!.toStringAsFixed(1)} м',
                            ),
                          Text(
                            '${location.source == ObservationLocationSource.device ? 'GPS' : 'Вручную'} · '
                            '${location.timestamp.toLocal()}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                        if (model.locationErrorMessage != null)
                          _Message(
                            text: model.locationErrorMessage!,
                            color: scheme.error,
                          ),
                        const SizedBox(height: 16),
                        Text('Погода', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 6),
                        if (weather == null)
                          Text(
                            model.isRefreshingWeather
                                ? 'Загружаем прогноз...'
                                : 'Прогноз для этой точки недоступен.',
                          )
                        else
                          _WeatherDetails(weather: weather),
                        if (weather != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              'Прогноз на ${weather.forecastAt.toLocal()} · Open-Meteo',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        if (model.weatherErrorMessage != null)
                          _Message(
                            text: model.weatherErrorMessage!,
                            color: scheme.error,
                          ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            OutlinedButton.icon(
                              onPressed: model.isRefreshingLocation
                                  ? null
                                  : () => _refreshLocation(context),
                              icon: model.isRefreshingLocation
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.my_location),
                              label: const Text('Обновить GPS'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _editLocation(context),
                              icon: const Icon(
                                Icons.edit_location_alt_outlined,
                              ),
                              label: const Text('Координаты'),
                            ),
                            FilledButton.tonalIcon(
                              onPressed:
                                  location == null || model.isRefreshingWeather
                                  ? null
                                  : () => model.refreshWeather(),
                              icon: model.isRefreshingWeather
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.refresh),
                              label: const Text('Обновить погоду'),
                            ),
                            TextButton(
                              onPressed: () => _openSettings(context),
                              child: const Text('Настройки геолокации'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _WeatherDetails extends StatelessWidget {
  const _WeatherDetails({required this.weather});

  final WeatherSnapshot weather;

  @override
  Widget build(BuildContext context) {
    final temperature = weather.temperatureC;
    final dewPoint = weather.dewPointC;
    final dewPointSpread = temperature == null || dewPoint == null
        ? null
        : temperature - dewPoint;
    final condensationRisk = dewPointSpread == null
        ? null
        : dewPointSpread <= 2
        ? 'Высокий риск запотевания'
        : dewPointSpread <= 5
        ? 'Возможное запотевание'
        : 'Низкий риск запотевания';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (temperature != null)
          Text('Температура: ${temperature.toStringAsFixed(1)} °C'),
        if (dewPoint != null)
          Text('Точка росы: ${dewPoint.toStringAsFixed(1)} °C'),
        if (condensationRisk != null)
          Text(
            '$condensationRisk (Δ ${dewPointSpread!.toStringAsFixed(1)} °C)',
          ),
        if (weather.cloudCover != null)
          Text('Облачность: ${weather.cloudCover!.toStringAsFixed(0)}%'),
        if (weather.cloudCoverLow != null)
          Text(
            'Нижний ярус облаков: ${weather.cloudCoverLow!.toStringAsFixed(0)}%',
          ),
        if (weather.cloudCoverMid != null)
          Text(
            'Средний ярус облаков: ${weather.cloudCoverMid!.toStringAsFixed(0)}%',
          ),
        if (weather.cloudCoverHigh != null)
          Text(
            'Верхний ярус облаков: ${weather.cloudCoverHigh!.toStringAsFixed(0)}%',
          ),
        if (weather.relativeHumidity != null)
          Text('Влажность: ${weather.relativeHumidity!.toStringAsFixed(0)}%'),
        if (weather.windSpeedKmh != null)
          Text('Ветер: ${weather.windSpeedKmh!.toStringAsFixed(1)} км/ч'),
        if (weather.windGustKmh != null)
          Text('Порывы: ${weather.windGustKmh!.toStringAsFixed(1)} км/ч'),
        if (weather.precipitationProbability != null)
          Text(
            'Вероятность осадков: '
            '${weather.precipitationProbability!.toStringAsFixed(0)}%',
          ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text(text, style: TextStyle(color: color)),
  );
}
