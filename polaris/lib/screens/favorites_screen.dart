import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/auth_model.dart';
import '../models/favorites_model.dart';
import '../widgets/celestial_object_card.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = context.watch<AuthModel>().isAuthenticated;
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: !isAuthenticated
          ? Center(
              child: FilledButton(
                onPressed: () => context.go('/login'),
                child: const Text('Войдите, чтобы открыть избранное'),
              ),
            )
          : Consumer<FavoritesModel>(
              builder: (context, favorites, child) {
                if (favorites.items.isEmpty) {
                  return const Center(child: Text('No favorite objects yet.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: favorites.items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, index) =>
                      CelestialObjectCard(object: favorites.items[index]),
                );
              },
            ),
    );
  }
}
