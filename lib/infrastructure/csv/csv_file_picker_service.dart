import 'dart:convert';

import 'package:file_picker/file_picker.dart';

class CsvPickedFile {
  const CsvPickedFile({required this.filename, required this.content});
  final String filename;
  final String content;
}

class CsvFilePickerService {
  const CsvFilePickerService();

  Future<CsvPickedFile?> pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result == null) return null;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return null;
    final content = utf8.decode(bytes, allowMalformed: true);
    return CsvPickedFile(filename: file.name, content: content);
  }
}
