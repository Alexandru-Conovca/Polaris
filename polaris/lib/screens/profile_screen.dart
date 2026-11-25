import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/auth_api.dart';
import '../data/result.dart';
import '../models/auth_model.dart';
import '../models/theme_model.dart';
import '../widgets/observation_conditions_card.dart';

Future<void> _logout(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogCtx) {
      return AlertDialog(
        title: const Text('Выйти из аккаунта?'),
        content: const Text(
          'Вы действительно хотите завершить текущую сессию?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx, false);
            },
            child: const Text('Нет'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogCtx, true);
            },
            child: const Text('Да, выйти'),
          ),
        ],
      );
    },
  );

  if (ok == true && context.mounted) {
    final auth = context.read<AuthApi>();
    await auth.logout();
    if (!context.mounted) {
      return;
    }
    context.read<AuthModel>().setAuthenticated(false);
    context.go('/');
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = 'Загрузка...';
  String _email = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<AuthModel>().isAuthenticated) {
        _loadUser();
      } else if (mounted) {
        setState(() {
          _name = 'Гость';
        });
      }
    });
  }

  Future<void> _setNightMode(bool enabled) async {
    final result = await context.read<ThemeModel>().setRedNightMode(enabled);
    if (!mounted) {
      return;
    }
    switch (result) {
      case Ok():
        return;
      case Err(msg: final message):
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _loadUser() async {
    final result = await context.read<AuthApi>().fetchMe();
    if (!mounted) {
      return;
    }

    switch (result) {
      case Ok(value: final user):
        setState(() {
          _name = user.name;
          _email = user.email;
        });
      case Err(msg: final message):
        final expired = message == 'Сессия истекла';
        if (expired) {
          context.read<AuthModel>().setAuthenticated(false);
        }
        setState(() {
          _name = expired ? 'Гость' : 'Пользователь';
          _email = '';
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isAuthenticated = context.watch<AuthModel>().isAuthenticated;
    final displayName = isAuthenticated ? _name : 'Гость';
    final initials = displayName.trim().isEmpty
        ? '?'
        : displayName
              .trim()
              .split(RegExp(r'\s+'))
              .take(2)
              .map((part) => part.isEmpty ? '' : part[0].toUpperCase())
              .join();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your profile'),
        actions: [
          IconButton(
            tooltip: isAuthenticated ? 'Выйти из аккаунта' : 'Войти',
            onPressed: isAuthenticated
                ? () => _logout(context)
                : () => context.go('/login'),
            icon: Icon(isAuthenticated ? Icons.logout : Icons.login),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: scheme.primaryContainer,
                foregroundColor: scheme.onPrimaryContainer,
                child: Text(
                  initials,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  if (isAuthenticated && _email.isNotEmpty)
                    Text(
                      _email,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const ObservationConditionsCard(),
          const SizedBox(height: 12),
          Consumer<ThemeModel>(
            builder: (context, theme, child) => Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.nightlight_round),
                    title: const Text('Астрономический ночной режим'),
                    subtitle: Text(
                      theme.isRedNightMode
                          ? 'Тёмно-красная тема включена'
                          : 'Сохраняет адаптацию зрения в темноте',
                    ),
                    value: theme.isRedNightMode,
                    onChanged: _setNightMode,
                  ),
                  if (theme.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Text(
                        theme.errorMessage!,
                        style: TextStyle(color: scheme.error),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (!isAuthenticated) ...[
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.cloud_sync_outlined),
                title: const Text('Синхронизируйте наблюдения'),
                subtitle: const Text(
                  'Войдите, чтобы загружать подтверждения и работать с аккаунтом.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/login'),
              ),
            ),
          ],
          if (isAuthenticated) ...[
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Настройки телескопа'),
                subtitle: const Text(
                  'Аппертурa, фокусное расстояние и монтировка',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/profile/telescope'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
