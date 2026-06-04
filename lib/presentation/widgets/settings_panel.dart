import 'package:flutter/material.dart';

class SettingsPanel extends StatelessWidget {
  final TextEditingController nameController;
  final int maxTextureSize;
  final int framePadding;
  final ValueChanged<int> onMaxTextureSizeChanged;
  final ValueChanged<int> onFramePaddingChanged;

  const SettingsPanel({
    super.key,
    required this.nameController,
    required this.maxTextureSize,
    required this.framePadding,
    required this.onMaxTextureSizeChanged,
    required this.onFramePaddingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Settings', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Sheet name',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: maxTextureSize,
              decoration: const InputDecoration(
                labelText: 'Max texture size',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: 2048, child: Text('2048\u00d72048')),
                DropdownMenuItem(value: 4096, child: Text('4096\u00d74096')),
              ],
              onChanged: (v) {
                if (v != null) onMaxTextureSizeChanged(v);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: framePadding,
              decoration: const InputDecoration(
                labelText: 'Frame padding',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: List.generate(9, (i) => DropdownMenuItem(
                value: i,
                child: Text('$i px'),
              )),
              onChanged: (v) {
                if (v != null) onFramePaddingChanged(v);
              },
            ),
          ],
        ),
      ),
    );
  }
}
