import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/auth_model.dart';

class VerificationScreen extends StatelessWidget {
  const VerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = context.watch<AuthModel>().isAuthenticated;
    return Scaffold(
      appBar: AppBar(title: const Text('Verify observation')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: isAuthenticated
              ? const Text(
                  'Проверка станет доступна после сохранения реальной записи наблюдения.',
                  textAlign: TextAlign.center,
                )
              : FilledButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Войдите, чтобы продолжить'),
                ),
        ),
      ),
    );
  }
}
