import '../entities/sprite_frame.dart';
import '../repositories/image_repository.dart';
import '../repositories/file_picker_repository.dart';

class ImportFrames {
  final FilePickerRepository _filePicker;
  final ImageRepository _repository;

  ImportFrames({
    required FilePickerRepository filePicker,
    required ImageRepository repository,
  })  : _filePicker = filePicker,
        _repository = repository;

  Future<List<SpriteFrame>> execute() async {
    final paths = await _filePicker.pickImageFiles();
    if (paths.isEmpty) return [];

    return _repository.importFrames(paths);
  }
}
