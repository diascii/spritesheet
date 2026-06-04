import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image/image.dart' as img;
import 'package:file_picker/file_picker.dart';

import '../../domain/entities/anchor_data.dart';
import '../../domain/entities/hitbox_data.dart';
import '../../domain/entities/sprite_frame.dart';
import '../bloc/sprite_sheet_bloc.dart';
import 'checkerboard.dart';
import 'hitbox_toolbar.dart';
import 'painter_overlay.dart';

class AnimationPreview extends StatefulWidget {
  final List<SpriteFrame> frames;

  const AnimationPreview({super.key, required this.frames});

  @override
  State<AnimationPreview> createState() => _AnimationPreviewState();
}

class _AnimationPreviewState extends State<AnimationPreview> {
  int _currentFrame = 0;
  double _fps = 24;
  bool _isPlaying = true;
  bool _paintMode = false;
  bool _loop = true;
  Timer? _timer;
  ui.Image? _displayImage;
  final _anchorXCtrl = TextEditingController();
  final _anchorYCtrl = TextEditingController();
  
  HitboxType _selectedHitboxType = HitboxType.body;
  String? _selectedHitboxId;
  String? _selectedTag;

  List<SpriteFrame> get _visibleFrames {
    if (_selectedTag == null || _selectedTag!.isEmpty) return widget.frames;
    final filtered = widget.frames.where((f) => f.tag == _selectedTag).toList();
    return filtered.isNotEmpty ? filtered : widget.frames;
  }

  @override
  void initState() {
    super.initState();
    _loadFrame(0);
    _startTimer();
  }

  @override
  void didUpdateWidget(AnimationPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.frames != widget.frames) {
      if (_currentFrame >= _visibleFrames.length) {
        _currentFrame = 0;
      }
      _loadFrame(_currentFrame);
      if (_isPlaying) _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _displayImage?.dispose();
    _anchorXCtrl.dispose();
    _anchorYCtrl.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    final frames = _visibleFrames;
    if (!_isPlaying || frames.length <= 1) return;

    final interval = Duration(microseconds: (1000000 / _fps).round());
    _timer = Timer.periodic(interval, (_) {
      if (!mounted) return;
      final next = _currentFrame + 1;
      if (next >= frames.length) {
        if (_loop) {
          _advanceFrame(0);
        } else {
          setState(() => _isPlaying = false);
          _timer?.cancel();
        }
      } else {
        _advanceFrame(next);
      }
    });
  }

  void _advanceFrame(int index) {
    setState(() => _currentFrame = index);
    if (!_paintMode) _loadFrame(index);
  }

  Future<void> _loadFrame(int index) async {
    final frames = _visibleFrames;
    if (index >= frames.length) return;
    final frame = frames[index];

    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      frame.imageBytes,
      frame.width,
      frame.height,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    final image = await completer.future;
    if (!mounted) {
      image.dispose();
      return;
    }
    _displayImage?.dispose();
    setState(() => _displayImage = image);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AssetBloc, SpriteSheetState>(
      builder: (context, _) {
        if (_visibleFrames.isEmpty) return const Center(child: Text('No frames match tag'));
        final currentFrame = _visibleFrames[_currentFrame];
        // ignore: invalid_use_of_visible_for_testing_member
        final annotations = context.read<AssetBloc>().annotations;
        final annotation =
            annotations.where((a) => a.frameId == currentFrame.id).firstOrNull;

        final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

        final canvasArea = InteractiveViewer(
          minScale: 0.5,
          maxScale: 4,
          child: CustomPaint(
            painter: const CheckerboardPainter(
              color1: Color(0xFF2A2A2A),
              color2: Color(0xFF1E1E1E),
              squareSize: 16.0,
            ),
            child: _paintMode
                ? PainterOverlay(
                    frame: currentFrame,
                    hitboxes: annotation?.hitboxes ?? [],
                    anchor: annotation?.anchor,
                    currentHitboxType: _selectedHitboxType,
                    selectedHitboxId: _selectedHitboxId,
                    onSelectHitbox: (id) => setState(() => _selectedHitboxId = id),
                  )
                : Center(
                    child: _displayImage == null
                        ? const CircularProgressIndicator()
                        : RawImage(
                            image: _displayImage,
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                  ),
          ),
        );

        if (isLandscape) {
          return Row(
            children: [
              _buildFigmaLeftColumn(context, currentFrame, annotation?.anchor),
              if (_paintMode) const VerticalDivider(width: 1, color: Colors.grey, thickness: 1),
              if (_paintMode) _buildFigmaMiddleColumn(context, currentFrame, annotation?.anchor),
              Expanded(child: canvasArea),
            ],
          );
        }

        final mainColumn = Column(
          children: [
            if (_paintMode) ...[
              HitboxToolbar(
                currentType: _selectedHitboxType,
                onTypeChanged: (type) {
                  setState(() => _selectedHitboxType = type);
                  if (_selectedHitboxId != null) {
                    context.read<AssetBloc>().add(UpdateHitboxEvent(hitboxId: _selectedHitboxId!, type: type));
                  }
                },
                hasSelectedHitbox: _selectedHitboxId != null,
                onDeleteHitbox: () {
                  if (_selectedHitboxId != null) {
                    context.read<AssetBloc>().add(RemoveHitboxEvent(hitboxId: _selectedHitboxId!));
                    setState(() => _selectedHitboxId = null);
                  }
                },
                onClearAnchor: annotation?.anchor != null
                    ? () => context.read<AssetBloc>().add(ClearAnchorEvent(frameId: currentFrame.id))
                    : null,
              ),
              const SizedBox(height: 8),
            ],
            Expanded(child: canvasArea),
            const SizedBox(height: 6),
            _buildControls(context, currentFrame, annotation?.anchor),
          ],
        );

        if (!_paintMode) return mainColumn;

        return Column(
          children: [
            Expanded(child: mainColumn),
            const Divider(height: 1),
            _buildAnalogControls(context, currentFrame, annotation?.anchor, false),
          ],
        );
      },
    );
  }

  void _togglePaintMode() {
    _timer?.cancel();
    setState(() {
      _paintMode = !_paintMode;
      _isPlaying = false;
      _selectedHitboxId = null;
    });
    if (!_paintMode) _loadFrame(_currentFrame);
  }

  Widget _buildFigmaLeftColumn(BuildContext context, SpriteFrame currentFrame, AnchorData? anchor) {
    final allTags = widget.frames.map((f) => f.tag).whereType<String>().where((t) => t.isNotEmpty).toSet().toList()..sort();
    return Container(
      width: 120, // Increased width to fit slider and buttons side-by-side
      color: const Color(0xFF242424),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Left side: Buttons & Playback
                Column(
                  children: [
                    if (allTags.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: DropdownButton<String?>(
                          value: _selectedTag,
                          hint: const Text('All Tags', style: TextStyle(color: Colors.white, fontSize: 12)),
                          dropdownColor: const Color(0xFF242424),
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                          icon: const Icon(Icons.filter_list, color: Colors.white, size: 16),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('All Tags')),
                            ...allTags.map((t) => DropdownMenuItem(value: t, child: Text(t))),
                          ],
                          onChanged: (v) {
                            setState(() {
                              _selectedTag = v;
                              _currentFrame = 0;
                            });
                            _loadFrame(0);
                            if (_isPlaying) _startTimer();
                          },
                        ),
                      ),
                    TextButton(
                      onPressed: _exportGif,
                      child: const Text('GIF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    IconButton(
                      icon: Icon(Icons.edit, color: _paintMode ? Colors.deepPurpleAccent : Colors.white),
                      onPressed: _togglePaintMode,
                    ),
                    IconButton(
                      icon: Icon(Icons.loop, color: _loop ? Colors.deepPurpleAccent : Colors.white),
                      onPressed: () => setState(() => _loop = !_loop),
                    ),
                    const SizedBox(height: 32),
                    IconButton(
                      icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 32),
                      onPressed: () {
                        if (!_isPlaying) {
                          if (!_loop && _currentFrame >= _visibleFrames.length - 1) {
                            _advanceFrame(0);
                          }
                          setState(() => _isPlaying = true);
                          _startTimer();
                        } else {
                          _timer?.cancel();
                          setState(() => _isPlaying = false);
                        }
                      },
                    ),
                    Text('${_currentFrame + 1}/${_visibleFrames.length}', style: const TextStyle(color: Colors.white)),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.skip_previous, color: Colors.white, size: 20),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          onPressed: _currentFrame > 0
                              ? () {
                                  _timer?.cancel();
                                  setState(() => _isPlaying = false);
                                  _advanceFrame(_currentFrame - 1);
                                }
                              : null,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.skip_next, color: Colors.white, size: 20),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          onPressed: _currentFrame < _visibleFrames.length - 1
                              ? () {
                                  _timer?.cancel();
                                  setState(() => _isPlaying = false);
                                  _advanceFrame(_currentFrame + 1);
                                }
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
                // Right side: FPS Slider
                Column(
                  children: [
                    Text('${_fps.round()} fps', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    SizedBox(
                      height: 120,
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: Slider(
                          value: _fps,
                          min: 1,
                          max: 60,
                          activeColor: Colors.deepPurpleAccent,
                          onChanged: (v) {
                            setState(() => _fps = v);
                            _startTimer();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _figmaTypeBtn(HitboxType type, String label) {
    final isSel = _selectedHitboxType == type;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: isSel ? Colors.deepPurpleAccent : Colors.grey),
        color: isSel ? Colors.deepPurpleAccent.withValues(alpha: 0.2) : Colors.transparent,
      ),
      child: InkWell(
        onTap: () {
          setState(() => _selectedHitboxType = type);
          if (_selectedHitboxId != null) {
            context.read<AssetBloc>().add(UpdateHitboxEvent(hitboxId: _selectedHitboxId!, type: type));
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: isSel ? Colors.white : Colors.grey, fontSize: 10)),
        ),
      ),
    );
  }

  Widget _buildFigmaMiddleColumn(BuildContext context, SpriteFrame currentFrame, AnchorData? anchor) {
    return Container(
      width: 150,
      color: const Color(0xFF1E1E1E),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.white),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                  onPressed: () {
                    if (_selectedHitboxId != null) {
                      context.read<AssetBloc>().add(RemoveHitboxEvent(hitboxId: _selectedHitboxId!));
                      setState(() => _selectedHitboxId = null);
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.location_on, size: 20, color: Colors.deepPurpleAccent),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                  onPressed: anchor != null
                      ? () => context.read<AssetBloc>().add(ClearAnchorEvent(frameId: currentFrame.id))
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Type:', style: TextStyle(fontSize: 10, color: Colors.white)),
            _figmaTypeBtn(HitboxType.body, 'Body'),
            _figmaTypeBtn(HitboxType.attack, 'Attack'),
            _figmaTypeBtn(HitboxType.hurt, 'Hurt'),
            const SizedBox(height: 32),
            _buildDPad(currentFrame, anchor),
            const SizedBox(height: 16),
            const Text('Anchor Position:', style: TextStyle(fontSize: 10, color: Colors.white)),
            _buildAnchorInputs(context, currentFrame, anchor),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(
      BuildContext context, SpriteFrame currentFrame, AnchorData? anchor) {
    final total = _visibleFrames.length;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    final playControls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
          onPressed: () {
            if (!_isPlaying) {
              if (!_loop && _currentFrame >= _visibleFrames.length - 1) {
                _advanceFrame(0);
              }
              setState(() => _isPlaying = true);
              _startTimer();
            } else {
              _timer?.cancel();
              setState(() => _isPlaying = false);
            }
          },
          tooltip: _isPlaying ? 'Pause' : 'Play',
        ),
        IconButton(
          icon: const Icon(Icons.skip_previous, size: 20),
          onPressed: _currentFrame > 0
              ? () {
                  _timer?.cancel();
                  setState(() => _isPlaying = false);
                  _advanceFrame(_currentFrame - 1);
                }
              : null,
          tooltip: 'Previous Frame',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text('${_currentFrame + 1} / $total',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ),
        IconButton(
          icon: const Icon(Icons.skip_next, size: 20),
          onPressed: _currentFrame < total - 1
              ? () {
                  _timer?.cancel();
                  setState(() => _isPlaying = false);
                  _advanceFrame(_currentFrame + 1);
                }
              : null,
          tooltip: 'Next Frame',
        ),
      ],
    );

    final allTags = widget.frames.map((f) => f.tag).whereType<String>().where((t) => t.isNotEmpty).toSet().toList()..sort();
    final toolControls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (allTags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: DropdownButton<String?>(
              value: _selectedTag,
              hint: const Text('All Tags', style: TextStyle(fontSize: 12)),
              underline: const SizedBox(),
              icon: const Icon(Icons.filter_list, size: 16),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Tags', style: TextStyle(fontSize: 12))),
                ...allTags.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 12)))),
              ],
              onChanged: (v) {
                setState(() {
                  _selectedTag = v;
                  _currentFrame = 0;
                });
                _loadFrame(0);
                if (_isPlaying) _startTimer();
              },
            ),
          ),
        IconButton(
          icon: Icon(Icons.loop, color: _loop ? Theme.of(context).colorScheme.primary : null),
          onPressed: () => setState(() => _loop = !_loop),
          tooltip: 'Loop Animation',
        ),
        IconButton(
          icon: Icon(Icons.edit, color: _paintMode ? Colors.orange : null),
          onPressed: () {
            _timer?.cancel();
            setState(() {
              _paintMode = !_paintMode;
              _isPlaying = false;
              _selectedHitboxId = null;
            });
            if (!_paintMode) _loadFrame(_currentFrame);
          },
          tooltip: 'Paint Mode',
        ),
        IconButton(
          icon: const Icon(Icons.gif_box),
          onPressed: _exportGif,
          tooltip: 'Export GIF',
        ),
      ],
    );

    final sliderControl = _paintMode ? const SizedBox.shrink() : Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isLandscape) const Icon(Icons.speed, size: 16, color: Colors.grey),
        if (isLandscape) const SizedBox(width: 16),
        SizedBox(
          width: isLandscape ? 150 : null,
          child: Slider(
            value: _fps,
            min: 1,
            max: 60,
            divisions: 59,
            label: _fps.round().toString(),
            onChanged: (v) {
              setState(() => _fps = v);
              _startTimer();
            },
          ),
        ),
        Text('${_fps.round()} FPS', style: const TextStyle(fontSize: 12)),
        if (isLandscape) const SizedBox(width: 16),
      ],
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: isLandscape
            ? Row(
                children: [
                  playControls,
                  if (!_paintMode) Expanded(child: Center(child: sliderControl)) else const Spacer(),
                  toolControls,
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [playControls, toolControls],
                  ),
                  if (!_paintMode)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          Expanded(child: sliderControl),
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildAnalogControls(BuildContext context, SpriteFrame currentFrame, AnchorData? anchor, bool isLandscape) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: isLandscape
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDPad(currentFrame, anchor),
                const SizedBox(height: 24),
                _buildAnchorInputs(context, currentFrame, anchor),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDPad(currentFrame, anchor),
                const SizedBox(width: 24),
                _buildAnchorInputs(context, currentFrame, anchor),
              ],
            ),
    );
  }

  Widget _buildDPad(SpriteFrame currentFrame, AnchorData? anchor) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _nudgeBtn(Icons.keyboard_arrow_up, anchor == null ? null : () => _nudge(0, -1, currentFrame, anchor)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _nudgeBtn(Icons.keyboard_arrow_left, anchor == null ? null : () => _nudge(-1, 0, currentFrame, anchor)),
              const SizedBox(width: 24),
              _nudgeBtn(Icons.keyboard_arrow_right, anchor == null ? null : () => _nudge(1, 0, currentFrame, anchor)),
            ],
          ),
          _nudgeBtn(Icons.keyboard_arrow_down, anchor == null ? null : () => _nudge(0, 1, currentFrame, anchor)),
        ],
      ),
    );
  }

  Widget _nudgeBtn(IconData icon, VoidCallback? onPressed) {
    return IconButton(
      icon: Icon(icon, size: 24), // slightly larger for the D-Pad
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      onPressed: onPressed,
    );
  }

  void _nudge(int dxPx, int dyPx, SpriteFrame frame, AnchorData anchor) {
    final stepX = 1.0 / frame.width;
    final stepY = 1.0 / frame.height;
    context.read<AssetBloc>().add(SetAnchorEvent(
      frameId: frame.id,
      x: (anchor.x + dxPx * stepX).clamp(0.0, 1.0),
      y: (anchor.y + dyPx * stepY).clamp(0.0, 1.0),
    ));
  }

  Widget _buildAnchorInputs(BuildContext context, SpriteFrame frame, AnchorData? anchor) {
    if (anchor == null) {
      _anchorXCtrl.clear();
      _anchorYCtrl.clear();
    } else {
      _anchorXCtrl.text = (anchor.x * frame.width).round().toString();
      _anchorYCtrl.text = (anchor.y * frame.height).round().toString();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Anchor Position', style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('X: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            SizedBox(
              width: 50,
              height: 28,
              child: TextField(
                controller: _anchorXCtrl,
                enabled: anchor != null,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  border: OutlineInputBorder(),
                  hintText: '-',
                ),
                onSubmitted: (v) {
                  if (anchor == null) return;
                  final px = double.tryParse(v)?.clamp(0, frame.width.toDouble());
                  if (px != null) {
                    context.read<AssetBloc>().add(SetAnchorEvent(
                      frameId: frame.id,
                      x: px / frame.width,
                      y: anchor.y,
                    ));
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            const Text('Y: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            SizedBox(
              width: 50,
              height: 28,
              child: TextField(
                controller: _anchorYCtrl,
                enabled: anchor != null,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  border: OutlineInputBorder(),
                  hintText: '-',
                ),
                onSubmitted: (v) {
                  if (anchor == null) return;
                  final py = double.tryParse(v)?.clamp(0, frame.height.toDouble());
                  if (py != null) {
                    context.read<AssetBloc>().add(SetAnchorEvent(
                      frameId: frame.id,
                      x: anchor.x,
                      y: py / frame.height,
                    ));
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _exportGif() async {
    final dir = await FilePicker.platform.getDirectoryPath(dialogTitle: 'Select Folder to Save GIF');
    if (dir == null || !mounted) return;

    final name = 'animation_${DateTime.now().millisecondsSinceEpoch}.gif';
    final path = '$dir/$name';

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating GIF...')),
    );

    try {
      final encoder = img.GifEncoder();
      final duration100th = (100 / _fps).round();

      // Find max dimensions to ensure all frames fit on a uniform canvas
      int maxWidth = 0;
      int maxHeight = 0;
      for (final f in widget.frames) {
        if (f.width > maxWidth) maxWidth = f.width;
        if (f.height > maxHeight) maxHeight = f.height;
      }

      for (final frame in widget.frames) {
        // Decode raw RGBA to image
        final frameImg = img.Image.fromBytes(width: frame.width, height: frame.height, bytes: frame.imageBytes.buffer);
        
        // Create a blank canvas of max size
        final canvas = img.Image(width: maxWidth, height: maxHeight);
        
        // Draw frame onto center of canvas
        final dx = (maxWidth - frame.width) ~/ 2;
        final dy = (maxHeight - frame.height) ~/ 2;
        img.compositeImage(canvas, frameImg, dstX: dx, dstY: dy);

        encoder.addFrame(canvas, duration: duration100th);
      }

      final gifBytes = encoder.finish();
      if (gifBytes == null) throw Exception('Failed to encode GIF');

      await File(path).writeAsBytes(gifBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('GIF saved to $path')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting GIF: $e')),
        );
      }
    }
  }
}
