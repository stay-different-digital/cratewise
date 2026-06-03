import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/csv_collection_export_preview.dart';
import '../../domain/models/import_export_job.dart';
import '../../domain/models/import_export_job_type.dart';
import '../../domain/models/import_export_status.dart';
import '../../domain/repositories/import_export_job_repository.dart';
import '../../infrastructure/csv/collection_csv_mapper.dart';
import '../../infrastructure/csv/csv_file_writer.dart';

sealed class ExecuteCollectionCsvExportResult {
  const ExecuteCollectionCsvExportResult();
}

class ExecuteCollectionCsvExportCompleted
    extends ExecuteCollectionCsvExportResult {
  const ExecuteCollectionCsvExportCompleted({
    required this.jobId,
    required this.rowCount,
    required this.filename,
  });

  final String jobId;
  final int rowCount;
  final String filename;
}

class ExecuteCollectionCsvExportFailed
    extends ExecuteCollectionCsvExportResult {
  const ExecuteCollectionCsvExportFailed(this.safeMessage);

  final String safeMessage;
}

class ExecuteCollectionCsvExportUseCase {
  ExecuteCollectionCsvExportUseCase({
    required this._jobRepository,
    required this._fileWriter,
    this._mapper = const CollectionCsvMapper(),
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
  final CollectionCsvMapper _mapper;
  final Future<void> Function(String filePath) _onShare;
  final String Function() _idGenerator;

  Future<ExecuteCollectionCsvExportResult> execute(
    CsvCollectionExportPreview preview,
  ) async {
    final jobId = _idGenerator();
    final now = DateTime.now();
    final filename =
        'collection_export_${now.millisecondsSinceEpoch}.csv';

    final job = ImportExportJob(
      id: jobId,
      jobType: ImportExportJobType.csvCollectionExport,
      source: 'Local collection',
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

      return ExecuteCollectionCsvExportCompleted(
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
      return const ExecuteCollectionCsvExportFailed(
        'CSV export could not be completed',
      );
    }
  }
}
