import 'dart:ui';

/// Converts between screen coordinates and normalized frame coordinates (0.0–1.0).
class CoordinateConverter {
  final Size frameSize;
  final Rect viewport;
  final double zoom;
  final Offset scroll;

  CoordinateConverter({
    required this.frameSize,
    required this.viewport,
    this.zoom = 1.0,
    this.scroll = Offset.zero,
  });

  /// Maps a screen-space point to a normalized (0.0–1.0) frame-space point.
  Offset screenToFrame(Offset screenPoint) {
    final centered = contentRect().contains(screenPoint);
    if (!centered) return Offset.zero;
    final local = screenPoint - contentRect().topLeft;
    return Offset(local.dx / contentRect().width, local.dy / contentRect().height);
  }

  /// Maps a normalized frame-space point to screen space.
  Offset frameToScreen(Offset framePoint) {
    final r = contentRect();
    return Offset(r.left + framePoint.dx * r.width, r.top + framePoint.dy * r.height);
  }

  /// The rectangle where the frame is rendered on screen (centered, scaled).
  Rect contentRect() {
    final scale = _fitScale();
    final w = frameSize.width * scale * zoom;
    final h = frameSize.height * scale * zoom;
    final cx = viewport.center.dx + scroll.dx;
    final cy = viewport.center.dy + scroll.dy;
    return Rect.fromCenter(center: Offset(cx, cy), width: w, height: h);
  }

  double _fitScale() {
    final scaleX = viewport.width / frameSize.width;
    final scaleY = viewport.height / frameSize.height;
    return scaleX < scaleY ? scaleX : scaleY;
  }

  /// Normalized rect from screen rect (e.g. a drag gesture).
  Rect screenRectToFrame(Rect screenRect) {
    final a = screenToFrame(screenRect.topLeft);
    final b = screenToFrame(screenRect.bottomRight);
    return Rect.fromLTRB(a.dx, a.dy, b.dx, b.dy).normalize();
  }
}

extension RectNormalize on Rect {
  Rect normalize() {
    final l = left < right ? left : right;
    final t = top < bottom ? top : bottom;
    final r = left < right ? right : left;
    final b = top < bottom ? bottom : top;
    return Rect.fromLTRB(l, t, r, b);
  }
}
