import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/file_api.dart';
import '../data/result.dart';
import 'domain_models.dart';

class QuestSessionModel extends ChangeNotifier {
  QuestSessionModel(this.fileApi, this.quest) {
    _restore();
  }

  final FileApi fileApi;
  final Quest quest;

  List<bool> _steps = List<bool>.filled(6, false);
  String _notes = '';
  String? _imageUrl;
  bool _isUploading = false;
  bool _isSaving = false;
  bool _isComplete = false;
  String? _errorMessage;

  bool get isUploading => _isUploading;
  bool get isSaving => _isSaving;
  bool get isComplete => _isComplete;
  bool get hasPhoto => _imageUrl != null;
  String? get imageUrl => _imageUrl;
  String get notes => _notes;
  String? get errorMessage => _errorMessage;
  List<bool> get steps => List.unmodifiable(_steps);

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('quest_session_${quest.id}');
    if (saved != null) {
      try {
        final data = jsonDecode(saved) as Map<String, dynamic>;
        final savedSteps = data['steps'] as List?;
        _steps = List<bool>.generate(
          defaultSteps.length,
          (index) => index < (savedSteps?.length ?? 0)
              ? savedSteps![index] as bool
              : false,
        );
        _notes = data['notes'] as String? ?? '';
        _imageUrl = data['imageUrl'] as String?;
        _isComplete = data['isComplete'] as bool? ?? false;
        notifyListeners();
        return;
      } on FormatException catch (_) {
        // Ignore corrupted local session data.
      } on TypeError catch (_) {
        // Ignore corrupted local session data.
      }
    }
    _steps = List<bool>.filled(defaultSteps.length, false);
  }

  List<String> get defaultSteps => [
    'Locate the target',
    'Check the observing conditions',
    'Set up the telescope',
    'Capture the observation',
    'Record field notes',
    'Upload photo confirmation',
  ];

  void toggleStep(int index, bool value) {
    _steps[index] = value;
    notifyListeners();
  }

  void updateNotes(String value) {
    _notes = value;
  }

  Future<Result<void>> uploadPhoto({
    required String path,
    List<int>? bytes,
    required String filename,
  }) async {
    if (_isUploading) {
      return const Err('Фото уже загружается');
    }

    _isUploading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await fileApi.upload(path, bytes: bytes, filename: filename);

    switch (result) {
      case Ok(value: final imageUrl):
        _imageUrl = imageUrl;
        if (_steps.isNotEmpty) {
          _steps[_steps.length - 1] = true;
        }
      case Err(msg: final message):
        _errorMessage = message;
    }

    _isUploading = false;
    notifyListeners();
    return switch (result) {
      Ok() => const Ok(null),
      Err(msg: final message) => Err(message),
    };
  }

  Future<String?> save({bool complete = false}) async {
    _isSaving = true;
    notifyListeners();

    _isComplete = complete;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'quest_session_${quest.id}',
      jsonEncode({
        'steps': _steps,
        'notes': _notes,
        'imageUrl': _imageUrl,
        'isComplete': _isComplete,
      }),
    );

    _isSaving = false;
    notifyListeners();
    return null;
  }

  Future<void> clearError() async {
    _errorMessage = null;
    notifyListeners();
  }
}
