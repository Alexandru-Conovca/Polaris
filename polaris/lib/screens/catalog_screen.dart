import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/celestial_object.dart';
import '../data/astronomy_service.dart';
import '../models/domain_models.dart';
import '../models/auth_model.dart';
import '../models/celestial_objects_model.dart';
import '../models/favorites_model.dart';
import '../models/weather_model.dart';
import '../widgets/celestial_object_card.dart';
import '../widgets/error_view.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _searchController = TextEditingController();
  bool _visibleOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CelestialObjectsModel>();
    final isAuthenticated = context.watch<AuthModel>().isAuthenticated;
    final location = context.watch<WeatherModel>().location;
    final astronomy = const AstronomyService();
    final now = DateTime.now().toUtc();
    final positions = <String, HorizontalPosition?>{
      for (final object in catalog.items)
        object.id: location == null
            ? null
            : astronomy.positionFor(
                object: object,
                location: location,
                at: now,
              ),
    };
    final visibleItems = _visibleOnly
        ? catalog.items
              .where((object) => positions[object.id]?.isVisibleNow == true)
              .toList()
        : catalog.items;
    final hasUncalculatedObjects =
        location != null &&
        catalog.items.any((object) => positions[object.id] == null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sky catalogue'),
        actions: isAuthenticated
            ? [
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
              ]
            : [],
      ),
      body: !isAuthenticated
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Card(
                  child: ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: const Text('Каталог доступен после входа'),
                    subtitle: const Text(
                      'Войдите, чтобы загрузить каталог и избранное.',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/login'),
                  ),
                ),
              ),
            )
          : Column(
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FilterChip(
                      selected: _visibleOnly,
                      label: const Text('Видны сейчас · Alt > 15°'),
                      onSelected: (value) => setState(() {
                        _visibleOnly = value;
                      }),
                    ),
                  ),
                ),
                if (_visibleOnly && location == null)
                  TextButton.icon(
                    onPressed: () => context.go('/profile'),
                    icon: const Icon(Icons.location_on_outlined),
                    label: const Text('Укажите точку наблюдения в профиле'),
                  ),
                if (_visibleOnly && hasUncalculatedObjects)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      'Записи без корректных RA/Dec исключены из расчёта.',
                    ),
                  ),
                Expanded(
                  child: switch ((catalog.isLoading, catalog.errorMessage)) {
                    (true, _) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    (false, final String? errorMessage)
                        when errorMessage != null =>
                      Center(
                        child: ErrorView(
                          message: errorMessage,
                          onRetry: () =>
                              context.read<CelestialObjectsModel>().load(),
                        ),
                      ),
                    _ =>
                      visibleItems.isEmpty && !catalog.hasMore
                          ? Center(
                              child: Text(
                                _visibleOnly && location != null
                                    ? hasUncalculatedObjects &&
                                              !positions.values.any(
                                                (position) => position != null,
                                              )
                                          ? 'В каталоге нет корректных RA/Dec для расчёта видимости'
                                          : 'Сейчас нет объектов выше 15° над горизонтом'
                                    : 'Объекты не найдены',
                                textAlign: TextAlign.center,
                              ),
                            )
                          : ListView.builder(
                              itemCount:
                                  visibleItems.length +
                                  (catalog.hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == visibleItems.length) {
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

                                final object = visibleItems[index];
                                final card = CelestialObjectCard(
                                  object: object,
                                  position: positions[object.id],
                                  hasLocation: location != null,
                                  onTap: () {
                                    context.push(
                                      '/catalog/objects/${object.id}',
                                    );
                                  },
                                );
                                if (!isAuthenticated) {
                                  return card;
                                }
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
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                            SnackBar(content: Text(error)),
                                          );
                                      return;
                                    }
                                    context.read<FavoritesModel>().remove(
                                      object,
                                    );
                                  },
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    color: Theme.of(context)
                                        .colorScheme
                                        .errorContainer,
                                    child: const Icon(Icons.delete_outline),
                                  ),
                                  child: card,
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
    final nameController = TextEditingController();
    final coordinatesController = TextEditingController();
    final values = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Добавить объект'),
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
                helperText: 'Например: RA 18h 36m 56s, Dec +38° 47′ 01″',
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
            child: const Text('Добавить'),
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

    final error = await context.read<CelestialObjectsModel>().add(
      CelestialObject(
        id: '',
        name: name,
        type: CelestialType.star,
        description: 'Custom catalogue object.',
        magnitude: 0,
        coordinates: values!['coordinates']!.isEmpty
            ? 'Not specified'
            : values['coordinates']!,
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
