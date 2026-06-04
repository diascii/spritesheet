import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'checkerboard.dart';

import '../bloc/sprite_sheet_bloc.dart';

class PixelEditor extends StatefulWidget {
  const PixelEditor({super.key});

  @override
  State<PixelEditor> createState() => _PixelEditorState();
}

class _PixelEditorState extends State<PixelEditor> {
  int _gridSize = 32;
  late List<List<Color>> _layers;
  int _activeLayerIndex = 0;
  bool _onionSkinEnabled = true;
  bool _showGrid = true;

  Color _currentColor = Colors.black;
  bool _isEraser = false;
  bool _isPanning = false;
  bool _isBucket = false;
  bool _isEyedropper = false;
  bool _isMarquee = false;

  Rect? _marqueeRect;
  Offset? _marqueeStart;
  List<Color>? _selectionBuffer;
  Offset _selectionOffset = Offset.zero;
  bool _isDraggingSelection = false;

  final List<List<List<Color>>> _undoStack = [];
  final List<List<List<Color>>> _redoStack = [];

  late List<Color> _palette;

  final List<Color> _defaultPalette = [
    Colors.black,
    Colors.white,
    Colors.grey,
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
    Colors.brown,
    Colors.cyan,
    Colors.pink,
  ];

  @override
  void initState() {
    super.initState();
    _palette = context.read<AssetBloc>().palette ?? List.from(_defaultPalette);
    _initPixels();
  }

  void _initPixels() {
    _layers = [List.filled(_gridSize * _gridSize, Colors.transparent)];
    _activeLayerIndex = 0;
  }

  void _clearCanvas() {
    _saveSnapshot();
    setState(() {
      _layers[_activeLayerIndex] = List.filled(_gridSize * _gridSize, Colors.transparent);
    });
  }

  void _saveSnapshot() {
    final snapshot = _layers.map((layer) => List<Color>.from(layer)).toList();
    _undoStack.add(snapshot);
    if (_undoStack.length > 30) _undoStack.removeAt(0);
    _redoStack.clear();
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    setState(() {
      _redoStack.add(_layers.map((layer) => List<Color>.from(layer)).toList());
      _layers = _undoStack.removeLast();
    });
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    setState(() {
      _undoStack.add(_layers.map((layer) => List<Color>.from(layer)).toList());
      _layers = _redoStack.removeLast();
    });
  }

  void _addBlankLayer() {
    _saveSnapshot();
    setState(() {
      _layers.insert(_activeLayerIndex + 1, List.filled(_gridSize * _gridSize, Colors.transparent));
      _activeLayerIndex++;
    });
  }

  void _duplicateLayer() {
    _saveSnapshot();
    setState(() {
      _layers.insert(_activeLayerIndex + 1, List.from(_layers[_activeLayerIndex]));
      _activeLayerIndex++;
    });
  }

  void _deleteLayer() {
    if (_layers.length <= 1) {
      _clearCanvas();
      return;
    }
    _saveSnapshot();
    setState(() {
      _layers.removeAt(_activeLayerIndex);
      if (_activeLayerIndex >= _layers.length) {
        _activeLayerIndex = _layers.length - 1;
      }
    });
  }

  void _resizeCanvas(int newSize) {
    setState(() {
      _gridSize = newSize;
      _initPixels();
    });
  }

  void _drawPixel(Offset localPosition, Size size, {bool isStart = false, bool isEnd = false}) {
    const rulerSize = 20.0;
    final drawArea = Size(size.width - rulerSize, size.height - rulerSize);
    
    final cellWidth = drawArea.width / _gridSize;
    final cellHeight = drawArea.height / _gridSize;

    final x = ((localPosition.dx - rulerSize) / cellWidth).floor();
    final y = ((localPosition.dy - rulerSize) / cellHeight).floor();

    if (_isMarquee) {
      if (isStart) {
        if (_marqueeRect != null && _marqueeRect!.contains(Offset(x.toDouble(), y.toDouble()))) {
          _isDraggingSelection = true;
          _marqueeStart = Offset(x.toDouble(), y.toDouble());
          if (_selectionBuffer == null) {
            _saveSnapshot();
            _selectionBuffer = List.filled((_marqueeRect!.width * _marqueeRect!.height).toInt(), Colors.transparent);
            for (int sy = 0; sy < _marqueeRect!.height; sy++) {
              for (int sx = 0; sx < _marqueeRect!.width; sx++) {
                final px = _marqueeRect!.left.toInt() + sx;
                final py = _marqueeRect!.top.toInt() + sy;
                if (px >= 0 && px < _gridSize && py >= 0 && py < _gridSize) {
                  _selectionBuffer![sy * _marqueeRect!.width.toInt() + sx] = _layers[_activeLayerIndex][py * _gridSize + px];
                  _layers[_activeLayerIndex][py * _gridSize + px] = Colors.transparent;
                }
              }
            }
          }
        } else {
          _commitSelection();
          _marqueeStart = Offset(x.toDouble(), y.toDouble());
          setState(() {
            _marqueeRect = Rect.fromLTRB(_marqueeStart!.dx, _marqueeStart!.dy, _marqueeStart!.dx + 1, _marqueeStart!.dy + 1);
          });
        }
      } else if (isEnd) {
        if (_isDraggingSelection && _marqueeRect != null) {
          setState(() {
            _marqueeRect = _marqueeRect!.shift(_selectionOffset);
            _selectionOffset = Offset.zero;
          });
        }
        _isDraggingSelection = false;
        _marqueeStart = null;
      } else if (_isDraggingSelection) {
        setState(() {
          final dx = x - _marqueeStart!.dx;
          final dy = y - _marqueeStart!.dy;
          _selectionOffset = Offset(dx.toDouble(), dy.toDouble());
        });
      } else if (_marqueeStart != null) {
        final endX = x.toDouble();
        final endY = y.toDouble();
        setState(() {
          _marqueeRect = Rect.fromLTRB(
            _marqueeStart!.dx < endX ? _marqueeStart!.dx : endX,
            _marqueeStart!.dy < endY ? _marqueeStart!.dy : endY,
            (_marqueeStart!.dx > endX ? _marqueeStart!.dx : endX) + 1,
            (_marqueeStart!.dy > endY ? _marqueeStart!.dy : endY) + 1,
          );
        });
      }
      return;
    }

    if (isStart) _commitSelection();

    if (x >= 0 && x < _gridSize && y >= 0 && y < _gridSize) {
      final index = y * _gridSize + x;
      
      if (_isEyedropper) {
        setState(() {
          _currentColor = _layers[_activeLayerIndex][index];
          _isEyedropper = false; // Auto-switch back to brush
        });
        return;
      }
      
      final newColor = _isEraser ? Colors.transparent : _currentColor;

      if (_isBucket) {
        final targetColor = _layers[_activeLayerIndex][index];
        if (targetColor == newColor) return;
        
        final queue = [index];
        final layer = _layers[_activeLayerIndex];
        
        setState(() {
          while (queue.isNotEmpty) {
            final curr = queue.removeLast();
            if (layer[curr] == targetColor) {
              layer[curr] = newColor;
              
              final currX = curr % _gridSize;
              final currY = curr ~/ _gridSize;
              
              if (currX > 0) queue.add(curr - 1);
              if (currX < _gridSize - 1) queue.add(curr + 1);
              if (currY > 0) queue.add(curr - _gridSize);
              if (currY < _gridSize - 1) queue.add(curr + _gridSize);
            }
          }
        });
        return;
      }

      if (_layers[_activeLayerIndex][index] != newColor) {
        setState(() {
          _layers[_activeLayerIndex][index] = newColor;
        });
      }
    }
  }

  void _commitSelection() {
    if (_selectionBuffer != null && _marqueeRect != null) {
      _saveSnapshot();
      setState(() {
        for (int sy = 0; sy < _marqueeRect!.height; sy++) {
          for (int sx = 0; sx < _marqueeRect!.width; sx++) {
            final px = (_marqueeRect!.left + _selectionOffset.dx).toInt() + sx;
            final py = (_marqueeRect!.top + _selectionOffset.dy).toInt() + sy;
            if (px >= 0 && px < _gridSize && py >= 0 && py < _gridSize) {
              final color = _selectionBuffer![sy * _marqueeRect!.width.toInt() + sx];
              if (color != Colors.transparent) {
                _layers[_activeLayerIndex][py * _gridSize + px] = color;
              }
            }
          }
        }
        _selectionBuffer = null;
        _selectionOffset = Offset.zero;
        _marqueeRect = null;
      });
    } else {
      setState(() {
        _marqueeRect = null;
      });
    }
  }

  Future<void> _addToProject() async {
    final scale = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Export Size'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Original (${_gridSize}x$_gridSize)'),
                onTap: () => Navigator.pop(context, 1),
              ),
              ListTile(
                title: Text('${_gridSize * 4}x${_gridSize * 4} (4x)'),
                onTap: () => Navigator.pop(context, 4),
              ),
              ListTile(
                title: Text('${_gridSize * 8}x${_gridSize * 8} (8x)'),
                onTap: () => Navigator.pop(context, 8),
              ),
              ListTile(
                title: Text('${_gridSize * 16}x${_gridSize * 16} (16x)'),
                onTap: () => Navigator.pop(context, 16),
              ),
            ],
          ),
        );
      },
    );

    if (scale == null) return; // User cancelled

    final targetSize = _gridSize * scale;
    
    // Add each layer sequentially
    for (int i = 0; i < _layers.length; i++) {
      final layer = _layers[i];
      final bytes = Uint8List(targetSize * targetSize * 4);

      for (int y = 0; y < targetSize; y++) {
        for (int x = 0; x < targetSize; x++) {
          final sourceX = x ~/ scale;
          final sourceY = y ~/ scale;
          final color = layer[sourceY * _gridSize + sourceX];

          final byteIndex = (y * targetSize + x) * 4;
          bytes[byteIndex] = (color.r * 255.0).round().clamp(0, 255);
          bytes[byteIndex + 1] = (color.g * 255.0).round().clamp(0, 255);
          bytes[byteIndex + 2] = (color.b * 255.0).round().clamp(0, 255);
          bytes[byteIndex + 3] = (color.a * 255.0).round().clamp(0, 255);
        }
      }

      if (!mounted) return;
      context.read<AssetBloc>().add(AddDrawnFrameEvent(
            rgbaBytes: bytes,
            width: targetSize,
            height: targetSize,
          ));
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added ${_layers.length} frame(s) to project!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildToolbar(),
        const VerticalDivider(width: 1),
        Expanded(
          child: ClipRect(
            child: InteractiveViewer(
              panEnabled: _isPanning,
              scaleEnabled: _isPanning,
              minScale: 0.5,
              maxScale: 20.0,
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
                      return GestureDetector(
                        onPanStart: _isPanning ? null : (details) {
                          if (!_isMarquee) _saveSnapshot();
                          _drawPixel(details.localPosition, canvasSize, isStart: true);
                        },
                        onPanUpdate: _isPanning ? null : (details) => _drawPixel(details.localPosition, canvasSize),
                        onPanEnd: _isPanning ? null : (details) => _drawPixel(Offset.zero, canvasSize, isEnd: true),
                        onTapDown: _isPanning ? null : (details) {
                          if (!_isMarquee) _saveSnapshot();
                          _drawPixel(details.localPosition, canvasSize, isStart: true);
                          _drawPixel(details.localPosition, canvasSize, isEnd: true);
                        },
                        child: CustomPaint(
                          size: canvasSize,
                          painter: const CheckerboardPainter(
                            color1: Color(0xFF2A2A2A),
                            color2: Color(0xFF1E1E1E),
                            squareSize: 16.0,
                          ),
                          foregroundPainter: _PixelGridPainter(
                            layers: _layers,
                            activeLayerIndex: _activeLayerIndex,
                            onionSkinEnabled: _onionSkinEnabled,
                            showGrid: _showGrid,
                            gridSize: _gridSize,
                            marqueeRect: _marqueeRect,
                            selectionBuffer: _selectionBuffer,
                            selectionOffset: _selectionOffset,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      width: 64,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 8),
            IconButton(
              icon: const Icon(Icons.undo),
              onPressed: _undoStack.isNotEmpty ? _undo : null,
              tooltip: 'Undo',
            ),
            IconButton(
              icon: const Icon(Icons.redo),
              onPressed: _redoStack.isNotEmpty ? _redo : null,
              tooltip: 'Redo',
            ),
            const Divider(),
            // Color Picker Button
            GestureDetector(
              onTap: _showColorPicker,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _currentColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            IconButton(
              icon: const Icon(Icons.pan_tool),
              color: _isPanning ? Theme.of(context).colorScheme.primary : null,
              onPressed: () => setState(() {
                if (_isMarquee) _commitSelection();
                _isPanning = true;
                _isEraser = false;
                _isBucket = false;
                _isEyedropper = false;
                _isMarquee = false;
              }),
              tooltip: 'Pan / Zoom',
            ),
            IconButton(
              icon: const Icon(Icons.brush),
              color: (!_isEraser && !_isPanning && !_isBucket && !_isEyedropper && !_isMarquee) ? Theme.of(context).colorScheme.primary : null,
              onPressed: () => setState(() {
                if (_isMarquee) _commitSelection();
                _isEraser = false;
                _isPanning = false;
                _isBucket = false;
                _isEyedropper = false;
                _isMarquee = false;
              }),
              tooltip: 'Brush',
            ),
            IconButton(
              icon: const Icon(Icons.format_paint),
              color: _isBucket ? Theme.of(context).colorScheme.primary : null,
              onPressed: () => setState(() {
                if (_isMarquee) _commitSelection();
                _isBucket = true;
                _isEraser = false;
                _isPanning = false;
                _isEyedropper = false;
                _isMarquee = false;
              }),
              tooltip: 'Fill Bucket',
            ),
            IconButton(
              icon: const Icon(Icons.select_all),
              color: _isMarquee ? Theme.of(context).colorScheme.primary : null,
              onPressed: () => setState(() {
                _isMarquee = true;
                _isPanning = false;
                _isEraser = false;
                _isBucket = false;
                _isEyedropper = false;
              }),
              tooltip: 'Select & Move',
            ),
            IconButton(
              icon: const Icon(Icons.colorize),
              color: _isEyedropper ? Theme.of(context).colorScheme.primary : null,
              onPressed: () => setState(() {
                if (_isMarquee) _commitSelection();
                _isEyedropper = true;
                _isMarquee = false;
                _isBucket = false;
                _isEraser = false;
                _isPanning = false;
              }),
              tooltip: 'Eyedropper',
            ),
            IconButton(
              icon: const Icon(Icons.layers_clear),
              color: _isEraser ? Theme.of(context).colorScheme.primary : null,
              onPressed: () => setState(() {
                if (_isMarquee) _commitSelection();
                _isEraser = true;
                _isMarquee = false;
                _isPanning = false;
                _isBucket = false;
                _isEyedropper = false;
              }),
              tooltip: 'Eraser',
            ),
            const Divider(),
            IconButton(
              icon: const Icon(Icons.navigate_before),
              onPressed: _activeLayerIndex > 0 ? () => setState(() => _activeLayerIndex--) : null,
              tooltip: 'Prev Frame',
            ),
            Text('${_activeLayerIndex + 1}/${_layers.length}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.navigate_next),
              onPressed: _activeLayerIndex < _layers.length - 1 ? () => setState(() => _activeLayerIndex++) : null,
              tooltip: 'Next Frame',
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addBlankLayer,
              tooltip: 'New Frame',
            ),
            IconButton(
              icon: const Icon(Icons.control_point_duplicate),
              onPressed: _duplicateLayer,
              tooltip: 'Dup Frame',
            ),
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: _deleteLayer,
              tooltip: 'Del Frame',
            ),
            const Divider(),
            IconButton(
              icon: const Icon(Icons.animation),
              color: _onionSkinEnabled ? Theme.of(context).colorScheme.primary : null,
              onPressed: () => setState(() => _onionSkinEnabled = !_onionSkinEnabled),
              tooltip: 'Onion Skin',
            ),
            IconButton(
              icon: Icon(_showGrid ? Icons.grid_on : Icons.grid_off),
              color: _showGrid ? Theme.of(context).colorScheme.primary : null,
              onPressed: () => setState(() => _showGrid = !_showGrid),
              tooltip: 'Grid',
            ),
            const Divider(),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearCanvas,
              tooltip: 'Clear Canvas',
            ),
            PopupMenuButton<int>(
              icon: const Icon(Icons.aspect_ratio),
              tooltip: 'Resize Canvas',
              onSelected: (v) {
                if (v != _gridSize) _resizeCanvas(v);
              },
              itemBuilder: (context) => [16, 32, 64].map((size) {
                return PopupMenuItem(
                  value: size,
                  child: Text('${size}x$size'),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            FloatingActionButton.small(
              onPressed: _addToProject,
              tooltip: 'Add to Project',
              child: const Icon(Icons.add_photo_alternate),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showColorPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ..._palette.map((color) {
                final isSelected = _currentColor == color;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentColor = color;
                      _isEraser = false;
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
                        width: isSelected ? 3 : 1,
                      ),
                    ),
                  ),
                );
              }),
              GestureDetector(
                onTap: () async {
                  Navigator.pop(context);
                  final ctrl = TextEditingController(text: '#');
                  final hex = await showDialog<String>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('Add Hex Color'),
                      content: TextField(
                        controller: ctrl,
                        decoration: const InputDecoration(hintText: '#RRGGBB'),
                        autofocus: true,
                        onSubmitted: (v) => Navigator.pop(c, v),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
                        FilledButton(onPressed: () => Navigator.pop(c, ctrl.text), child: const Text('Add')),
                      ],
                    ),
                  );
                  if (!context.mounted) return;
                  if (hex != null && hex.isNotEmpty) {
                    try {
                      var hexString = hex.toUpperCase().replaceAll('#', '');
                      if (hexString.length == 6) {
                        hexString = 'FF$hexString';
                      }
                      final color = Color(int.parse(hexString, radix: 16));
                      setState(() {
                        _palette.add(color);
                        _currentColor = color;
                        _isEraser = false;
                      });
                      if (mounted) {
                        context.read<AssetBloc>().palette = _palette;
                      }
                    } catch (_) {}
                  }
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey, width: 2),
                  ),
                  child: const Icon(Icons.add, color: Colors.grey),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

}

class _PixelGridPainter extends CustomPainter {
  final List<List<Color>> layers;
  final int activeLayerIndex;
  final bool onionSkinEnabled;
  final bool showGrid;
  final int gridSize;
  final Rect? marqueeRect;
  final List<Color>? selectionBuffer;
  final Offset selectionOffset;

  _PixelGridPainter({
    required this.layers,
    required this.activeLayerIndex,
    required this.onionSkinEnabled,
    required this.showGrid,
    required this.gridSize,
    this.marqueeRect,
    this.selectionBuffer,
    this.selectionOffset = Offset.zero,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Reserve top and left margins for the ruler
    const rulerSize = 20.0;
    final drawArea = Rect.fromLTWH(rulerSize, rulerSize, size.width - rulerSize, size.height - rulerSize);
    
    final cellWidth = drawArea.width / gridSize;
    final cellHeight = drawArea.height / gridSize;

    // Draw Ruler Background
    final rulerBgPaint = Paint()..color = const Color(0xFFEEEEEE);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, rulerSize), rulerBgPaint); // Top
    canvas.drawRect(Rect.fromLTWH(0, 0, rulerSize, size.height), rulerBgPaint); // Left

    // Draw Ruler Text (every 4 pixels for better visibility, or 8 depending on grid)
    final step = gridSize >= 64 ? 8 : 4;
    for (int i = 0; i <= gridSize; i += step) {
      final textSpan = TextSpan(
        text: '$i',
        style: const TextStyle(color: Colors.black54, fontSize: 8),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      
      // Top Ruler Text
      if (i < gridSize) {
        textPainter.paint(canvas, Offset(rulerSize + (i * cellWidth) + 2, 2));
      }
      
      // Left Ruler Text
      if (i < gridSize) {
        textPainter.paint(canvas, Offset(2, rulerSize + (i * cellHeight) + 2));
      }
    }

    // Save canvas state and clip to drawing area
    canvas.save();
    canvas.clipRect(drawArea);
    canvas.translate(rulerSize, rulerSize);

    // Draw checkerboard background
    final bgPaint1 = Paint()..color = const Color(0xFFE0E0E0);
    final bgPaint2 = Paint()..color = const Color(0xFFBDBDBD);
    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        final rect = Rect.fromLTWH(x * cellWidth, y * cellHeight, cellWidth, cellHeight);
        canvas.drawRect(rect, (x + y) % 2 == 0 ? bgPaint1 : bgPaint2);
      }
    }

    // Draw Onion Skin (previous layer)
    if (onionSkinEnabled && activeLayerIndex > 0) {
      final prevLayer = layers[activeLayerIndex - 1];
      for (int y = 0; y < gridSize; y++) {
        for (int x = 0; x < gridSize; x++) {
          final index = y * gridSize + x;
          final color = prevLayer[index];
          if (color != Colors.transparent) {
            final paint = Paint()..color = color.withValues(alpha: 0.3);
            final rect = Rect.fromLTWH(x * cellWidth, y * cellHeight, cellWidth, cellHeight);
            canvas.drawRect(rect, paint);
          }
        }
      }
    }

    // Draw Active Layer
    final activeLayer = layers[activeLayerIndex];
    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        final index = y * gridSize + x;
        final color = activeLayer[index];
        if (color != Colors.transparent) {
          final paint = Paint()..color = color;
          final rect = Rect.fromLTWH(x * cellWidth, y * cellHeight, cellWidth, cellHeight);
          canvas.drawRect(rect, paint);
        }
      }
    }

    // Draw Selection Buffer
    if (selectionBuffer != null && marqueeRect != null) {
      for (int sy = 0; sy < marqueeRect!.height; sy++) {
        for (int sx = 0; sx < marqueeRect!.width; sx++) {
          final color = selectionBuffer![sy * marqueeRect!.width.toInt() + sx];
          if (color != Colors.transparent) {
            final paint = Paint()..color = color;
            final px = marqueeRect!.left + selectionOffset.dx + sx;
            final py = marqueeRect!.top + selectionOffset.dy + sy;
            final rect = Rect.fromLTWH(px * cellWidth, py * cellHeight, cellWidth, cellHeight);
            canvas.drawRect(rect, paint);
          }
        }
      }
    }

    // Draw Marquee Border
    if (marqueeRect != null) {
      final borderPaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      final px = marqueeRect!.left + selectionOffset.dx;
      final py = marqueeRect!.top + selectionOffset.dy;
      final rect = Rect.fromLTWH(px * cellWidth, py * cellHeight, marqueeRect!.width * cellWidth, marqueeRect!.height * cellHeight);
      canvas.drawRect(rect, borderPaint);
    }

    // Draw grid lines
    if (showGrid) {
      final gridPaint = Paint()
        ..color = Colors.black12
        ..strokeWidth = 1;
      for (int i = 0; i <= gridSize; i++) {
        canvas.drawLine(Offset(0, i * cellHeight), Offset(drawArea.width, i * cellHeight), gridPaint);
        canvas.drawLine(Offset(i * cellWidth, 0), Offset(i * cellWidth, drawArea.height), gridPaint);
      }
    }

    // Restore canvas state (removes clip and translation)
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PixelGridPainter oldDelegate) {
    return oldDelegate.layers != layers ||
           oldDelegate.activeLayerIndex != activeLayerIndex ||
           oldDelegate.onionSkinEnabled != onionSkinEnabled ||
           oldDelegate.gridSize != gridSize ||
           oldDelegate.marqueeRect != marqueeRect ||
           oldDelegate.selectionBuffer != selectionBuffer ||
           oldDelegate.selectionOffset != selectionOffset;
  }
}
