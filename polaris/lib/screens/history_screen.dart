import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/auth_model.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = context.watch<AuthModel>().isAuthenticated;
    return Scaffold(
      appBar: AppBar(title: const Text('Observation history')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: isAuthenticated
              ? const Text(
                  'История наблюдений пока не подключена.',
                  textAlign: TextAlign.center,
                )
              : FilledButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Войдите, чтобы открыть историю'),
                ),
        ),
      ),
    );
  }
}
