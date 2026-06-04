import 'package:file_picker/file_picker.dart';

/// Abstract repository for file picking operations.
abstract class FilePickerRepository {
  /// Prompts the user to pick image files and returns their paths.
  Future<List<PlatformFile>> pickImageFiles();
}
