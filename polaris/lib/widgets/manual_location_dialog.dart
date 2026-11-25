import 'package:flutter/material.dart';

import '../models/observation_location.dart';

Future<ObservationLocation?> showManualLocationDialog(BuildContext context) =>
    showDialog<ObservationLocation>(
      context: context,
      builder: (context) => const _ManualLocationDialog(),
    );

class _ManualLocationDialog extends StatefulWidget {
  const _ManualLocationDialog();

  @override
  State<_ManualLocationDialog> createState() => _ManualLocationDialogState();
}

class _ManualLocationDialogState extends State<_ManualLocationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _altitudeController = TextEditingController();

  @override
  void dispose() {
    _latitudeController.dispose();
    _longitudeController.dispose();
    _altitudeController.dispose();
    super.dispose();
  }

  String? _validateCoordinate(
    String? value, {
    required double minimum,
    required double maximum,
  }) {
    final number = double.tryParse((value ?? '').trim().replaceAll(',', '.'));
    if (number == null || !number.isFinite) {
      return 'Введите корректное число';
    }
    if (number < minimum || number > maximum) {
      return 'Значение должно быть от $minimum до $maximum';
    }
    return null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    double read(TextEditingController controller) =>
        double.parse(controller.text.trim().replaceAll(',', '.'));

    final altitudeText = _altitudeController.text.trim();
    Navigator.pop(
      context,
      ObservationLocation.manual(
        latitude: read(_latitudeController),
        longitude: read(_longitudeController),
        altitude: altitudeText.isEmpty
            ? null
            : double.parse(altitudeText.replaceAll(',', '.')),
        timestamp: DateTime.now().toUtc(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Точка наблюдения'),
    content: Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _latitudeController,
              decoration: const InputDecoration(labelText: 'Широта'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              validator: (value) =>
                  _validateCoordinate(value, minimum: -90, maximum: 90),
            ),
            TextFormField(
              controller: _longitudeController,
              decoration: const InputDecoration(labelText: 'Долгота'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              validator: (value) =>
                  _validateCoordinate(value, minimum: -180, maximum: 180),
            ),
            TextFormField(
              controller: _altitudeController,
              decoration: const InputDecoration(
                labelText: 'Высота над уровнем моря, м (необязательно)',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return null;
                }
                final altitude = double.tryParse(
                  value!.trim().replaceAll(',', '.'),
                );
                return altitude == null || !altitude.isFinite
                    ? 'Введите корректное число'
                    : null;
              },
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Отмена'),
      ),
      FilledButton(onPressed: _save, child: const Text('Сохранить')),
    ],
  );
}
