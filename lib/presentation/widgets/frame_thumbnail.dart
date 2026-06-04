import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../data/services/image_registry.dart';

class FrameThumbnail extends StatefulWidget {
  final String frameId;
  final Uint8List rgbaBytes;
  final int width;
  final int height;
  final double size;
  final FilterQuality filterQuality;

  const FrameThumbnail({
    super.key,
    required this.frameId,
    required this.rgbaBytes,
    required this.width,
    required this.height,
    this.size = 48,
    this.filterQuality = FilterQuality.none,
  });

  @override
  State<FrameThumbnail> createState() => _FrameThumbnailState();
}

class _FrameThumbnailState extends State<FrameThumbnail> {
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(FrameThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.frameId != widget.frameId || oldWidget.rgbaBytes != widget.rgbaBytes) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    final image = await ImageRegistry.instance.getImage(
      widget.frameId,
      widget.rgbaBytes,
      widget.width,
      widget.height,
    );
    if (mounted) setState(() { _image = image; });
  }

  @override
  Widget build(BuildContext context) {
    if (_image == null) {
      return Container(
        width: widget.size,
        height: widget.size,
        color: Colors.grey.shade200,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    return RawImage(
      image: _image,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.contain,
      filterQuality: widget.filterQuality,
    );
  }
}
