import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'data/auth_api.dart';
import 'data/api_config.dart';
import 'data/celestial_object_repository.dart';
import 'data/file_api.dart';
import 'data/http_celestial_object_repository.dart';
import 'data/telescope_repository.dart';
import 'data/http_telescope_repository.dart';
import 'data/token_store.dart';
import 'models/celestial_objects_model.dart';
import 'models/favorites_model.dart';
import 'models/telescope_model.dart';
import 'router.dart' as app_router;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final tokens = TokenStore();
  final loggedIn = await tokens.read() != null;
  final auth = AuthApi(apiBase, tokens);
  app_router.initializeRouter(loggedIn: loggedIn);
  final repository = HttpCelestialObjectRepository(
    apiBase,
    tokens,
    onUnauthorized: () {
      final uri = app_router.router.routeInformationProvider.value.uri;
      if (uri.path != '/login') {
        app_router.router.go('/login');
      }
    },
  );
  final telescopeRepository = HttpTelescopeRepository(
    apiBase,
    tokens,
    onUnauthorized: () {
      final uri = app_router.router.routeInformationProvider.value.uri;
      if (uri.path != '/login') {
        app_router.router.go('/login');
      }
    },
  );
  final fileApi = FileApi(
    apiBase,
    tokens,
    onUnauthorized: () {
      final uri = app_router.router.routeInformationProvider.value.uri;
      if (uri.path != '/login') {
        app_router.router.go('/login');
      }
    },
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<TokenStore>.value(value: tokens),
        Provider<AuthApi>.value(value: auth),
        Provider<FileApi>.value(value: fileApi),
        Provider<CelestialObjectRepository>.value(value: repository),
        Provider<TelescopeRepository>.value(value: telescopeRepository),
        ChangeNotifierProvider(
          create: (_) => CelestialObjectsModel(repository)..load(),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              TelescopeModel(context.read<TelescopeRepository>())..load('sw'),
        ),
        ChangeNotifierProvider(create: (_) => FavoritesModel()),
      ],
      child: Polaris(routerConfig: app_router.router),
    ),
  );
}

class Polaris extends StatelessWidget {
  const Polaris({super.key, required this.routerConfig});

  final GoRouter routerConfig;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Polaris',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      routerConfig: routerConfig,
    );
  }
}
