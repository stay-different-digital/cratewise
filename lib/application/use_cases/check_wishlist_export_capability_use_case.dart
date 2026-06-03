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
class CheckWishlistExportCapabilityUseCase {
  const CheckWishlistExportCapabilityUseCase();

  CheckWishlistExportCapabilityResult execute() {
    return const WishlistExportSupported();
  }
}
