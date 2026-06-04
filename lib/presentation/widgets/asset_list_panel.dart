import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/sprite_frame.dart';
import '../bloc/sprite_sheet_bloc.dart';
import 'frame_thumbnail.dart';

class AssetListPanel extends StatelessWidget {
  final List<SpriteFrame> frames;
  final bool scrollable;

  const AssetListPanel({super.key, required this.frames, this.scrollable = false});

  @override
  Widget build(BuildContext context) {
    final list = ReorderableListView.builder(
      shrinkWrap: scrollable,
      physics: scrollable ? const NeverScrollableScrollPhysics() : null,
      itemCount: frames.length,
      onReorder: (oldIndex, newIndex) {
        context.read<AssetBloc>().add(
              ReorderFramesEvent(oldIndex: oldIndex, newIndex: newIndex),
            );
      },
      buildDefaultDragHandles: false,
      proxyDecorator: (child, index, animation) => Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(8),
        child: child,
      ),
      itemBuilder: (context, index) {
        final frame = frames[index];
        return _FrameItem(
          key: ValueKey(frame.id),
          frame: frame,
          index: index,
        );
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Text('Frames (${frames.length})',
                  style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => context
                    .read<AssetBloc>()
                    .add(const ImportFramesEvent()),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Import'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  textStyle: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        if (scrollable) list else Expanded(child: list),
      ],
    );
  }
}

class _FrameItem extends StatelessWidget {
  final SpriteFrame frame;
  final int index;

  const _FrameItem({super.key, required this.frame, required this.index});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        dense: true,
        leading: ReorderableDragStartListener(
          index: index,
          child: FrameThumbnail(
            frameId: frame.id,
            rgbaBytes: frame.imageBytes,
            width: frame.width,
            height: frame.height,
            size: 40,
          ),
        ),
        title: Text(
          frame.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13),
        ),
        subtitle: InkWell(
          onTap: () async {
            final ctrl = TextEditingController(text: frame.tag ?? '');
            final result = await showDialog<String>(
              context: context,
              builder: (c) => AlertDialog(
                title: const Text('Set Animation Tag'),
                content: TextField(
                  controller: ctrl,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Idle, Run, Jump',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                  onSubmitted: (v) => Navigator.pop(c, v),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
                  FilledButton(onPressed: () => Navigator.pop(c, ctrl.text), child: const Text('Save')),
                ],
              ),
            );
            if (result != null && context.mounted) {
              context.read<AssetBloc>().add(SetFrameTagEvent(frameId: frame.id, tag: result));
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              frame.tag != null && frame.tag!.isNotEmpty
                  ? '${frame.width}x${frame.height} • ${frame.tag}'
                  : '${frame.width}x${frame.height} • add tag',
              style: TextStyle(
                fontSize: 11,
                color: frame.tag != null && frame.tag!.isNotEmpty
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                fontWeight: frame.tag != null && frame.tag!.isNotEmpty ? FontWeight.bold : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close, size: 18),
          onPressed: () => context
              .read<AssetBloc>()
              .add(RemoveFrameEvent(frameId: frame.id)),
        ),
      ),
    );
  }
}
