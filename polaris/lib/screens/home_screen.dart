import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/astronomy_service.dart';
import '../models/auth_model.dart';
import '../models/celestial_objects_model.dart';
import '../models/weather_model.dart';
import '../widgets/celestial_object_card.dart';
import '../widgets/error_view.dart';
import '../widgets/observation_conditions_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = context.watch<AuthModel>().isAuthenticated;
    final catalog = context.watch<CelestialObjectsModel>();
    final location = context.watch<WeatherModel>().location;
    final astronomy = const AstronomyService();
    return Scaffold(
      appBar: AppBar(title: const Text('Polaris')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            'Условия наблюдения',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          const ObservationConditionsCard(),
          if (isAuthenticated) ...[
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Объекты из каталога',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/catalog'),
                  child: const Text('View all'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 170,
              child: switch ((catalog.isLoading, catalog.errorMessage)) {
                (true, _) => const Center(child: CircularProgressIndicator()),
                (false, final String? errorMessage) when errorMessage != null =>
                  ErrorView(
                    message: errorMessage,
                    onRetry: () => context.read<CelestialObjectsModel>().load(),
                  ),
                (false, _) when catalog.items.isEmpty => const Center(
                  child: Text('В каталоге пока нет объектов.'),
                ),
                _ => ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: catalog.items.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (_, index) => SizedBox(
                    width: 260,
                    child: CelestialObjectCard(
                      object: catalog.items[index],
                      hasLocation: location != null,
                      position: location == null
                          ? null
                          : astronomy.positionFor(
                              object: catalog.items[index],
                              location: location,
                            ),
                    ),
                  ),
                ),
              },
            ),
          ] else ...[
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Каталог доступен после входа'),
                subtitle: const Text(
                  'Войдите, чтобы загрузить каталог и рекомендации.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/login'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
