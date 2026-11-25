import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/telescope_model.dart';
import '../models/auth_model.dart';

class TelescopeScreen extends StatefulWidget {
  const TelescopeScreen({super.key});

  @override
  State<TelescopeScreen> createState() => _TelescopeScreenState();
}

class _TelescopeScreenState extends State<TelescopeScreen> {
  final _formKey = GlobalKey<FormState>();

  final _apertureController = TextEditingController();
  final _focalLengthController = TextEditingController();
  final _mountController = TextEditingController();

  @override
  void dispose() {
    _apertureController.dispose();
    _focalLengthController.dispose();
    _mountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final telescope = context.read<TelescopeModel>().telescope;
    if (telescope == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось загрузить телескоп')),
      );
      return;
    }

    final error = await context.read<TelescopeModel>().update(
      telescope.copyWith(
        aperture: int.parse(_apertureController.text.trim()),
        focalLength: int.parse(_focalLengthController.text.trim()),
        mountType: _mountController.text.trim(),
      ),
    );
    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (!context.watch<AuthModel>().isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Telescope setup')),
        body: Center(
          child: FilledButton(
            onPressed: () => context.go('/login'),
            child: const Text('Войдите, чтобы открыть настройки'),
          ),
        ),
      );
    }

    final telescope = context.watch<TelescopeModel>().telescope;
    if (telescope == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final ratio = telescope.focalLength / telescope.aperture;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Telescope setup')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      telescope.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Aperture\n${telescope.aperture} mm'),
                        Text('Focal length\n${telescope.focalLength} mm'),
                        Text('Focal ratio\nf/${ratio.toStringAsFixed(1)}'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Equipment profile',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _apertureController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Aperture (mm)',
                prefixIcon: Icon(Icons.circle_outlined),
              ),
              validator: (value) {
                final aperture = int.tryParse(value ?? '');

                if (aperture == null) {
                  return 'Введите диаметр апертуры';
                }

                if (aperture <= 0) {
                  return 'Значение должно быть положительным';
                }

                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _focalLengthController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Focal length (mm)',
                prefixIcon: Icon(Icons.straighten),
              ),
              validator: (value) {
                final focalLength = int.tryParse(value ?? '');

                if (focalLength == null) {
                  return 'Введите фокусное расстояние';
                }

                if (focalLength <= 0) {
                  return 'Значение должно быть положительным';
                }

                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _mountController,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Mount type',
                prefixIcon: Icon(Icons.alt_route),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Введите тип монтировки';
                }

                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Сохранить'),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              color: scheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: scheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Recommended eyepiece for deep sky: 25 mm\n'
                        'Start with a wide field, then increase magnification '
                        'as the object settles.',
                        style: TextStyle(color: scheme.onSecondaryContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
