/// What collection and wishlist CSV exports have in common, so one preview
/// screen serves both (US-130).
abstract interface class CsvExportPreview {
  List<String> get headers;
  List<List<String>> get sampleRows;
  int get rowCount;
}

abstract interface class CsvExportDone {
  int get rowCount;
  String get filename;
  String get filePath;
}
