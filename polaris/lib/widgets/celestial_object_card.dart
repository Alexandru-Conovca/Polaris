import 'package:flutter/material.dart';

import '../data/astronomy_service.dart';
import '../data/celestial_object.dart';
import '../models/domain_models.dart';
import 'stat_badge.dart';

class CelestialObjectCard extends StatelessWidget {
  const CelestialObjectCard({
    super.key,
    required this.object,
    this.onTap,
    this.position,
    this.hasLocation = false,
  });

  final CelestialObject object;
  final VoidCallback? onTap;
  final HorizontalPosition? position;
  final bool hasLocation;

  IconData get _icon => switch (object.type) {
    CelestialType.planet => Icons.public,
    CelestialType.galaxy => Icons.blur_on,
    CelestialType.nebula => Icons.cloud,
    CelestialType.star => Icons.star,
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
          child: Icon(_icon),
        ),
        title: Text(object.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          [
            '${object.constellation}  •  Mag ${object.magnitude.toStringAsFixed(1)}',
            if (!hasLocation)
              'Точка наблюдения не задана'
            else if (position == null)
              'Координаты RA/Dec недоступны'
            else
              '${position!.statusLabel} · '
                  'Alt ${position!.altitudeDegrees.toStringAsFixed(1)}° · '
                  'Az ${position!.azimuthDegrees.toStringAsFixed(1)}°',
          ].join('\n'),
        ),
        trailing: StatBadge(
          label: position == null
              ? '—'
              : '${position!.altitudeDegrees.toStringAsFixed(0)}°',
          color: position?.isVisibleNow == true
              ? scheme.tertiary
              : scheme.outline,
        ),
      ),
    );
  }
}
