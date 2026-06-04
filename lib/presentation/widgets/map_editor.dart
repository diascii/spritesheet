import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flame/game.dart';

import 'frame_thumbnail.dart';
import 'scene_list_panel.dart';
import 'entity_inspector_panel.dart';
import '../../domain/entities/game_map.dart';
import '../../domain/entities/entity_behavior.dart';
import '../../domain/entities/scene.dart';
import '../../domain/entities/sprite_frame.dart';
import '../../domain/entities/game_template.dart';
import '../bloc/sprite_sheet_bloc.dart';
import '../bloc/project_cubit.dart';
import '../../game/pixel_game.dart';
import '../../game/fps/fps_game_controller.dart';
import '../../game/overlays/game_hud.dart';
import '../../data/services/image_registry.dart';

class MapEditor extends StatefulWidget {
  const MapEditor({super.key});

  @override
  State<MapEditor> createState() => _MapEditorState();
}

enum MapToolMode { pan, select, paint, fill, solid, transition }

class _MapEditorState extends State<MapEditor> {
  GameMap? _currentMap;
  String? _selectedFrameId;
  final TransformationController _transformController = TransformationController();
  MapToolMode _currentTool = MapToolMode.pan;
  bool _isEntityLayer = false;
  Offset? _transitionStart;
  Offset? _transitionCurrent;
  MapEntity? _selectedEntity;

  @override
  void initState() {
    super.initState();
    _ensureMapExists();
  }

  void _ensureMapExists() {
    final projectState = context.read<ProjectCubit>().state;
    final scenes = projectState.scenes;

    if (scenes.isEmpty) {
      final newMap = GameMap.create(name: 'Map 1', width: 20, height: 15, tileSize: 32);
      final newScene = Scene(id: newMap.id, name: newMap.name, map: newMap);
      context.read<ProjectCubit>().addScene(newScene);
      setState(() {
        _currentMap = newMap;
      });
    } else {
      setState(() {
        _currentMap = scenes.first.map;
      });
    }
  }

  void _paintTile(Offset localPosition, List<SpriteFrame> frames) {
    if (_currentMap == null || _selectedFrameId == null) return;
    
    final Offset mapOffset = localPosition;

    final int col = (mapOffset.dx / _currentMap!.tileSize).floor();
    final int row = (mapOffset.dy / _currentMap!.tileSize).floor();

    if (col < 0 || col >= _currentMap!.width || row < 0 || row >= _currentMap!.height) return;

    if (_currentTool == MapToolMode.solid) {
      final int index = row * _currentMap!.width + col;
      final newSolids = List<bool>.from(_currentMap!.layers[0].solids);
      newSolids[index] = !newSolids[index]; // Toggle
      final newLayer = _currentMap!.layers[0].copyWith(solids: newSolids);
      final newLayers = List<MapLayer>.from(_currentMap!.layers);
      newLayers[0] = newLayer;
      final updatedMap = _currentMap!.copyWith(layers: newLayers);
      setState(() => _currentMap = updatedMap);
      final scene = context.read<ProjectCubit>().state.scenes.firstWhere((s) => s.map.id == updatedMap.id);
      context.read<ProjectCubit>().updateScene(scene.copyWith(map: updatedMap));
      return;
    }

    if (_isEntityLayer) {
      // Place Entity
      final existingIndex = _currentMap!.entities.indexWhere((e) =>
          e.x.floor() == col * _currentMap!.tileSize &&
          e.y.floor() == row * _currentMap!.tileSize);

      List<MapEntity> newEntities = List.from(_currentMap!.entities);
      if (existingIndex >= 0) {
        if (newEntities[existingIndex].frameId == _selectedFrameId) return; // Same
        final frame = frames.firstWhere((f) => f.id == _selectedFrameId);
        final newEntity = MapEntity(
          id: newEntities[existingIndex].id,
          frameId: frame.id,
          type: 'default',
          x: (col * _currentMap!.tileSize).toDouble(),
          y: (row * _currentMap!.tileSize).toDouble(),
        );
        newEntities[existingIndex] = newEntity;
      } else {
        final frame = frames.firstWhere((f) => f.id == _selectedFrameId);
        final newEntity = MapEntity(
          id: UniqueKey().toString(),
          frameId: frame.id,
          type: 'default',
          x: (col * _currentMap!.tileSize).toDouble(),
          y: (row * _currentMap!.tileSize).toDouble(),
        );
        newEntities.add(newEntity);
      }
      
      final updatedMap = _currentMap!.copyWith(entities: newEntities);
      setState(() {
        _currentMap = updatedMap;
      });
      final scene = context.read<ProjectCubit>().state.scenes.firstWhere((s) => s.map.id == updatedMap.id);
      context.read<ProjectCubit>().updateScene(scene.copyWith(map: updatedMap));
    } else {
      // Paint or Fill Tile
      final int index = row * _currentMap!.width + col;

      if (_currentTool == MapToolMode.fill) {
        final newTiles = List<String?>.from(_currentMap!.layers[0].tiles);
        final targetId = newTiles[index];
        if (targetId == _selectedFrameId) return;

        final queue = <int>[index];
        final visited = <int>{};
        
        while (queue.isNotEmpty) {
          final curr = queue.removeAt(0);
          if (visited.contains(curr)) continue;
          visited.add(curr);

          if (newTiles[curr] == targetId) {
            newTiles[curr] = _selectedFrameId;

            final r = curr ~/ _currentMap!.width;
            final c = curr % _currentMap!.width;

            if (r > 0) queue.add(curr - _currentMap!.width);
            if (r < _currentMap!.height - 1) queue.add(curr + _currentMap!.width);
            if (c > 0) queue.add(curr - 1);
            if (c < _currentMap!.width - 1) queue.add(curr + 1);
          }
        }

        final newLayer = _currentMap!.layers[0].copyWith(tiles: newTiles);
        final newLayers = List<MapLayer>.from(_currentMap!.layers);
        newLayers[0] = newLayer;

        final updatedMap = _currentMap!.copyWith(layers: newLayers);
        
        setState(() {
          _currentMap = updatedMap;
        });
        final scene = context.read<ProjectCubit>().state.scenes.firstWhere((s) => s.map.id == updatedMap.id);
        context.read<ProjectCubit>().updateScene(scene.copyWith(map: updatedMap));
      } else {
        if (_currentMap!.layers[0].tiles[index] != _selectedFrameId) {
          final newTiles = List<String?>.from(_currentMap!.layers[0].tiles);
          newTiles[index] = _selectedFrameId;

          final newLayer = _currentMap!.layers[0].copyWith(tiles: newTiles);
          final newLayers = List<MapLayer>.from(_currentMap!.layers);
          newLayers[0] = newLayer;

          final updatedMap = _currentMap!.copyWith(layers: newLayers);
          
          setState(() {
            _currentMap = updatedMap;
          });
          final scene = context.read<ProjectCubit>().state.scenes.firstWhere((s) => s.map.id == updatedMap.id);
          context.read<ProjectCubit>().updateScene(scene.copyWith(map: updatedMap));
        }
      }
    }
  }

  void _promptForTransitionTarget(BuildContext context, Rect rect) async {
    final projectState = context.read<ProjectCubit>().state;
    final scenes = projectState.scenes.where((s) => s.id != _currentMap!.id).toList();

    if (scenes.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create another scene first to link to it.')),
      );
      return;
    }

    String? selectedSceneId = scenes.first.id;
    double spawnX = 0;
    double spawnY = 0;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Create Transition'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    value: selectedSceneId,
                    isExpanded: true,
                    items: scenes.map((s) {
                      return DropdownMenuItem(
                        value: s.id,
                        child: Text(s.name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setStateDialog(() => selectedSceneId = val);
                    },
                  ),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Spawn X'),
                    keyboardType: TextInputType.number,
                    onChanged: (val) => spawnX = double.tryParse(val) ?? 0,
                  ),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Spawn Y'),
                    keyboardType: TextInputType.number,
                    onChanged: (val) => spawnY = double.tryParse(val) ?? 0,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Create'),
                ),
              ],
            );
          }
        );
      },
    );

    if (result == true && selectedSceneId != null) {
      final transition = SceneTransition(
        id: UniqueKey().toString(),
        targetSceneId: selectedSceneId!,
        triggerX: rect.left,
        triggerY: rect.top,
        triggerW: rect.width,
        triggerH: rect.height,
        spawnX: spawnX,
        spawnY: spawnY,
      );

      final currentScene = projectState.scenes.firstWhere((s) => s.id == _currentMap!.id);
      final newTransitions = List<SceneTransition>.from(currentScene.transitions)..add(transition);
      if (!context.mounted) return;
      context.read<ProjectCubit>().updateScene(currentScene.copyWith(transitions: newTransitions));
    }
  }



  @override
  Widget build(BuildContext context) {
    final projectState = context.watch<ProjectCubit>().state;
    final scenes = projectState.scenes;
    final maps = scenes.map((s) => s.map).toList();

    return BlocBuilder<AssetBloc, SpriteSheetState>(
      builder: (context, state) {
        List<SpriteFrame> frames = [];
        if (state is FramesImported) {
          frames = state.frames;
        } else if (state is PackComplete) {
          frames = state.frames;
        }

        if (_currentMap == null && maps.isNotEmpty) {
          _currentMap = maps.first;
        } else if (_currentMap != null && maps.any((m) => m.id == _currentMap!.id)) {
          _currentMap = maps.firstWhere((m) => m.id == _currentMap!.id);
        }

        if (_currentMap == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return Row(
          children: [
            // Left Scenes Panel
            SceneListPanel(
              currentScene: scenes.firstWhere((s) => s.map.id == _currentMap!.id, orElse: () => scenes.first),
              onSceneSelected: (scene) {
                setState(() {
                  _currentMap = scene.map;
                });
              },
            ),
            const VerticalDivider(width: 1),
            // Left Palette & Tools
            Container(
              width: 120,
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Layer', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  ToggleButtons(
                    direction: Axis.vertical,
                    isSelected: [!_isEntityLayer, _isEntityLayer],
                    onPressed: (index) {
                      setState(() {
                        _isEntityLayer = index == 1;
                      });
                    },
                    children: const [
                      Padding(padding: EdgeInsets.all(8.0), child: Text('Tiles')),
                      Padding(padding: EdgeInsets.all(8.0), child: Text('Entities')),
                    ],
                  ),
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Assets', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: frames.length,
                      itemBuilder: (context, index) {
                        final frame = frames[index];
                        final isSelected = _selectedFrameId == frame.id;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedFrameId = frame.id;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: FrameThumbnail(
                              frameId: frame.id,
                              rgbaBytes: frame.imageBytes,
                              width: frame.width,
                              height: frame.height,
                              size: 64,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Map Canvas
            Expanded(
              child: Stack(
                children: [
                  InteractiveViewer(
                    transformationController: _transformController,
                    panEnabled: _currentTool == MapToolMode.pan,
                    scaleEnabled: _currentTool == MapToolMode.pan,
                    minScale: 0.1,
                    maxScale: 10.0,
                    boundaryMargin: const EdgeInsets.all(1000),
                    child: Center(
                      child: GestureDetector(
                        onPanStart: (_currentTool == MapToolMode.pan || _currentTool == MapToolMode.select) ? null : (details) {
                          if (_currentTool == MapToolMode.transition) {
                            setState(() {
                              _transitionStart = details.localPosition;
                              _transitionCurrent = details.localPosition;
                            });
                          } else {
                            _paintTile(details.localPosition, frames);
                          }
                        },
                        onPanUpdate: (_currentTool == MapToolMode.pan || _currentTool == MapToolMode.select) ? null : (details) {
                          if (_currentTool == MapToolMode.transition) {
                            setState(() {
                              _transitionCurrent = details.localPosition;
                            });
                          } else {
                            _paintTile(details.localPosition, frames);
                          }
                        },
                        onPanEnd: (_currentTool == MapToolMode.pan || _currentTool == MapToolMode.select) ? null : (details) {
                          if (_currentTool == MapToolMode.transition && _transitionStart != null && _transitionCurrent != null) {
                            final rect = Rect.fromPoints(_transitionStart!, _transitionCurrent!);
                            setState(() {
                              _transitionStart = null;
                              _transitionCurrent = null;
                            });
                            if (rect.width > 10 && rect.height > 10) {
                              _promptForTransitionTarget(context, rect);
                            }
                          }
                        },
                        onTapDown: _currentTool == MapToolMode.pan ? null : (details) {
                          if (_currentTool == MapToolMode.select) {
                            // Find entity under cursor
                            final localPos = details.localPosition;
                            final map = _currentMap!;
                            final ts = map.tileSize.toDouble();
                            final tx = localPos.dx;
                            final ty = localPos.dy;
                            
                            MapEntity? hitEntity;
                            for (final e in map.entities) {
                              final rect = Rect.fromLTWH(e.x, e.y, ts, ts); // Assume visual size is tileSize for selection
                              if (rect.contains(Offset(tx, ty))) {
                                hitEntity = e;
                                break;
                              }
                            }
                            setState(() {
                              _selectedEntity = hitEntity;
                            });
                          } else if (_currentTool != MapToolMode.transition) {
                            _paintTile(details.localPosition, frames);
                          }
                        },
                        child: Stack(
                          children: [
                            CustomPaint(
                              size: Size(
                                _currentMap!.width * _currentMap!.tileSize.toDouble(),
                                _currentMap!.height * _currentMap!.tileSize.toDouble(),
                              ),
                              painter: MapPainter(
                                map: _currentMap!,
                                scene: projectState.scenes.firstWhere((s) => s.map.id == _currentMap!.id, orElse: () => projectState.scenes.first),
                                transitionRect: _transitionStart != null && _transitionCurrent != null
                                    ? Rect.fromPoints(_transitionStart!, _transitionCurrent!)
                                    : null,
                              ),
                            ),
                            // Draw the actual tiles using Positioned widgets
                            ..._buildTiles(frames, _currentMap!),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Card(
                      elevation: 4,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.pan_tool),
                            color: _currentTool == MapToolMode.pan ? Theme.of(context).colorScheme.primary : null,
                            tooltip: 'Pan (Space)',
                            onPressed: () => setState(() => _currentTool = MapToolMode.pan),
                          ),
                          IconButton(
                            icon: const Icon(Icons.ads_click),
                            color: _currentTool == MapToolMode.select ? Theme.of(context).colorScheme.primary : null,
                            tooltip: 'Select Entity',
                            onPressed: () => setState(() => _currentTool = MapToolMode.select),
                          ),
                          IconButton(
                            icon: const Icon(Icons.brush),
                            color: _currentTool == MapToolMode.paint ? Theme.of(context).colorScheme.primary : null,
                            tooltip: 'Draw Tiles',
                            onPressed: () => setState(() => _currentTool = MapToolMode.paint),
                          ),
                          IconButton(
                            icon: const Icon(Icons.format_color_fill),
                            color: _currentTool == MapToolMode.fill ? Theme.of(context).colorScheme.primary : null,
                            tooltip: 'Fill',
                            onPressed: () => setState(() => _currentTool = MapToolMode.fill),
                          ),
                          IconButton(
                            icon: const Icon(Icons.block),
                            color: _currentTool == MapToolMode.solid ? Theme.of(context).colorScheme.primary : null,
                            tooltip: 'Mark Solid',
                            onPressed: () => setState(() => _currentTool = MapToolMode.solid),
                          ),
                          IconButton(
                            icon: const Icon(Icons.exit_to_app),
                            color: _currentTool == MapToolMode.transition ? Theme.of(context).colorScheme.primary : null,
                            tooltip: 'Add Transition',
                            onPressed: () => setState(() => _currentTool = MapToolMode.transition),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Play'),
                            onPressed: () {
                              final currentScene = projectState.scenes.firstWhere((s) => s.map.id == _currentMap!.id, orElse: () => projectState.scenes.first);
                              _playGame(frames, currentScene);
                            },
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Right Inspector Panel
            if (_selectedEntity != null) ...[
              const VerticalDivider(width: 1),
              EntityInspectorPanel(
                entity: _selectedEntity!,
                onEntityUpdated: (updatedEntity) {
                  final newEntities = _currentMap!.entities.map((e) => e.id == updatedEntity.id ? updatedEntity : e).toList();
                  final newMap = _currentMap!.copyWith(entities: newEntities);
                  final scene = projectState.scenes.firstWhere((s) => s.map.id == newMap.id);
                  context.read<ProjectCubit>().updateScene(scene.copyWith(map: newMap));
                  setState(() {
                    _currentMap = newMap;
                    _selectedEntity = updatedEntity;
                  });
                },
              ),
            ],
          ],
        );
      },
    );
  }

  List<Widget> _buildTiles(List<SpriteFrame> frames, GameMap map) {
    List<Widget> widgets = [];
    final double tileSize = map.tileSize.toDouble();
    // Add Tile Layer widgets
    if (map.layers.isNotEmpty) {
      final layer = map.layers[0];
      for (int row = 0; row < map.height; row++) {
        for (int col = 0; col < map.width; col++) {
          final index = row * map.width + col;
          final frameId = layer.tiles[index];
          if (frameId != null) {
            final frame = frames.cast<SpriteFrame?>().firstWhere((f) => f?.id == frameId, orElse: () => null);
            final isSolid = layer.solids.length > index ? layer.solids[index] : false;
            if (frame != null) {
              widgets.add(
                Positioned(
                  left: col * tileSize,
                  top: row * tileSize,
                  width: tileSize,
                  height: tileSize,
                  child: Stack(
                    children: [
                      Opacity(
                        opacity: _isEntityLayer ? 0.5 : 1.0,
                        child: FrameThumbnail(
                          frameId: frame.id,
                          rgbaBytes: frame.imageBytes,
                          width: frame.width,
                          height: frame.height,
                          size: tileSize,
                        ),
                      ),
                      if (isSolid)
                        Container(
                          color: Colors.red.withValues(alpha: 0.4),
                        ),
                    ],
                  ),
                ),
              );
            }
          }
        }
      }
    }

    // Add Entity Layer widgets
    for (final entity in map.entities) {
      final frame = frames.cast<SpriteFrame?>().firstWhere((f) => f?.id == entity.frameId, orElse: () => null);
      if (frame != null) {
        widgets.add(
          Positioned(
            left: entity.x,
            top: entity.y,
            width: tileSize,
            height: tileSize,
            child: Opacity(
              opacity: !_isEntityLayer ? 0.5 : 1.0,
              child: Container(
                decoration: _isEntityLayer ? BoxDecoration(
                  border: Border.all(color: Colors.redAccent, width: 2),
                ) : null,
                child: FrameThumbnail(
                  frameId: frame.id,
                  rgbaBytes: frame.imageBytes,
                  width: frame.width,
                  height: frame.height,
                  size: tileSize,
                ),
              ),
            ),
          ),
        );
      }
    }
    return widgets;
  }

  void _playGame(List<SpriteFrame> frames, Scene currentScene) {
    final projectState = context.read<ProjectCubit>().state;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _PlayScreen(
          scenes: projectState.scenes,
          initialSceneId: currentScene.id,
          frames: frames,
          template: projectState.template,
        ),
      ),
    );
  }
}

class _PlayScreen extends StatefulWidget {
  final List<Scene> scenes;
  final String initialSceneId;
  final List<SpriteFrame> frames;
  final GameTemplate template;

  const _PlayScreen({
    required this.scenes, 
    required this.initialSceneId, 
    required this.frames,
    required this.template,
  });

  @override
  State<_PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<_PlayScreen> {
  late PixelGame _pixelGame;
  late String _currentSceneId;

  @override
  void initState() {
    super.initState();
    _currentSceneId = widget.initialSceneId;
    _initGame();
  }

  void _initGame() {
    final scene = widget.scenes.firstWhere((s) => s.id == _currentSceneId);
    _pixelGame = PixelGame(
      scene: scene,
      frames: widget.frames,
      imageRegistry: ImageRegistry.instance,
      onTransition: _handleTransition,
      onInteraction: _handleInteraction,
    );
  }

  void _handleTransition(SceneTransition transition) {
    setState(() {
      _currentSceneId = transition.targetSceneId;
      _initGame();
    });
  }

  void _handleInteraction(InteractableBehavior behavior) {
    if (!mounted) return;
    if (behavior.triggerAction == 'dialog') {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Interaction'),
          content: Text('Triggered dialog target: ${behavior.targetId}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else if (behavior.triggerAction == 'battle') {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Battle!'),
          content: Text('Encounter with ${behavior.targetId}!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Flee'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.template == GameTemplate.fps) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            FPSGameController(
              scene: widget.scenes.firstWhere((s) => s.id == _currentSceneId),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GameWidget(
        game: _pixelGame,
        overlayBuilderMap: {
          'hud': (context, game) => GameHud(
            onStop: () => Navigator.pop(context),
          ),
        },
        initialActiveOverlays: const ['hud'],
      ),
    );
  }
}

class MapPainter extends CustomPainter {
  final GameMap map;
  final Scene scene;
  final Rect? transitionRect;

  MapPainter({required this.map, required this.scene, this.transitionRect});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw Grid Background
    final bgPaint = Paint()..color = Colors.grey[800]!;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Draw Grid Lines
    final gridPaint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 0; i <= map.width; i++) {
      canvas.drawLine(
        Offset(i * map.tileSize.toDouble(), 0),
        Offset(i * map.tileSize.toDouble(), size.height),
        gridPaint,
      );
    }
    for (int i = 0; i <= map.height; i++) {
      canvas.drawLine(
        Offset(0, i * map.tileSize.toDouble()),
        Offset(size.width, i * map.tileSize.toDouble()),
        gridPaint,
      );
    }

    // Draw existing transitions
    final transPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    final transBorderPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (final t in scene.transitions) {
      final rect = Rect.fromLTWH(t.triggerX, t.triggerY, t.triggerW, t.triggerH);
      canvas.drawRect(rect, transPaint);
      canvas.drawRect(rect, transBorderPaint);
    }

    // Draw current dragging transition
    if (transitionRect != null) {
      canvas.drawRect(transitionRect!, transPaint);
      canvas.drawRect(transitionRect!, transBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant MapPainter oldDelegate) {
    return oldDelegate.map != map || oldDelegate.scene != scene || oldDelegate.transitionRect != transitionRect;
  }
}
