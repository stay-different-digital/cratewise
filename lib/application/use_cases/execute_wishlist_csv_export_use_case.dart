import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/csv_wishlist_export_preview.dart';
import '../../domain/models/import_export_job.dart';
import '../../domain/models/import_export_job_type.dart';
import '../../domain/models/import_export_status.dart';
import '../../domain/repositories/import_export_job_repository.dart';
import '../../infrastructure/csv/csv_file_writer.dart';
import '../../infrastructure/csv/wishlist_csv_mapper.dart';

sealed class ExecuteWishlistCsvExportResult {
  const ExecuteWishlistCsvExportResult();
}

class ExecuteWishlistCsvExportCompleted
    extends ExecuteWishlistCsvExportResult {
  const ExecuteWishlistCsvExportCompleted({
    required this.jobId,
    required this.rowCount,
    required this.filename,
  });

  final String jobId;
  final int rowCount;
  final String filename;
}

class ExecuteWishlistCsvExportFailed extends ExecuteWishlistCsvExportResult {
  const ExecuteWishlistCsvExportFailed(this.safeMessage);

  final String safeMessage;
}

class ExecuteWishlistCsvExportUseCase {
  ExecuteWishlistCsvExportUseCase({
    required this._jobRepository,
    required this._fileWriter,
    this._mapper = const WishlistCsvMapper(),
    Future<void> Function(String filePath)? onShare,
    String Function()? idGenerator,
  })  : _onShare = onShare ?? _defaultShare,
        _idGenerator = idGenerator ?? _newUuid;

  static String _newUuid() => const Uuid().v4();

  static Future<void> _defaultShare(String filePath) async {
    await Share.shareXFiles([XFile(filePath, mimeType: 'text/csv')]);
  }

  final ImportExportJobRepository _jobRepository;
  final CsvFileWriter _fileWriter;
  final WishlistCsvMapper _mapper;
  final Future<void> Function(String filePath) _onShare;
  final String Function() _idGenerator;

  Future<ExecuteWishlistCsvExportResult> execute(
    CsvWishlistExportPreview preview,
  ) async {
    final jobId = _idGenerator();
    final now = DateTime.now();
    final filename = 'wishlist_export_${now.millisecondsSinceEpoch}.csv';

    final job = ImportExportJob(
      id: jobId,
      jobType: ImportExportJobType.csvWishlistExport,
      source: 'Local wishlist',
      target: 'CSV file',
      status: ImportExportStatus.running,
      totalItems: preview.rowCount,
      createdAt: now,
      updatedAt: now,
    );

    try {
      await _jobRepository.add(job);

      final rows = preview.items.map(_mapper.toRow).toList();
      final filePath = await _fileWriter.write(
        filename: filename,
        headers: preview.headers,
        rows: rows,
      );

      await _onShare(filePath);

      await _jobRepository.update(
        job.copyWith(
          status: ImportExportStatus.completed,
          validItems: preview.rowCount,
          updatedAt: DateTime.now(),
        ),
      );

      return ExecuteWishlistCsvExportCompleted(
        jobId: jobId,
        rowCount: preview.rowCount,
        filename: filename,
      );
    } catch (_) {
      try {
        await _jobRepository.update(
          job.copyWith(
            status: ImportExportStatus.failed,
            safeErrorMessage: 'CSV export could not be completed',
            updatedAt: DateTime.now(),
          ),
        );
      } catch (_) {}
      return const ExecuteWishlistCsvExportFailed(
        'CSV export could not be completed',
      );
    }
  }
}
