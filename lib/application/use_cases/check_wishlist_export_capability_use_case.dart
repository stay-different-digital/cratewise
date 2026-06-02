sealed class CheckWishlistExportCapabilityResult {
  const CheckWishlistExportCapabilityResult();
}

class WishlistExportSupported extends CheckWishlistExportCapabilityResult {
  const WishlistExportSupported();
}

class WishlistExportNotSupported extends CheckWishlistExportCapabilityResult {
  const WishlistExportNotSupported(this.reason);

  final String reason;
}

/// Checks whether the app can export local wishlist items to Discogs.
///
/// Exporting wantlist items to Discogs requires a write API endpoint.
/// The Discogs API client does not yet support wantlist write operations,
/// so this use case returns [WishlistExportNotSupported] until write support
/// is added.
class CheckWishlistExportCapabilityUseCase {
  const CheckWishlistExportCapabilityUseCase();

  CheckWishlistExportCapabilityResult execute() {
    return const WishlistExportNotSupported(
      'Export to Discogs is not available yet. '
      'You can export your wishlist as a CSV file instead.',
    );
  }
}
