sealed class CheckCollectionExportCapabilityResult {
  const CheckCollectionExportCapabilityResult();
}

class CollectionExportSupported extends CheckCollectionExportCapabilityResult {
  const CollectionExportSupported();
}

class CollectionExportNotSupported
    extends CheckCollectionExportCapabilityResult {
  const CollectionExportNotSupported(this.reason);

  final String reason;
}

/// Checks whether the app can export local collection items to Discogs.
///
/// The Discogs API client supports the required write endpoint
/// (POST /users/{username}/collection/folders/{folder_id}/releases/{release_id})
/// via `DiscogsApiClient.addToCollection`, so exporting is available.
class CheckCollectionExportCapabilityUseCase {
  const CheckCollectionExportCapabilityUseCase();

  CheckCollectionExportCapabilityResult execute() {
    return const CollectionExportSupported();
  }
}
