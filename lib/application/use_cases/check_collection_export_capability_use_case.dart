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
/// Exporting to Discogs requires a write API endpoint
/// (POST /users/{username}/collection/folders/{folder_id}/releases/{release_id}).
/// The Discogs API client currently only supports read operations, so this
/// use case returns [CollectionExportNotSupported] until write support is added.
class CheckCollectionExportCapabilityUseCase {
  const CheckCollectionExportCapabilityUseCase();

  CheckCollectionExportCapabilityResult execute() {
    return const CollectionExportNotSupported(
      'Export to Discogs is not available yet. '
      'You can export your collection as a CSV file instead.',
    );
  }
}
