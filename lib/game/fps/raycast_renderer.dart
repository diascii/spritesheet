import 'dart:math';
import 'package:flutter/material.dart';
import 'fps_game_state.dart';

class RaycastRenderer extends CustomPainter {
  final FPSGameState state;

  RaycastRenderer(this.state);

  @override
  void paint(Canvas canvas, Size size) {
    _drawCeilingAndFloor(canvas, size);
    _castWalls(canvas, size);
  }

  void _drawCeilingAndFloor(Canvas canvas, Size size) {
    final halfHeight = size.height / 2;
    // Ceiling
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, halfHeight),
      Paint()..color = const Color(0xFF333333),
    );
    // Floor
    canvas.drawRect(
      Rect.fromLTWH(0, halfHeight, size.width, halfHeight),
      Paint()..color = const Color(0xFF555555),
    );
  }

  void _castWalls(Canvas canvas, Size size) {
    final map = state.scene.map;
    if (map.layers.isEmpty) return;
    
    final solids = map.layers[0].solids;
    final mapWidth = map.width;
    final mapHeight = map.height;

    final numRays = size.width.toInt();
    final fov = pi / 3.0; // 60 degrees

    for (int x = 0; x < numRays; x++) {
      // Calculate ray position and direction
      final cameraX = 2 * x / numRays - 1; // x-coordinate in camera space
      
      final rayDirX = cos(state.playerAngle) + sin(state.playerAngle) * cameraX * tan(fov / 2);
      final rayDirY = sin(state.playerAngle) - cos(state.playerAngle) * cameraX * tan(fov / 2);

      // Which box of the map we're in
      int mapX = state.playerX.toInt();
      int mapY = state.playerY.toInt();

      // Length of ray from current position to next x or y-side
      double sideDistX;
      double sideDistY;

      // Length of ray from one x or y-side to next x or y-side
      final deltaDistX = (rayDirX == 0) ? 1e30 : (1.0 / rayDirX).abs();
      final deltaDistY = (rayDirY == 0) ? 1e30 : (1.0 / rayDirY).abs();
      double perpWallDist;

      // What direction to step in x or y-direction (either +1 or -1)
      int stepX;
      int stepY;

      bool hit = false; // Was there a wall hit?
      int side = 0; // Was a NS or a EW wall hit?

      // Calculate step and initial sideDist
      if (rayDirX < 0) {
        stepX = -1;
        sideDistX = (state.playerX - mapX) * deltaDistX;
      } else {
        stepX = 1;
        sideDistX = (mapX + 1.0 - state.playerX) * deltaDistX;
      }
      if (rayDirY < 0) {
        stepY = -1;
        sideDistY = (state.playerY - mapY) * deltaDistY;
      } else {
        stepY = 1;
        sideDistY = (mapY + 1.0 - state.playerY) * deltaDistY;
      }

      // Perform DDA
      while (!hit) {
        // Jump to next map square, either in x-direction, or in y-direction
        if (sideDistX < sideDistY) {
          sideDistX += deltaDistX;
          mapX += stepX;
          side = 0;
        } else {
          sideDistY += deltaDistY;
          mapY += stepY;
          side = 1;
        }
        
        // Check if ray has hit a wall
        if (mapX >= 0 && mapX < mapWidth && mapY >= 0 && mapY < mapHeight) {
          final index = mapY * mapWidth + mapX;
          if (solids.length > index && solids[index]) {
            hit = true;
          }
        } else {
          hit = true; // Hit boundary
        }
      }

      // Calculate distance projected on camera direction (Euclidean distance would give fisheye effect!)
      if (side == 0) {
        perpWallDist = (mapX - state.playerX + (1 - stepX) / 2) / rayDirX;
      } else {
        perpWallDist = (mapY - state.playerY + (1 - stepY) / 2) / rayDirY;
      }

      // Calculate height of line to draw on screen
      final lineHeight = (size.height / perpWallDist).toInt();

      // Calculate lowest and highest pixel to fill in current stripe
      int drawStart = -lineHeight ~/ 2 + size.height ~/ 2;
      if (drawStart < 0) drawStart = 0;
      int drawEnd = lineHeight ~/ 2 + size.height ~/ 2;
      if (drawEnd >= size.height) drawEnd = size.height.toInt() - 1;

      // Draw vertical line
      final color = side == 1 ? Colors.grey[700]! : Colors.grey[400]!;
      canvas.drawLine(
        Offset(x.toDouble(), drawStart.toDouble()),
        Offset(x.toDouble(), drawEnd.toDouble()),
        Paint()..color = color..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant RaycastRenderer oldDelegate) {
    return true; // Always repaint for now
  }
}
