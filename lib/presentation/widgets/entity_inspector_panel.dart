import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/game_map.dart';
import '../../domain/entities/entity_behavior.dart';
import '../bloc/project_cubit.dart';

class EntityInspectorPanel extends StatelessWidget {
  final MapEntity entity;
  final ValueChanged<MapEntity> onEntityUpdated;

  const EntityInspectorPanel({
    super.key,
    required this.entity,
    required this.onEntityUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Entity Inspector', style: TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _addBehaviorDialog(context),
                  tooltip: 'Add Behavior',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: entity.behaviors.length,
              itemBuilder: (context, index) {
                final behavior = entity.behaviors[index];
                return _buildBehaviorCard(context, behavior, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBehaviorCard(BuildContext context, EntityBehavior behavior, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ExpansionTile(
        title: Text(_getBehaviorName(behavior)),
        trailing: IconButton(
          icon: const Icon(Icons.delete, size: 18),
          onPressed: () {
            final newBehaviors = List<EntityBehavior>.from(entity.behaviors)..removeAt(index);
            onEntityUpdated(entity.copyWith(behaviors: newBehaviors));
          },
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildBehaviorEditor(context, behavior, index),
          )
        ],
      ),
    );
  }

  String _getBehaviorName(EntityBehavior behavior) {
    if (behavior is PlayerControlBehavior) return 'Player Control';
    if (behavior is PatrolBehavior) return 'Patrol';
    if (behavior is ChaseBehavior) return 'Chase';
    if (behavior is DialogBehavior) return 'Dialog';
    if (behavior is StaticBehavior) return 'Static';
    if (behavior is ProjectileBehavior) return 'Projectile';
    if (behavior is GridMovementBehavior) return 'Grid Movement';
    if (behavior is InteractableBehavior) return 'Interactable';
    return 'Unknown';
  }

  Widget _buildBehaviorEditor(BuildContext context, EntityBehavior behavior, int index) {
    if (behavior is PlayerControlBehavior) {
      return TextFormField(
        initialValue: behavior.speed.toString(),
        decoration: const InputDecoration(labelText: 'Speed', isDense: true),
        keyboardType: TextInputType.number,
        onChanged: (val) {
          final s = double.tryParse(val) ?? 100.0;
          _updateBehavior(index, PlayerControlBehavior(speed: s, idleTag: behavior.idleTag, walkTag: behavior.walkTag));
        },
      );
    }
    // TODO: Add editors for other behaviors
    return const Text('Properties editing coming soon');
  }

  void _updateBehavior(int index, EntityBehavior newBehavior) {
    final newBehaviors = List<EntityBehavior>.from(entity.behaviors)..[index] = newBehavior;
    onEntityUpdated(entity.copyWith(behaviors: newBehaviors));
  }

  void _addBehaviorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Behavior'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: const Text('Player Control'), onTap: () => _add(ctx, const PlayerControlBehavior())),
            ListTile(title: const Text('Patrol'), onTap: () => _add(ctx, const PatrolBehavior())),
            ListTile(title: const Text('Chase'), onTap: () => _add(ctx, const ChaseBehavior())),
            ListTile(title: const Text('Dialog'), onTap: () => _add(ctx, const DialogBehavior())),
            ListTile(title: const Text('Grid Movement'), onTap: () => _add(ctx, const GridMovementBehavior())),
            ListTile(title: const Text('Interactable'), onTap: () => _add(ctx, const InteractableBehavior(triggerAction: 'dialog'))),
          ],
        ),
      ),
    );
  }

  void _add(BuildContext ctx, EntityBehavior behavior) {
    Navigator.of(ctx).pop();
    final newBehaviors = List<EntityBehavior>.from(entity.behaviors)..add(behavior);
    onEntityUpdated(entity.copyWith(behaviors: newBehaviors));
  }
}
