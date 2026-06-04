import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/scene.dart';
import 'fps_game_state.dart';
import 'raycast_renderer.dart';

class FPSGameController extends StatefulWidget {
  final Scene scene;

  const FPSGameController({super.key, required this.scene});

  @override
  State<FPSGameController> createState() => _FPSGameControllerState();
}

class _FPSGameControllerState extends State<FPSGameController> with SingleTickerProviderStateMixin {
  late FPSGameState _state;
  late Ticker _ticker;
  
  final Set<LogicalKeyboardKey> _keysPressed = {};
  Duration _lastElapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _state = FPSGameState.fromScene(widget.scene);
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (_lastElapsed == Duration.zero) {
      _lastElapsed = elapsed;
      return;
    }
    
    final dt = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;

    _processInput(dt);
    
    setState(() {});
  }

  void _processInput(double dt) {
    final moveSpeed = 3.0 * dt;
    final rotSpeed = 2.0 * dt;

    if (_keysPressed.contains(LogicalKeyboardKey.arrowUp) || _keysPressed.contains(LogicalKeyboardKey.keyW)) {
      final newX = _state.playerX + cos(_state.playerAngle) * moveSpeed;
      final newY = _state.playerY + sin(_state.playerAngle) * moveSpeed;
      if (!_isSolid(newX, _state.playerY)) _state.playerX = newX;
      if (!_isSolid(_state.playerX, newY)) _state.playerY = newY;
    }
    if (_keysPressed.contains(LogicalKeyboardKey.arrowDown) || _keysPressed.contains(LogicalKeyboardKey.keyS)) {
      final newX = _state.playerX - cos(_state.playerAngle) * moveSpeed;
      final newY = _state.playerY - sin(_state.playerAngle) * moveSpeed;
      if (!_isSolid(newX, _state.playerY)) _state.playerX = newX;
      if (!_isSolid(_state.playerX, newY)) _state.playerY = newY;
    }
    
    // Strafe
    if (_keysPressed.contains(LogicalKeyboardKey.keyA)) {
      final newX = _state.playerX - cos(_state.playerAngle + pi / 2) * moveSpeed;
      final newY = _state.playerY - sin(_state.playerAngle + pi / 2) * moveSpeed;
      if (!_isSolid(newX, _state.playerY)) _state.playerX = newX;
      if (!_isSolid(_state.playerX, newY)) _state.playerY = newY;
    }
    if (_keysPressed.contains(LogicalKeyboardKey.keyD)) {
      final newX = _state.playerX + cos(_state.playerAngle + pi / 2) * moveSpeed;
      final newY = _state.playerY + sin(_state.playerAngle + pi / 2) * moveSpeed;
      if (!_isSolid(newX, _state.playerY)) _state.playerX = newX;
      if (!_isSolid(_state.playerX, newY)) _state.playerY = newY;
    }

    if (_keysPressed.contains(LogicalKeyboardKey.arrowLeft)) {
      _state.playerAngle -= rotSpeed;
    }
    if (_keysPressed.contains(LogicalKeyboardKey.arrowRight)) {
      _state.playerAngle += rotSpeed;
    }
  }

  bool _isSolid(double x, double y) {
    final map = _state.scene.map;
    if (map.layers.isEmpty) return false;
    final solids = map.layers[0].solids;
    
    int mapX = x.toInt();
    int mapY = y.toInt();
    
    if (mapX < 0 || mapX >= map.width || mapY < 0 || mapY >= map.height) {
      return true;
    }
    final index = mapY * map.width + mapX;
    if (solids.length > index && solids[index]) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          _keysPressed.add(event.logicalKey);
        } else if (event is KeyUpEvent) {
          _keysPressed.remove(event.logicalKey);
        }
        return KeyEventResult.handled;
      },
      child: GestureDetector(
        onPanUpdate: (details) {
          _state.playerAngle += details.delta.dx * 0.01;
        },
        child: Container(
          color: Colors.black,
          width: double.infinity,
          height: double.infinity,
          child: CustomPaint(
            painter: RaycastRenderer(_state),
          ),
        ),
      ),
    );
  }
}
