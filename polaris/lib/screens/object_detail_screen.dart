import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/astronomy_service.dart';
import '../data/celestial_object.dart';
import '../models/auth_model.dart';
import '../models/celestial_objects_model.dart';
import '../models/favorites_model.dart';
import '../models/weather_model.dart';
import '../widgets/error_view.dart';
import '../widgets/stat_badge.dart';

class ObjectDetailScreen extends StatelessWidget {
  const ObjectDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    if (!context.watch<AuthModel>().isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Object')),
        body: Center(
          child: FilledButton(
            onPressed: () => context.go('/login'),
            child: const Text('Войдите, чтобы открыть объект'),
          ),
        ),
      );
    }

    final model = context.watch<CelestialObjectsModel>();
    final object = model.byId(id);

    if (model.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (model.errorMessage case final message?) {
      return Scaffold(
        appBar: AppBar(title: const Text('Object')),
        body: ErrorView(
          message: message,
          onRetry: () => context.read<CelestialObjectsModel>().load(),
        ),
      );
    }

    if (object == null) {
      return const Scaffold(body: Center(child: Text('Запись не существует')));
    }

    return _ObjectDetails(object: object);
  }
}

class _ObjectDetails extends StatelessWidget {
  const _ObjectDetails({required this.object});

  final CelestialObject object;

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesModel>();
    final isAuthenticated = context.watch<AuthModel>().isAuthenticated;
    final location = context.watch<WeatherModel>().location;
    final position = location == null
        ? null
        : const AstronomyService().positionFor(
            object: object,
            location: location,
          );
    final isFavorite = favorites.contains(object);
    final scheme = Theme.of(context).colorScheme;
    final visibilityLabel = location == null
        ? 'Укажите точку'
        : position?.statusLabel ?? 'Нет RA/Dec';

    return Scaffold(
      appBar: AppBar(
        title: Text(object.name),
        actions: [
          if (isAuthenticated) ...[
            IconButton(
              onPressed: () => _editObject(context, object),
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Изменить',
            ),
            IconButton(
              onPressed: () => _deleteObject(context, object),
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Удалить',
            ),
          ],
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 190,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.brightness_3, size: 88, color: scheme.primary),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  object.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              StatBadge(
                label: visibilityLabel,
                color: position?.isVisibleNow == true
                    ? scheme.tertiary
                    : scheme.outline,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            object.description,
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _Parameter(
                label: 'Magnitude',
                value: object.magnitude.toStringAsFixed(1),
              ),
              _Parameter(label: 'Coordinates', value: object.coordinates),
              _Parameter(label: 'Constellation', value: object.constellation),
              _Parameter(
                label: 'Оценка яркости',
                value: const AstronomyService().brightnessHint(
                  object.magnitude,
                ),
              ),
              if (position != null) ...[
                _Parameter(
                  label: 'Высота над горизонтом',
                  value: '${position.altitudeDegrees.toStringAsFixed(1)}°',
                ),
                _Parameter(
                  label: 'Азимут',
                  value: '${position.azimuthDegrees.toStringAsFixed(1)}°',
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/quests/session/solar'),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Начать наблюдение'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    context.read<FavoritesModel>().toggle(object);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isFavorite
                              ? '${object.name} удалён из избранного'
                              : '${object.name} добавлен в избранное',
                        ),
                      ),
                    );
                  },
                  icon: Icon(
                    isFavorite ? Icons.bookmark : Icons.bookmark_border,
                  ),
                  label: Text(
                    isFavorite ? 'Удалить из избранного' : 'В избранное',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _editObject(BuildContext context, CelestialObject object) async {
    final nameController = TextEditingController(text: object.name);
    final coordinatesController = TextEditingController(
      text: object.coordinates,
    );
    final values = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Изменить объект'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Название'),
            ),
            TextField(
              controller: coordinatesController,
              decoration: const InputDecoration(
                labelText: 'Экваториальные координаты',
                helperText: 'Формат RA 18h 36m 56s, Dec +38° 47′ 01″',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, {
              'name': nameController.text.trim(),
              'coordinates': coordinatesController.text.trim(),
            }),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    nameController.dispose();
    coordinatesController.dispose();

    final name = values?['name'];
    if (name == null || name.isEmpty || !context.mounted) {
      return;
    }

    final updated = object.copyWith(
      name: name,
      coordinates: values!['coordinates']!,
    );
    final error = await context.read<CelestialObjectsModel>().update(updated);
    if (!context.mounted) {
      return;
    }
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    context.read<FavoritesModel>().update(updated);
  }

  Future<void> _deleteObject(
    BuildContext context,
    CelestialObject object,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удалить объект?'),
        content: Text('Удалить ${object.name} из каталога?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }

    final error = await context.read<CelestialObjectsModel>().remove(object.id);
    if (!context.mounted) {
      return;
    }
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    context.read<FavoritesModel>().remove(object);
    context.pop();
  }
}

class _Parameter extends StatelessWidget {
  const _Parameter({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: (MediaQuery.sizeOf(context).width - 42) / 2,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 5),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
      ),
    ),
  );
}
