import 'package:uuid/uuid.dart';

import '../../domain/models/collection_item.dart';
import '../../domain/models/release_detail.dart';
import '../../domain/models/sync_status.dart';
import '../../domain/repositories/collection_repository.dart';

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

class AddToCollectionUseCase {
  AddToCollectionUseCase(
    this._repository, {
    String Function()? idGenerator,
  }) : _idGenerator = idGenerator ?? _newUuid;

  static String _newUuid() => const Uuid().v4();

  final CollectionRepository _repository;
  final String Function() _idGenerator;

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
    await _repository.add(item);
    return AddToCollectionSuccess(item);
  }
}
