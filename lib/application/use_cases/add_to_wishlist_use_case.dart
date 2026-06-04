import 'package:uuid/uuid.dart';

import '../../domain/models/release_detail.dart';
import '../../domain/models/sync_status.dart';
import '../../domain/models/wishlist_item.dart';
import '../../domain/repositories/wishlist_repository.dart';

sealed class AddToWishlistResult {
  const AddToWishlistResult();
}

class AddToWishlistSuccess extends AddToWishlistResult {
  AddToWishlistSuccess(this.item);
  final WishlistItem item;
}

class AddToWishlistDuplicate extends AddToWishlistResult {
  const AddToWishlistDuplicate();
}

class AddToWishlistUseCase {
  AddToWishlistUseCase(this._repository, {String Function()? idGenerator})
    : _idGenerator = idGenerator ?? _newUuid;

  static String _newUuid() => const Uuid().v4();

  final WishlistRepository _repository;
  final String Function() _idGenerator;

  Future<AddToWishlistResult> execute(ReleaseDetail release) async {
    if (await _repository.containsRelease(release.id)) {
      return const AddToWishlistDuplicate();
    }
    final now = DateTime.now();
    final item = WishlistItem(
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
      priority: WishlistPriority.medium,
      syncStatus: SyncStatus.localOnly,
      createdAt: now,
      updatedAt: now,
    );
    await _repository.add(item);
    return AddToWishlistSuccess(item);
  }
}
