import 'package:flutter/material.dart';

import '../../domain/entities/hitbox_data.dart';

class HitboxToolbar extends StatelessWidget {
  final HitboxType currentType;
  final ValueChanged<HitboxType> onTypeChanged;
  final VoidCallback? onDeleteHitbox;
  final VoidCallback? onClearAnchor;
  final bool hasSelectedHitbox;

  const HitboxToolbar({
    super.key,
    required this.currentType,
    required this.onTypeChanged,
    this.onDeleteHitbox,
    this.onClearAnchor,
    this.hasSelectedHitbox = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: [
          const Text('Type:', style: TextStyle(fontSize: 11)),
          SegmentedButton<HitboxType>(
            segments: const [
              ButtonSegment(
                value: HitboxType.body,
                label: Text('Body'),
              ),
              ButtonSegment(
                value: HitboxType.attack,
                label: Text('Attack'),
              ),
              ButtonSegment(
                value: HitboxType.hurt,
                label: Text('Hurt'),
              ),
            ],
            selected: {currentType},
            onSelectionChanged: (set) => onTypeChanged(set.first),
            style: SegmentedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              textStyle: const TextStyle(fontSize: 10),
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.delete, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                tooltip: 'Delete hitbox',
                onPressed: hasSelectedHitbox ? onDeleteHitbox : null,
                color: hasSelectedHitbox ? Colors.red : null,
              ),
              IconButton(
                icon: const Icon(Icons.location_off, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                tooltip: 'Clear anchor',
                onPressed: onClearAnchor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

