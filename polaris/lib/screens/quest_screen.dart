import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/app_data.dart';
import '../models/domain_models.dart';
import '../widgets/quest_card.dart';

class QuestScreen extends StatelessWidget {
  const QuestScreen({super.key, this.quest});
  final Quest? quest;

  @override
  Widget build(BuildContext context) {
    final selectedQuest = quest ?? quests[1];
    final scheme = Theme.of(context).colorScheme;
    final tasks = [
      'Locate Cassiopeia',
      'Center M31 in the eyepiece',
      'Compare the galaxy core and halo',
      'Take an observation log',
      'Mark the sky conditions',
      'Upload the observation for verification',
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Observation quest')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          QuestCard(quest: selectedQuest),
          const SizedBox(height: 20),
          Text(
            'Mission checklist',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          ...tasks.asMap().entries.map(
            (entry) => Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: scheme.surfaceContainerHighest,
                  child: Text('${entry.key + 1}'),
                ),
                title: Text(entry.value),
                trailing: const Icon(Icons.radio_button_unchecked),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () =>
                context.push('/quests/session/${selectedQuest.id}'),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Begin quest session'),
          ),
        ],
      ),
    );
  }
}
