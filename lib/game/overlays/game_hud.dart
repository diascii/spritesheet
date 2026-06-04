import 'package:flutter/material.dart';

class GameHud extends StatelessWidget {
  final VoidCallback onStop;
  const GameHud({super.key, required this.onStop});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16, right: 16,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.stop),
        label: const Text('Stop'),
        onPressed: onStop,
      ),
    );
  }
}
