import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../domain/entities/pack_result.dart';

class PackedPreview extends StatelessWidget {
  final Uint8List pngBytes;
  final PackResult packResult;

  const PackedPreview({
    super.key,
    required this.pngBytes,
    required this.packResult,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Packed Sheet', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Expanded(
          child: InteractiveViewer(
              minScale: 0.25,
              maxScale: 4,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: ClipRect(
                        child: Image.memory(
                          pngBytes,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${packResult.canvasWidth}\u00d7${packResult.canvasHeight}  |  '
                      '${packResult.placements.length} frames  |  '
                      '${(packResult.efficiency * 100).toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (packResult.hasOverflow)
                      Text(
                        '${packResult.overflowFrameIds.length} overflowed',
                        style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                      ),
                  ],
                ),
            ),
          ),
        ),
      ],
    );
  }
}
