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
    // file_picker 13: single-file picker; data is read on demand.
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    final content = utf8.decode(bytes, allowMalformed: true);
    return CsvPickedFile(filename: file.name, content: content);
  }
}
