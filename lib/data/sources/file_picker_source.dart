import 'package:file_picker/file_picker.dart';

import '../../domain/repositories/file_picker_repository.dart';

class FilePickerSource implements FilePickerRepository {
  @override
  Future<List<PlatformFile>> pickImageFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png'],
      allowMultiple: true,
      withData: true,
    );

    if (result == null) return [];

    return result.files;
  }
}
