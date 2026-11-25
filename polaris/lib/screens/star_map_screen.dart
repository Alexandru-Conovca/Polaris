import 'package:flutter/material.dart';

class StarMapScreen extends StatelessWidget {
  const StarMapScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Star map')),
    body: const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Карта не показывает данные, пока не подключён источник координат объектов.',
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}
