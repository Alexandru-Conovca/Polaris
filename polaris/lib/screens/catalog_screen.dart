import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/celestial_object.dart';
import '../models/domain_models.dart';
import '../models/celestial_objects_model.dart';
import '../models/favorites_model.dart';
import '../widgets/celestial_object_card.dart';
import '../widgets/error_view.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CelestialObjectsModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sky catalogue'),
        actions: [
          IconButton(
            onPressed: () => context.read<CelestialObjectsModel>().load(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Обновить каталог',
          ),
          IconButton(
            onPressed: () => _showCreateDialog(context),
            icon: const Icon(Icons.add),
            tooltip: 'Add object',
          ),
          Consumer<FavoritesModel>(
            builder: (context, favorites, child) => Badge(
              isLabelVisible: favorites.count > 0,
              label: Text('${favorites.count}'),
              child: child,
            ),
            child: IconButton(
              onPressed: () => context.push('/profile/favorites'),
              icon: const Icon(Icons.bookmarks_outlined),
              tooltip: 'Favorites',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: 'Поиск объектов',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Очистить',
                        onPressed: () {
                          _searchController.clear();
                          context.read<CelestialObjectsModel>().load(
                            search: '',
                          );
                        },
                        icon: const Icon(Icons.clear),
                      ),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (query) {
                context.read<CelestialObjectsModel>().load(
                  search: query.trim(),
                );
              },
            ),
          ),
          Expanded(
            child: switch ((catalog.isLoading, catalog.errorMessage)) {
              (true, _) => const Center(child: CircularProgressIndicator()),
              (false, final String? errorMessage) when errorMessage != null =>
                Center(
                  child: ErrorView(
                    message: errorMessage,
                    onRetry: () => context.read<CelestialObjectsModel>().load(),
                  ),
                ),
              _ =>
                catalog.items.isEmpty
                    ? const Center(child: Text('Объекты не найдены'))
                    : ListView.builder(
                        itemCount:
                            catalog.items.length + (catalog.hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == catalog.items.length) {
                            if (!catalog.isLoadingMore) {
                              catalog.loadMore();
                            }
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            );
                          }

                          final object = catalog.items[index];
                          return Dismissible(
                            key: ValueKey(object.id),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (_) =>
                                _confirmDelete(context, object.name),
                            onDismissed: (_) async {
                              final error = await context
                                  .read<CelestialObjectsModel>()
                                  .remove(object.id);
                              if (!context.mounted) {
                                return;
                              }
                              if (error != null) {
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(SnackBar(content: Text(error)));
                                return;
                              }
                              context.read<FavoritesModel>().remove(object);
                            },
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              color: Theme.of(context)
                                  .colorScheme
                                  .errorContainer,
                              child: const Icon(Icons.delete_outline),
                            ),
                            child: CelestialObjectCard(
                              object: object,
                              onTap: () {
                                context.push('/catalog/objects/${object.id}');
                              },
                            ),
                          );
                        },
                      ),
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Добавить объект'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Название'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (name == null || name.isEmpty || !context.mounted) {
      return;
    }

    final error = await context.read<CelestialObjectsModel>().add(
      CelestialObject(
        id: '',
        name: name,
        type: CelestialType.star,
        description: 'Custom catalogue object.',
        magnitude: 0,
        coordinates: 'Not specified',
        constellation: 'Not specified',
        isVisibleNow: true,
      ),
    );
    if (!context.mounted || error == null) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }

  Future<bool?> _confirmDelete(BuildContext context, String name) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удалить объект?'),
        content: Text('Удалить $name из каталога?'),
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
  }
}
