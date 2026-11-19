import 'package:flutter/foundation.dart';

import '../data/celestial_object.dart';
import '../data/celestial_object_repository.dart';
import '../data/result.dart';

class CelestialObjectsModel extends ChangeNotifier {
  CelestialObjectsModel(this._repository);

  final CelestialObjectRepository _repository;

  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  List<CelestialObject> _items = const [];
  String _search = '';
  int _page = 1;
  bool _hasMore = false;

  static const int _limit = 20;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  bool get isLoadingMore => _isLoadingMore;

  bool get hasMore => _hasMore;

  String get search => _search;

  List<CelestialObject> get items => List.unmodifiable(_items);

  CelestialObject? byId(String id) {
    for (final object in _items) {
      if (object.id == id) {
        return object;
      }
    }

    return null;
  }

  Future<void> load({String? search}) async {
    _search = search ?? _search;
    _page = 1;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.fetchAll(
      page: _page,
      limit: _limit,
      search: _search,
    );
    switch (result) {
      case Ok(value: final objects):
        _items = objects;
        _hasMore = objects.length == _limit;
      case Err(msg: final message):
        _errorMessage = message;
        _hasMore = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || _isLoading || !_hasMore) {
      return;
    }

    _isLoadingMore = true;
    final nextPage = _page + 1;
    final result = await _repository.fetchAll(
      page: nextPage,
      limit: _limit,
      search: _search,
    );

    switch (result) {
      case Ok(value: final objects):
        _page = nextPage;
        _items = [..._items, ...objects];
        _hasMore = objects.length == _limit;
        _errorMessage = null;
      case Err(msg: final message):
        _errorMessage = message;
        _hasMore = false;
    }

    _isLoadingMore = false;
    notifyListeners();
  }

  Future<String?> add(CelestialObject draft) async {
    switch (await _repository.create(draft)) {
      case Ok(value: final object):
        _items = [..._items, object];
        notifyListeners();
        return null;
      case Err(msg: final message):
        return message;
    }
  }

  Future<String?> remove(String id) async {
    switch (await _repository.delete(id)) {
      case Ok():
        _items = _items.where((object) => object.id != id).toList();
        notifyListeners();
        return null;
      case Err(msg: final message):
        return message;
    }
  }

  Future<String?> update(CelestialObject object) async {
    switch (await _repository.update(object)) {
      case Ok(value: final updated):
        _items = [
          for (final item in _items)
            if (item.id == updated.id) updated else item,
        ];
        notifyListeners();
        return null;
      case Err(msg: final message):
        return message;
    }
  }
}
