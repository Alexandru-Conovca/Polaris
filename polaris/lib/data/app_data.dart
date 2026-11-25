import '../models/domain_models.dart';

const quests = [
  Quest(
    id: 'solar',
    title: 'Tour of the Solar System',
    description:
        'Visit bright planets and learn to read their changing positions.',
    difficulty: QuestDifficulty.beginner,
    tasksCount: 5,
  ),
  Quest(
    id: 'deep-sky',
    title: 'Deep Sky Wonders of Autumn',
    description: 'Build confidence finding galaxies and nebulae beyond our neighborhood.',
    difficulty: QuestDifficulty.intermediate,
    tasksCount: 8,
  ),
  Quest(
    id: 'binary',
    title: 'Binary Star Hunt',
    description:
        'Resolve colorful double stars and compare their apparent brightness.',
    difficulty: QuestDifficulty.intermediate,
    tasksCount: 6,
  ),
  Quest(
    id: 'messier',
    title: 'Messier Challenge: Part 1',
    description:
        'Start a classic catalogue with ten rewarding Messier objects.',
    difficulty: QuestDifficulty.advanced,
    tasksCount: 10,
  ),
  Quest(
    id: 'moon',
    title: 'Moonwatch: Mare and Craters',
    description:
        'Learn lunar geography by tracing seas, craters, and mountain ranges.',
    difficulty: QuestDifficulty.beginner,
    tasksCount: 7,
  ),
  Quest(
    id: 'summer',
    title: 'Summer Triangle Field Notes',
    description:
        'Map three bright stars and discover the objects hidden around them.',
    difficulty: QuestDifficulty.intermediate,
    tasksCount: 6,
  ),
];
