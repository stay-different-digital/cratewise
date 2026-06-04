import 'import_export_job_type.dart';
import 'import_export_status.dart';

class ImportExportJob {
  const ImportExportJob({
    required this.id,
    required this.jobType,
    required this.source,
    required this.target,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.totalItems,
    this.validItems,
    this.skippedItems,
    this.failedItems,
    this.safeErrorMessage,
  });

  final String id;
  final ImportExportJobType jobType;

  /// Human-readable source identifier (e.g. "Discogs" or a filename).
  /// Must never contain tokens or secrets.
  final String source;

  /// Human-readable target identifier (e.g. "Local collection" or a filename).
  /// Must never contain tokens or secrets.
  final String target;

  final ImportExportStatus status;
  final int? totalItems;
  final int? validItems;
  final int? skippedItems;
  final int? failedItems;

  /// Safe, user-facing error message.
  /// Must never contain tokens, secrets, or stack traces.
  final String? safeErrorMessage;

  final DateTime createdAt;
  final DateTime updatedAt;

  ImportExportJob copyWith({
    String? id,
    ImportExportJobType? jobType,
    String? source,
    String? target,
    ImportExportStatus? status,
    int? totalItems,
    int? validItems,
    int? skippedItems,
    int? failedItems,
    String? safeErrorMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearSafeErrorMessage = false,
    bool clearTotalItems = false,
    bool clearValidItems = false,
    bool clearSkippedItems = false,
    bool clearFailedItems = false,
  }) {
    return ImportExportJob(
      id: id ?? this.id,
      jobType: jobType ?? this.jobType,
      source: source ?? this.source,
      target: target ?? this.target,
      status: status ?? this.status,
      totalItems: clearTotalItems ? null : (totalItems ?? this.totalItems),
      validItems: clearValidItems ? null : (validItems ?? this.validItems),
      skippedItems: clearSkippedItems
          ? null
          : (skippedItems ?? this.skippedItems),
      failedItems: clearFailedItems ? null : (failedItems ?? this.failedItems),
      safeErrorMessage: clearSafeErrorMessage
          ? null
          : (safeErrorMessage ?? this.safeErrorMessage),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
