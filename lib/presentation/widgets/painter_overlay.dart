import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/anchor_data.dart';
import '../../domain/entities/hitbox_data.dart';
import '../../domain/entities/sprite_frame.dart';
import '../bloc/sprite_sheet_bloc.dart';
import 'coordinate_converter.dart';

class PainterOverlay extends StatefulWidget {
  final SpriteFrame frame;
  final List<HitboxData> hitboxes;
  final AnchorData? anchor;
  final HitboxType currentHitboxType;
  final String? selectedHitboxId;
  final ValueChanged<String?> onSelectHitbox;

  const PainterOverlay({
    super.key,
    required this.frame,
    required this.hitboxes,
    this.anchor,
    required this.currentHitboxType,
    this.selectedHitboxId,
    required this.onSelectHitbox,
  });

  @override
  State<PainterOverlay> createState() => _PainterOverlayState();
}

class _PainterOverlayState extends State<PainterOverlay> {
  ui.Image? _frameImage;

  Offset? _dragStartFrame;
  int _resizeHandleIndex = -1;

  Offset? _newHitboxStartScreen;
  Offset? _newHitboxCurrentScreen;
  bool _isDrawingNew = false;

  @override
  void initState() {
    super.initState();
    _loadFrame();
  }

  @override
  void didUpdateWidget(PainterOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.frame.id != widget.frame.id) _loadFrame();
  }

  Future<void> _loadFrame() async {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      widget.frame.imageBytes,
      widget.frame.width,
      widget.frame.height,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    final image = await completer.future;
    if (!mounted) {
      image.dispose();
      return;
    }
    _frameImage?.dispose();
    setState(() => _frameImage = image);
  }

  @override
  void dispose() {
    _frameImage?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = Offset.zero & constraints.biggest;
        final converter = CoordinateConverter(
          frameSize: Size(widget.frame.width.toDouble(), widget.frame.height.toDouble()),
          viewport: viewport,
        );

        return GestureDetector(
          onTapUp: (details) => _onTap(details.localPosition, converter),
          onPanStart: (details) => _onDragStart(details.localPosition, converter),
          onPanUpdate: (details) => _onDragUpdate(details.localPosition, converter),
          onPanEnd: (_) => _onDragEnd(converter),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRect(
                child: CustomPaint(
                  size: constraints.biggest,
                  painter: _FrameWithHitboxesPainter(
                    frameImage: _frameImage,
                    hitboxes: widget.hitboxes,
                    anchor: widget.anchor,
                    selectedHitboxId: widget.selectedHitboxId,
                    converter: converter,
                    newHitboxRect: _isDrawingNew && _newHitboxStartScreen != null && _newHitboxCurrentScreen != null
                        ? Rect.fromPoints(_newHitboxStartScreen!, _newHitboxCurrentScreen!)
                        : null,
                    currentHitboxType: widget.currentHitboxType,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _onTap(Offset pos, CoordinateConverter converter) {
    final framePt = converter.screenToFrame(pos);

    // Check if tapped on existing hitbox
    for (final hb in widget.hitboxes.reversed) {
      if (framePt.dx >= hb.x &&
          framePt.dx <= hb.x + hb.w &&
          framePt.dy >= hb.y &&
          framePt.dy <= hb.y + hb.h) {
        widget.onSelectHitbox(widget.selectedHitboxId == hb.id ? null : hb.id);
        return;
      }
    }

    // Place anchor
    context.read<AssetBloc>().add(
          SetAnchorEvent(frameId: widget.frame.id, x: framePt.dx, y: framePt.dy),
        );
    widget.onSelectHitbox(null);
  }

  void _onDragStart(Offset pos, CoordinateConverter converter) {
    final framePt = converter.screenToFrame(pos);
    _dragStartFrame = framePt;

    // Check if dragging from a resize handle of selected hitbox
    if (widget.selectedHitboxId != null) {
      final hb = widget.hitboxes.where((h) => h.id == widget.selectedHitboxId).firstOrNull;
      if (hb != null) {
        final corners = [
          Offset(hb.x, hb.y),
          Offset(hb.x + hb.w, hb.y),
          Offset(hb.x, hb.y + hb.h),
          Offset(hb.x + hb.w, hb.y + hb.h),
        ];
        for (var i = 0; i < corners.length; i++) {
          final cornerScreen = converter.frameToScreen(corners[i]);
          if ((pos - cornerScreen).distance < 20.0) {
            _resizeHandleIndex = i;
            return;
          }
        }
      }
    }

    _resizeHandleIndex = -1;
    if (widget.selectedHitboxId == null) {
      _isDrawingNew = true;
      _newHitboxStartScreen = pos;
      _newHitboxCurrentScreen = pos;
      setState(() {});
    }
  }

  void _onDragUpdate(Offset pos, CoordinateConverter converter) {
    if (_isDrawingNew) {
      _newHitboxCurrentScreen = pos;
      setState(() {});
      return;
    }

    if (_dragStartFrame == null) return;
    final framePt = converter.screenToFrame(pos);

    if (widget.selectedHitboxId != null) {
      final hb = widget.hitboxes.where((h) => h.id == widget.selectedHitboxId).firstOrNull;
      if (hb == null) return;

      if (_resizeHandleIndex != -1) {
        double nx = hb.x;
        double ny = hb.y;
        double nw = hb.w;
        double nh = hb.h;

        if (_resizeHandleIndex == 0) { // TL
          nx = framePt.dx;
          ny = framePt.dy;
          nw = hb.w + (hb.x - nx);
          nh = hb.h + (hb.y - ny);
        } else if (_resizeHandleIndex == 1) { // TR
          ny = framePt.dy;
          nw = framePt.dx - hb.x;
          nh = hb.h + (hb.y - ny);
        } else if (_resizeHandleIndex == 2) { // BL
          nx = framePt.dx;
          nw = hb.w + (hb.x - nx);
          nh = framePt.dy - hb.y;
        } else if (_resizeHandleIndex == 3) { // BR
          nw = framePt.dx - hb.x;
          nh = framePt.dy - hb.y;
        }

        final newRect = Rect.fromLTRB(nx, ny, nx + nw, ny + nh).normalize();
        context.read<AssetBloc>().add(
              UpdateHitboxEvent(
                hitboxId: hb.id,
                x: newRect.left.clamp(0.0, 1.0),
                y: newRect.top.clamp(0.0, 1.0),
                w: newRect.width.clamp(0.0, 1.0 - newRect.left),
                h: newRect.height.clamp(0.0, 1.0 - newRect.top),
              ),
            );
      } else {
        final dx = framePt.dx - _dragStartFrame!.dx;
        final dy = framePt.dy - _dragStartFrame!.dy;
        _dragStartFrame = framePt;

        context.read<AssetBloc>().add(
              UpdateHitboxEvent(
                hitboxId: hb.id,
                x: (hb.x + dx).clamp(0.0, 1.0 - hb.w),
                y: (hb.y + dy).clamp(0.0, 1.0 - hb.h),
                w: hb.w,
                h: hb.h,
              ),
            );
      }
    }
  }

  void _onDragEnd(CoordinateConverter converter) {
    if (_isDrawingNew && _newHitboxStartScreen != null && _newHitboxCurrentScreen != null) {
      final distance = (_newHitboxCurrentScreen! - _newHitboxStartScreen!).distance;
      if (distance > 8.0) {
        final screenRect = Rect.fromPoints(_newHitboxStartScreen!, _newHitboxCurrentScreen!);
        final frameRect = converter.screenRectToFrame(screenRect);
        
        // minimum viable hitbox
        if (frameRect.width > 0.01 && frameRect.height > 0.01) {
          context.read<AssetBloc>().add(
                AddHitboxEvent(
                  frameId: widget.frame.id,
                  type: widget.currentHitboxType,
                  x: frameRect.left.clamp(0.0, 1.0),
                  y: frameRect.top.clamp(0.0, 1.0),
                  w: frameRect.width.clamp(0.0, 1.0 - frameRect.left),
                  h: frameRect.height.clamp(0.0, 1.0 - frameRect.top),
                ),
              );
        }
      }
    }
    _dragStartFrame = null;
    _isDrawingNew = false;
    _newHitboxStartScreen = null;
    _newHitboxCurrentScreen = null;
    setState(() {});
  }
}

class _FrameWithHitboxesPainter extends CustomPainter {
  final ui.Image? frameImage;
  final List<HitboxData> hitboxes;
  final AnchorData? anchor;
  final String? selectedHitboxId;
  final CoordinateConverter converter;
  final Rect? newHitboxRect;
  final HitboxType currentHitboxType;

  _FrameWithHitboxesPainter({
    required this.frameImage,
    required this.hitboxes,
    this.anchor,
    this.selectedHitboxId,
    required this.converter,
    this.newHitboxRect,
    required this.currentHitboxType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (frameImage != null) {
      final r = converter.contentRect();
      canvas.drawImageRect(
        frameImage!,
        Rect.fromLTWH(0, 0, frameImage!.width.toDouble(), frameImage!.height.toDouble()),
        r,
        Paint(),
      );
    }

    final hitboxPaint = Paint()..style = PaintingStyle.stroke;
    for (final hb in hitboxes) {
      final isSel = hb.id == selectedHitboxId;
      final a = converter.frameToScreen(Offset(hb.x, hb.y));
      final b = converter.frameToScreen(Offset(hb.x + hb.w, hb.y + hb.h));
      final rect = Rect.fromLTRB(a.dx, a.dy, b.dx, b.dy);

      hitboxPaint.color = _color(hb.type).withValues(alpha: isSel ? 0.9 : 0.6);
      hitboxPaint.strokeWidth = isSel ? 3 : 2;
      canvas.drawRect(rect, hitboxPaint);

      final fill = Paint()
        ..color = _color(hb.type).withValues(alpha: 0.15)
        ..style = PaintingStyle.fill;
      canvas.drawRect(rect, fill);

      if (isSel) {
        final label = TextPainter(
          text: TextSpan(
            text: hb.type.name.toUpperCase(),
            style: TextStyle(color: _color(hb.type), fontSize: 11, fontWeight: FontWeight.bold),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        label.paint(canvas, rect.topLeft + const Offset(4, 4));

        for (final c in [rect.topLeft, rect.topRight, rect.bottomLeft, rect.bottomRight]) {
          canvas.drawRect(Rect.fromCenter(center: c, width: 10, height: 10),
              Paint()..color = Colors.white..style = PaintingStyle.fill);
          canvas.drawRect(Rect.fromCenter(center: c, width: 10, height: 10),
              Paint()..color = Colors.black54..style = PaintingStyle.stroke..strokeWidth = 1.5);
        }
      }
    }

    if (anchor != null) {
      final c = converter.frameToScreen(Offset(anchor!.x, anchor!.y));
      final p = Paint()..color = Colors.yellow..strokeWidth = 2;
      final r = 8.0;
      canvas.drawLine(Offset(c.dx - r, c.dy), Offset(c.dx + r, c.dy), p);
      canvas.drawLine(Offset(c.dx, c.dy - r), Offset(c.dx, c.dy + r), p);
      canvas.drawCircle(c, 3, p..style = PaintingStyle.fill);
    }

    if (newHitboxRect != null) {
      final p = Paint()
        ..color = _color(currentHitboxType).withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawRect(newHitboxRect!, p);
      
      final fill = Paint()
        ..color = _color(currentHitboxType).withValues(alpha: 0.15)
        ..style = PaintingStyle.fill;
      canvas.drawRect(newHitboxRect!, fill);
    }
  }

  Color _color(HitboxType type) => switch (type) {
        HitboxType.body => Colors.green,
        HitboxType.attack => Colors.red,
        HitboxType.hurt => Colors.blue,
      };

  @override
  bool shouldRepaint(_FrameWithHitboxesPainter old) => true;
}
