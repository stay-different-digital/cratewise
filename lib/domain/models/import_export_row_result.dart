sealed class ImportExportRowResult {
  const ImportExportRowResult({required this.rowIndex});

  final int rowIndex;
}

final class ValidRow extends ImportExportRowResult {
  const ValidRow({required super.rowIndex, required this.description});

  /// Human-readable description of the row (e.g. "Artist – Title").
  final String description;
}

final class SkippedRow extends ImportExportRowResult {
  const SkippedRow({required super.rowIndex, required this.reason});

  /// Safe, user-facing reason the row was skipped (e.g. "Already in collection").
  final String reason;
}

final class FailedRow extends ImportExportRowResult {
  const FailedRow({
    required super.rowIndex,
    required this.safeErrorMessage,
  });

  /// Safe, user-facing error message.
  /// Must never contain tokens, secrets, or stack traces.
  final String safeErrorMessage;
}
