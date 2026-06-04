import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'data/repositories/image_repository_impl.dart';
import 'data/sources/file_picker_source.dart';
import 'data/sources/hash_util.dart';
import 'data/sources/image_decoder.dart';
import 'domain/usecases/export_sheet.dart';
import 'domain/usecases/import_frames.dart';
import 'domain/usecases/pack_sprites.dart';
import 'domain/usecases/stitch_sheet.dart';
import 'domain/usecases/trim_alpha.dart';
import 'presentation/bloc/sprite_sheet_bloc.dart';
import 'presentation/bloc/project_cubit.dart';
import 'presentation/pages/welcome_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final imageDecoder = ImageDecoder();
    final hashUtil = HashUtil();
    final imageRepository = ImageRepositoryImpl(
      imageDecoder: imageDecoder,
      hashUtil: hashUtil,
    );

    final filePicker = FilePickerSource();

    final trimAlpha = TrimAlpha();
    final stitchSheet = StitchSheet();
    final packSprites = PackSprites(
      trimAlpha: trimAlpha,
      stitchSheet: stitchSheet,
    );
    final importFrames = ImportFrames(
      filePicker: filePicker,
      repository: imageRepository,
    );
    final exportSheet = ExportSheet(
      repository: imageRepository,
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AssetBloc(
            importFrames: importFrames,
            packSprites: packSprites,
            exportSheet: exportSheet,
          ),
        ),
        BlocProvider(create: (_) => ProjectCubit()),
      ],
      child: MaterialApp(
        title: 'SpriteSheet Packer',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: const WelcomePage(),
      ),
    );
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}
