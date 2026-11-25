import 'package:flutter/material.dart';

import '../models/domain_models.dart';
import 'stat_badge.dart';

class QuestCard extends StatelessWidget {
  const QuestCard({super.key, required this.quest, this.onTap});

  final Quest quest;
  final VoidCallback? onTap;

  String get _difficulty => switch (quest.difficulty) {
    QuestDifficulty.beginner => 'Beginner',
    QuestDifficulty.intermediate => 'Intermediate',
    QuestDifficulty.advanced => 'Advanced',
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      quest.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  StatBadge(label: _difficulty, color: scheme.secondary),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                quest.description,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(Icons.checklist, size: 18, color: scheme.primary),
                  const SizedBox(width: 6),
                  Text('${quest.tasksCount} tasks'),
                  const Spacer(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
