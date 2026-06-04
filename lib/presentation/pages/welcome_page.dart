import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/sprite_sheet_bloc.dart';
import '../bloc/project_cubit.dart';
import '../../domain/entities/game_template.dart';
import '../../domain/usecases/load_project.dart';
import 'home_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AssetBloc, SpriteSheetState>(
        listener: (context, state) {
          if (state is FramesImported || state is PackComplete) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          } else if (state is SpriteSheetError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.animation, size: 80, color: Colors.deepPurpleAccent),
                const SizedBox(height: 24),
                Text(
                  'SpriteSheet Packer',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Create, animate, and pack sprite sheets with ease.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                FilledButton.icon(
                  onPressed: () => _showTemplatePicker(context),
                  icon: const Icon(Icons.add),
                  label: const Text('New Project'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(
                      dialogTitle: 'Load Project',
                      type: FileType.any,
                      withData: true,
                    );
                    if (!context.mounted) return;
                    if (result != null && result.files.isNotEmpty) {
                      final file = result.files.single;
                      String jsonString;
                      if (kIsWeb) {
                        jsonString = utf8.decode(file.bytes!);
                      } else {
                        jsonString = await File(file.path!).readAsString();
                      }
                      try {
                        final loadProject = LoadProject();
                        final result = await loadProject.execute(jsonString);
                        if (!context.mounted) return;
                        context.read<AssetBloc>().add(LoadProjectDataEvent(
                          frames: result.frames,
                          annotations: result.annotations,
                          palette: result.palette,
                        ));
                        context.read<ProjectCubit>().loadProjectData(
                          projectName: 'Loaded Project',
                          template: result.template,
                          scenes: result.scenes,
                          activeSceneId: result.scenes.isNotEmpty ? result.scenes.first.id : null,
                          globalVariables: {},
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error loading project: $e')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Open Project'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTemplatePicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Choose Game Template'),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTemplateOption(ctx, GameTemplate.rpg, '🗺️  RPG', 'Pokemon, Earthbound'),
              _buildTemplateOption(ctx, GameTemplate.action, '⚔️  Action', 'Zelda, Undertale'),
              _buildTemplateOption(ctx, GameTemplate.shooter, '🔫  Shooter', 'Hotline Miami'),
              _buildTemplateOption(ctx, GameTemplate.fps, '👁️  FPS', 'DOOM, Wolfenstein'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateOption(BuildContext context, GameTemplate template, String title, String subtitle) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: () {
        context.read<ProjectCubit>().loadProjectData(
          projectName: 'New Project',
          template: template,
          scenes: [],
          activeSceneId: null,
          globalVariables: {},
        );
        context.read<AssetBloc>().add(const ClearFramesEvent());
        Navigator.of(context).pop(); // Close dialog
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      },
    );
  }
}
