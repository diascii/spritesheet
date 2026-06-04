import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/sheet_config.dart';
import '../../domain/entities/sprite_frame.dart';
import '../bloc/sprite_sheet_bloc.dart';
import '../widgets/animation_preview.dart';
import '../widgets/asset_list_panel.dart';
import '../widgets/map_editor.dart';
import '../widgets/packed_preview.dart';
import '../widgets/pixel_editor.dart';
import '../widgets/settings_panel.dart';
import 'welcome_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _nameController = TextEditingController(text: 'spritesheet');
  int _maxTextureSize = 2048;
  int _framePadding = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    return Scaffold(
      appBar: isLandscape && !isTablet
          ? null // Hide app bar in landscape on phones for more space
          : AppBar(
              title: const Text('SpriteSheet Packer'),
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              actions: isTablet ? _buildAppBarActions(context) : null,
            ),
      body: BlocConsumer<AssetBloc, SpriteSheetState>(
        listener: (context, state) {
          if (state is FramesImported && _tabController.index == 0) {
            _tabController.animateTo(1); // Auto switch to Animate tab
          }
          if (state is SpriteSheetError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
          if (state is Exported) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Exported to ${state.pngPath}'),
                duration: const Duration(seconds: 4),
              ),
            );
          }
        },
        builder: (context, state) {
          if (isTablet) return _buildTabletLayout(state);
          return _buildPhoneLayout(state);
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tablet layout — split panel
  // ---------------------------------------------------------------------------
  Widget _buildTabletLayout(SpriteSheetState state) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final leftWidth = isLandscape ? 250.0 : 320.0; // Increased width slightly
    return Row(
      children: [
        SizedBox(
          width: leftWidth,
          child: _buildLeftPanel(state),
        ),
        const VerticalDivider(width: 1),
        Expanded(child: _buildRightPanel(state)),
      ],
    );
  }

  Widget _buildLeftPanel(SpriteSheetState state) {
    final body = switch (state) {
      SpriteSheetInitial _ => Padding(
          padding: const EdgeInsets.all(16),
          child: _buildImportPrompt(state),
        ),
      ImportingFrames() => const Center(child: CircularProgressIndicator()),
      FramesImported(:final frames) => Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              SettingsPanel(
                nameController: _nameController,
                maxTextureSize: _maxTextureSize,
                framePadding: _framePadding,
                onMaxTextureSizeChanged: (v) => setState(() => _maxTextureSize = v),
                onFramePaddingChanged: (v) => setState(() => _framePadding = v),
              ),
              const SizedBox(height: 8),
              AssetListPanel(frames: frames, scrollable: true),
            ],
          ),
        ),
      PackComplete(:final frames) => Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              SettingsPanel(
                nameController: _nameController,
                maxTextureSize: _maxTextureSize,
                framePadding: _framePadding,
                onMaxTextureSizeChanged: (v) => setState(() => _maxTextureSize = v),
                onFramePaddingChanged: (v) => setState(() => _framePadding = v),
              ),
              const SizedBox(height: 8),
              AssetListPanel(frames: frames, scrollable: true),
            ],
          ),
        ),
      _ => const SizedBox.shrink(),
    };
    return SingleChildScrollView(child: body);
  }

  Widget _buildRightPanel(SpriteSheetState state) {
    final frames = switch (state) {
      FramesImported(:final frames) => frames,
      PackComplete(:final frames) => frames,
      _ => <SpriteFrame>[],
    };

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: DefaultTabController(
        length: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TabBar(
              tabAlignment: TabAlignment.start,
              isScrollable: true,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
              tabs: const [
                Tab(text: 'Draw'),
                Tab(text: 'Map'),
                Tab(text: 'Animate'),
                Tab(text: 'Atlas'),
              ],
            ),
            Expanded(
              child: TabBarView(
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  const PixelEditor(),
                  const MapEditor(),
                  frames.isEmpty
                      ? const Center(child: Text('Import or draw frames first.'))
                      : AnimationPreview(frames: frames),
                  state is Packing
                      ? const Center(child: CircularProgressIndicator())
                      : state is PackComplete
                          ? PackedPreview(pngBytes: state.pngBytes, packResult: state.packResult)
                          : const Center(child: Text('Pack sprites to view the atlas preview.')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAppBarActions(BuildContext context) {
    // Read the current state directly from the bloc
    final state = context.watch<AssetBloc>().state;
    return [
      _buildSideButton(Icons.add_photo_alternate, 'Import', () {
        context.read<AssetBloc>().add(const ImportFramesEvent());
      }, state),

      _buildSideButton(Icons.grid_view, 'Pack', () {
        context.read<AssetBloc>().add(PackSpritesEvent(_buildConfig()));
      }, state, enabled: state is FramesImported || state is PackComplete),
      _buildSideButton(Icons.save_alt, 'Export', () => _export(context), state,
          enabled: state is PackComplete),
      if (state is FramesImported || state is PackComplete) 
        _buildSideButton(Icons.delete_outline, 'Clear', () {
          context.read<AssetBloc>().add(const ClearFramesEvent());
        }, state, outlined: true),
      const SizedBox(width: 8),
    ];
  }

  Widget _buildSideButton(IconData icon, String label, VoidCallback onPressed,
      SpriteSheetState state, {bool enabled = true, bool outlined = false}) {
    final isBusy =
        state is ImportingFrames || state is Packing || state is Exporting;
    final btn = outlined
        ? IconButton(
            onPressed: isBusy || !enabled ? null : onPressed,
            icon: Icon(icon),
            tooltip: label,
          )
        : IconButton(
            onPressed: isBusy || !enabled ? null : onPressed,
            icon: Icon(icon),
            tooltip: label,
            color: Theme.of(context).colorScheme.primary,
          );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: btn,
    );
  }

  // ---------------------------------------------------------------------------
  // Phone layout — vertical stack
  // ---------------------------------------------------------------------------
  Widget _buildPhoneLayout(SpriteSheetState state) {
    List<SpriteFrame> frames;
    if (state is FramesImported) {
      frames = state.frames;
    } else if (state is PackComplete) {
      frames = state.frames;
    } else {
      frames = [];
    }

    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
          tabs: [
            Tab(icon: const Icon(Icons.photo_library), text: isLandscape ? null : 'Assets', height: isLandscape ? 48 : null),
            Tab(icon: const Icon(Icons.brush), text: isLandscape ? null : 'Draw', height: isLandscape ? 48 : null),
            Tab(icon: const Icon(Icons.map), text: isLandscape ? null : 'Map', height: isLandscape ? 48 : null),
            Tab(icon: const Icon(Icons.animation), text: isLandscape ? null : 'Animate', height: isLandscape ? 48 : null),
            Tab(icon: const Icon(Icons.grid_on), text: isLandscape ? null : 'Atlas', height: isLandscape ? 48 : null),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              // 1. Assets Tab
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SettingsPanel(
                      nameController: _nameController,
                      maxTextureSize: _maxTextureSize,
                      framePadding: _framePadding,
                      onMaxTextureSizeChanged: (v) => setState(() => _maxTextureSize = v),
                      onFramePaddingChanged: (v) => setState(() => _framePadding = v),
                    ),
                    const SizedBox(height: 16),
                    AssetListPanel(frames: frames, scrollable: true), // FIXED: Must be true inside SingleChildScrollView
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton.icon(
                          onPressed: () {
                            context.read<AssetBloc>().add(const ImportFramesEvent());
                          },
                          icon: const Icon(Icons.add_photo_alternate),
                          label: const Text('Import'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const WelcomePage()),
                            );
                          },
                          icon: const Icon(Icons.home),
                          label: const Text('Home'),
                        ),
                        if (state is FramesImported || state is PackComplete) ...[
                          OutlinedButton.icon(
                            onPressed: () {
                              context.read<AssetBloc>().add(const ClearFramesEvent());
                            },
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Clear All'),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // 2. Draw Tab
              const PixelEditor(),
              // 3. Map Tab
              const MapEditor(),
              // 4. Animate Tab
              Padding(
                padding: const EdgeInsets.all(8),
                child: frames.isEmpty
                    ? const Center(child: Text('Import frames first to animate and paint hitboxes.'))
                    : AnimationPreview(frames: frames),
              ),
              // 4. Atlas Tab
              Padding(
                padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilledButton.icon(
                            onPressed: frames.isNotEmpty && state is! Packing
                                ? () => context.read<AssetBloc>().add(PackSpritesEvent(_buildConfig()))
                                : null,
                            icon: const Icon(Icons.grid_view),
                            label: const Text('Pack'),
                          ),
                          FilledButton.icon(
                            onPressed: state is PackComplete && state is! Exporting ? () => _export(context) : null,
                            icon: const Icon(Icons.save_alt),
                            label: const Text('Export'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: state is Packing
                            ? const Center(child: CircularProgressIndicator())
                            : state is PackComplete
                                ? PackedPreview(pngBytes: state.pngBytes, packResult: state.packResult)
                                : const Center(child: Text('Pack sprites to view the atlas preview.')),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
  }

  // ---------------------------------------------------------------------------
  // Shared widgets
  // ---------------------------------------------------------------------------
  Widget _buildImportPrompt(SpriteSheetState state) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Import PNG frames to begin',
              style: TextStyle(fontSize: 16)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => context
                .read<AssetBloc>()
                .add(const ImportFramesEvent()),
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('Import Frames'),
          ),
        ],
      ),
    );
  }





  SheetConfig _buildConfig() {
    return SheetConfig(
      sheetName:
          _nameController.text.isEmpty ? 'spritesheet' : _nameController.text,
      maxTextureSize: _maxTextureSize,
      framePadding: _framePadding,
    );
  }

  Future<void> _export(BuildContext context) async {
    if (kIsWeb) {
      // On web, bypass directory picking and just dispatch export
      if (!context.mounted) return;
      context.read<AssetBloc>().add(
            ExportSheetEvent(
              config: _buildConfig(),
              outputDirectory: '', // Ignored on web
            ),
          );
      return;
    }

    final dir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Choose export folder',
    );

    final outputDir = dir ??
        '${(await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory()).path}/SpriteSheetExports';

    await Directory(outputDir).create(recursive: true);

    if (!context.mounted) return;
    context.read<AssetBloc>().add(
          ExportSheetEvent(
            config: _buildConfig(),
            outputDirectory: outputDir,
          ),
        );
  }
}
