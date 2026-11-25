import 'package:go_router/go_router.dart';

import 'data/app_data.dart';
import 'screens/auth_screen.dart';
import 'screens/catalog_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/history_screen.dart';
import 'screens/home_screen.dart';
import 'screens/object_detail_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/quest_screen.dart';
import 'screens/quest_session_screen.dart';

import 'package:provider/provider.dart';

import 'data/file_api.dart';
import 'models/quest_session_model.dart';
import 'screens/star_map_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/telescope_screen.dart';
import 'screens/verification_screen.dart';

import 'widgets/app_shell.dart';

late final GoRouter router;

void initializeRouter() {
  router = createRouter();
}

GoRouter createRouter() => GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) {
        return const AuthScreen();
      },
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) {
                return const HomeScreen();
              },
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/catalog',
              builder: (context, state) {
                return const CatalogScreen();
              },
              routes: [
                GoRoute(
                  path: 'objects/:id',
                  builder: (context, state) {
                    final id = state.pathParameters['id']!;

                    return ObjectDetailScreen(id: id);
                  },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/quests',
              builder: (context, state) {
                return QuestScreen(quest: quests[1]);
              },
              routes: [
                GoRoute(
                  path: 'session/:questId',
                  builder: (context, state) {
                    final questId = state.pathParameters['questId']!;
                    final quest = quests.firstWhere(
                      (item) => item.id == questId,
                      orElse: () => quests.first,
                    );
                    return ChangeNotifierProvider(
                      create: (context) =>
                          QuestSessionModel(context.read<FileApi>(), quest),
                      child: const QuestSessionScreen(),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/star-map',
              builder: (context, state) {
                return const StarMapScreen();
              },
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) {
                return const ProfileScreen();
              },
              routes: [
                GoRoute(
                  path: 'history',
                  builder: (context, state) {
                    return const HistoryScreen();
                  },
                ),
                GoRoute(
                  path: 'favorites',
                  builder: (context, state) {
                    return const FavoritesScreen();
                  },
                ),
                GoRoute(
                  path: 'statistics',
                  builder: (context, state) {
                    return const StatisticsScreen();
                  },
                ),
                GoRoute(
                  path: 'telescope',
                  builder: (context, state) {
                    return const TelescopeScreen();
                  },
                ),
                GoRoute(
                  path: 'verification',
                  builder: (context, state) {
                    return const VerificationScreen();
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
