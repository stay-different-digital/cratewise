import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../domain/models/collection_item.dart';
import '../../domain/models/release_detail.dart';
import '../../domain/models/retry_action.dart';
import '../../domain/models/sync_status.dart';
import '../../domain/repositories/collection_repository.dart';
import '../../domain/repositories/retry_action_repository.dart';

sealed class AddToCollectionResult {
  const AddToCollectionResult();
}

class AddToCollectionSuccess extends AddToCollectionResult {
  AddToCollectionSuccess(this.item);
  final CollectionItem item;
}

class AddToCollectionDuplicate extends AddToCollectionResult {
  const AddToCollectionDuplicate();
}

/// The repository write failed; a retry action has been queued.
class AddToCollectionStorageError extends AddToCollectionResult {
  const AddToCollectionStorageError();
}

class AddToCollectionUseCase {
  AddToCollectionUseCase(
    this._repository, {
    String Function()? idGenerator,
    this._retryRepository,
  }) : _idGenerator = idGenerator ?? _newUuid;

  static String _newUuid() => const Uuid().v4();

  final CollectionRepository _repository;
  final String Function() _idGenerator;
  final RetryActionRepository? _retryRepository;

  Future<AddToCollectionResult> execute(ReleaseDetail release) async {
    if (await _repository.containsRelease(release.id)) {
      return const AddToCollectionDuplicate();
    }
    final now = DateTime.now();
    final item = CollectionItem(
      id: _idGenerator(),
      discogsReleaseId: release.id,
      artist: release.artist,
      title: release.title,
      label: release.label.isEmpty ? null : release.label,
      catno: release.catno.isEmpty ? null : release.catno,
      format: release.format.isEmpty ? null : release.format,
      country: release.country.isEmpty ? null : release.country,
      year: release.year,
      coverUrl: release.coverUrl,
      mediaCondition: RecordCondition.veryGood,
      sleeveCondition: RecordCondition.veryGood,
      tags: const [],
      syncStatus: SyncStatus.localOnly,
      createdAt: now,
      updatedAt: now,
    );
    try {
      await _repository.add(item);
      return AddToCollectionSuccess(item);
    } catch (_) {
      await _recordRetry(item);
      return const AddToCollectionStorageError();
    }
  }

  Future<void> _recordRetry(CollectionItem item) async {
    if (_retryRepository == null) return;
    try {
      final entityId = '${item.discogsReleaseId}';
      final pending = await _retryRepository.getPending();
      final hasDuplicate = pending.any(
        (a) =>
            a.entityId == entityId &&
            a.actionType == RetryActionType.addCollectionItem,
      );
      if (hasDuplicate) return;
      await _retryRepository.add(
        RetryAction(
          id: const Uuid().v4(),
          actionType: RetryActionType.addCollectionItem,
          entityType: RetryActionEntityType.collectionItem,
          entityId: entityId,
          payload: jsonEncode(item.toJson()),
          safeErrorMessage: "Could not save '${item.title}' to collection.",
          createdAt: DateTime.now(),
          attemptCount: 0,
          status: RetryActionStatus.pending,
        ),
      );
    } catch (_) {
      // recording failure must never crash the main flow
    }
  }
}
