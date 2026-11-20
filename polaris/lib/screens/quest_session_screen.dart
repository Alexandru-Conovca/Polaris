import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/api_config.dart';
import '../data/result.dart';
import '../models/quest_session_model.dart';

class QuestSessionScreen extends StatelessWidget {
  const QuestSessionScreen({super.key});

  Future<void> _pickAndUpload(BuildContext context) async {
    final files = await FilePicker.pickFiles(type: FileType.image);
    if (files.isEmpty || !context.mounted) {
      return;
    }

    final file = files.single;
    final bytes = file.path == null ? await file.readAsBytes() : null;
    if (!context.mounted) {
      return;
    }
    final model = context.read<QuestSessionModel>();
    final uploadResult = await model.uploadPhoto(
      path: file.path ?? '',
      bytes: bytes,
      filename: file.name,
    );
    if (!context.mounted) {
      return;
    }
    switch (uploadResult) {
      case Ok():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Фото подтверждения загружено')),
        );
      case Err(:final msg):
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<QuestSessionModel>();
    final quest = model.quest;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quest session'),
        actions: [
          if (model.isComplete)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  'Completed',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quest.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(quest.description),
                  const SizedBox(height: 12),
                  Text(
                    'Цель: выполнить ${quest.tasksCount} observation tasks.',
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(color: scheme.primary),
                  ),
                  const SizedBox(height: 8),
                  Text('Difficulty: ${quest.difficulty.name}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Observation conditions',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sky: clear'),
                  SizedBox(height: 4),
                  Text('Visibility: good'),
                  SizedBox(height: 4),
                  Text('Temperature: 12 °C'),
                  SizedBox(height: 4),
                  Text('Wind: 8 km/h'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Mission checklist',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          ...model.steps.asMap().entries.map(
            (entry) => CheckboxListTile(
              value: entry.value,
              title: Text(model.defaultSteps[entry.key]),
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (value) {
                model.toggleStep(entry.key, value ?? false);
              },
            ),
          ),
          const SizedBox(height: 16),
          Text('Observer notes', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: model.notes,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Запишите условия, видимые детали и результат...',
              border: OutlineInputBorder(),
            ),
            onChanged: model.updateNotes,
          ),
          const SizedBox(height: 16),
          Text(
            'Photo confirmation',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          if (model.errorMessage != null)
            Card(
              color: scheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  model.errorMessage!,
                  style: TextStyle(color: scheme.onErrorContainer),
                ),
              ),
            ),
          if (model.imageUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                '$apiBase${model.imageUrl}',
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox(
                  height: 220,
                  child: Center(child: Text('Не удалось показать фото')),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          OutlinedButton.icon(
            onPressed: model.isUploading ? null : () => _pickAndUpload(context),
            icon: model.isUploading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.photo_camera_outlined),
            label: Text(
              model.isUploading ? 'Загрузка...' : 'Выбрать и загрузить фото',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: model.isSaving
                ? null
                : () async {
                    final completed = model.steps.every((step) => step);
                    await model.save(complete: completed);
                    if (!context.mounted) {
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          completed
                              ? 'Квест выполнен и прогресс сохранён'
                              : 'Прогресс сохранён',
                        ),
                      ),
                    );
                  },
            icon: model.isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(
              model.isSaving ? 'Сохранение...' : 'Сохранить прогресс',
            ),
          ),
        ],
      ),
    );
  }
}
