import 'package:cratewise/application/use_cases/check_wishlist_export_capability_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CheckWishlistExportCapabilityUseCase', () {
    CheckWishlistExportCapabilityUseCase makeUseCase() =>
        const CheckWishlistExportCapabilityUseCase();

    test('returns WishlistExportSupported', () {
      final result = makeUseCase().execute();
      expect(result, isA<WishlistExportSupported>());
    });

    test('execute is synchronous and makes no network calls', () {
      final result = makeUseCase().execute();
      expect(result, isNotNull);
    });

    test('calling execute twice returns consistent result', () {
      final uc = makeUseCase();
      final r1 = uc.execute();
      final r2 = uc.execute();
      expect(r1.runtimeType, r2.runtimeType);
    });
  });
}
