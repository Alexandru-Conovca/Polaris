import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/auth_model.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = context.watch<AuthModel>().isAuthenticated;
    return Scaffold(
      appBar: AppBar(title: const Text('Detailed statistics')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: isAuthenticated
              ? const Text(
                  'Статистика появится после подключения реальных записей наблюдений.',
                  textAlign: TextAlign.center,
                )
              : FilledButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Войдите, чтобы открыть статистику'),
                ),
        ),
      ),
    );
  }
}
