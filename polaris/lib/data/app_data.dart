import '../models/domain_models.dart';

const quests = [
  Quest(
    id: 'solar',
    title: 'Tour of the Solar System',
    description:
        'Visit bright planets and learn to read their changing positions.',
    difficulty: QuestDifficulty.beginner,
    tasksCount: 5,
    createdAt: 'September 2026',
  ),
  Quest(
    id: 'deep-sky',
    title: 'Deep Sky Wonders of Autumn',
    description: 'Build confidence finding galaxies and nebulae beyond our neighborhood.',
    difficulty: QuestDifficulty.intermediate,
    tasksCount: 8,
    createdAt: 'September 2026',
  ),
  Quest(
    id: 'binary',
    title: 'Binary Star Hunt',
    description:
        'Resolve colorful double stars and compare their apparent brightness.',
    difficulty: QuestDifficulty.intermediate,
    tasksCount: 6,
    createdAt: 'August 2026',
  ),
  Quest(
    id: 'messier',
    title: 'Messier Challenge: Part 1',
    description:
        'Start a classic catalogue with ten rewarding Messier objects.',
    difficulty: QuestDifficulty.advanced,
    tasksCount: 10,
    createdAt: 'August 2026',
  ),
  Quest(
    id: 'moon',
    title: 'Moonwatch: Mare and Craters',
    description:
        'Learn lunar geography by tracing seas, craters, and mountain ranges.',
    difficulty: QuestDifficulty.beginner,
    tasksCount: 7,
    createdAt: 'July 2026',
  ),
  Quest(
    id: 'summer',
    title: 'Summer Triangle Field Notes',
    description:
        'Map three bright stars and discover the objects hidden around them.',
    difficulty: QuestDifficulty.intermediate,
    tasksCount: 6,
    createdAt: 'July 2026',
  ),
];

const observations = [
  Observation(
    id: 'obs-1',
    objectName: 'Saturn',
    dateTime: '18 Sep 2026, 22:14',
    location: 'Chișinău, 47.0101° N',
    status: 'Verified',
    questTitle: 'Tour of the Solar System',
  ),
  Observation(
    id: 'obs-2',
    objectName: 'Vega',
    dateTime: '16 Sep 2026, 21:48',
    location: 'Chișinău, 28.8638° E',
    status: 'Verified',
    questTitle: 'Binary Star Hunt',
  ),
  Observation(
    id: 'obs-3',
    objectName: 'Andromeda Galaxy (M31)',
    dateTime: '12 Sep 2026, 23:02',
    location: 'Orhei, 47.3833° N',
    status: 'Pending',
    questTitle: 'Deep Sky Wonders of Autumn',
  ),
  Observation(
    id: 'obs-4',
    objectName: 'Mars',
    dateTime: '08 Sep 2026, 21:35',
    location: 'Chișinău, 28.8638° E',
    status: 'Verified',
    questTitle: 'Tour of the Solar System',
  ),
  Observation(
    id: 'obs-5',
    objectName: 'Albireo',
    dateTime: '01 Sep 2026, 22:21',
    location: 'Codru, 46.9786° N',
    status: 'Verified',
    questTitle: 'Binary Star Hunt',
  ),
  Observation(
    id: 'obs-6',
    objectName: 'Ring Nebula (M57)',
    dateTime: '28 Aug 2026, 23:10',
    location: 'Chișinău, 28.8638° E',
    status: 'Pending',
    questTitle: 'Deep Sky Wonders of Autumn',
  ),
];
