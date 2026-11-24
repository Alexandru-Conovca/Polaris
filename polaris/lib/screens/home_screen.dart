import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/celestial_objects_model.dart';
import '../widgets/celestial_object_card.dart';
import '../widgets/error_view.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onQuest});

  final VoidCallback onQuest;

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CelestialObjectsModel>();
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Good evening'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            'Tonight in the sky',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.wb_sunny_outlined, color: scheme.tertiary),
                      const SizedBox(width: 10),
                      const Text(
                        'Clear conditions',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      Text(
                        '21:42',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    '47.0101° N, 28.8638° E',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Clear Sky\nHumidity 45%',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        'Seeing\n4 / 5',
                        textAlign: TextAlign.right,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Recommended tonight',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              TextButton(onPressed: () {}, child: const Text('View all')),
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
              _ => ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: catalog.items.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, index) => SizedBox(
                  width: 260,
                  child: CelestialObjectCard(object: catalog.items[index]),
                ),
              ),
            },
          ),
          const SizedBox(height: 28),
          Card(
            color: scheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Plan a new adventure',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: scheme.onPrimaryContainer),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Let Polaris pick a challenge for tonight.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: scheme.onPrimaryContainer),
                        ),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: onQuest,
                    child: const Text('Generate quest'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
