import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/scene.dart';
import '../../domain/entities/game_map.dart';
import '../bloc/project_cubit.dart';

class SceneListPanel extends StatelessWidget {
  final Scene? currentScene;
  final ValueChanged<Scene> onSceneSelected;

  const SceneListPanel({
    super.key,
    required this.currentScene,
    required this.onSceneSelected,
  });

  @override
  Widget build(BuildContext context) {
    final projectState = context.watch<ProjectCubit>().state;
    final scenes = projectState.scenes;

    return Container(
      width: 150,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Scenes', style: TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _createNewScene(context),
                  tooltip: 'New Scene',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: scenes.length,
              itemBuilder: (context, index) {
                final scene = scenes[index];
                final isSelected = currentScene?.id == scene.id;

                return Dismissible(
                  key: Key(scene.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    context.read<ProjectCubit>().removeScene(scene.id);
                  },
                  child: ListTile(
                    dense: true,
                    selected: isSelected,
                    selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
                    title: Text(scene.name, overflow: TextOverflow.ellipsis),
                    onTap: () => onSceneSelected(scene),
                    onLongPress: () => _renameScene(context, scene),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _createNewScene(BuildContext context) {
    final projectState = context.read<ProjectCubit>().state;
    final count = projectState.scenes.length + 1;
    final newMap = GameMap.create(name: 'Scene $count', width: 20, height: 15, tileSize: 32);
    final newScene = Scene(id: newMap.id, name: newMap.name, map: newMap);
    context.read<ProjectCubit>().addScene(newScene);
  }

  void _renameScene(BuildContext context, Scene scene) {
    final controller = TextEditingController(text: scene.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Scene'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Scene Name'),
          onSubmitted: (val) {
            _submitRename(context, scene, val);
            Navigator.of(ctx).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _submitRename(context, scene, controller.text);
              Navigator.of(ctx).pop();
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _submitRename(BuildContext context, Scene scene, String newName) {
    if (newName.trim().isEmpty) return;
    final updatedScene = scene.copyWith(
      name: newName.trim(),
      map: scene.map.copyWith(name: newName.trim()),
    );
    context.read<ProjectCubit>().updateScene(updatedScene);
  }
}
