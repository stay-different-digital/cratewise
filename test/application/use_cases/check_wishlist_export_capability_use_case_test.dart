import 'package:cratewise/application/use_cases/check_wishlist_export_capability_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CheckWishlistExportCapabilityUseCase', () {
    CheckWishlistExportCapabilityUseCase makeUseCase() =>
        const CheckWishlistExportCapabilityUseCase();

    test('returns WishlistExportNotSupported', () {
      final result = makeUseCase().execute();
      expect(result, isA<WishlistExportNotSupported>());
    });

    test('not supported result has a non-empty reason', () {
      final result =
          makeUseCase().execute() as WishlistExportNotSupported;
      expect(result.reason, isNotEmpty);
    });

    test('reason does not contain raw token or secret wording', () {
      final result =
          makeUseCase().execute() as WishlistExportNotSupported;
      expect(result.reason.toLowerCase(), isNot(contains('token')));
      expect(result.reason.toLowerCase(), isNot(contains('secret')));
    });

    test('reason mentions an alternative (CSV)', () {
      final result =
          makeUseCase().execute() as WishlistExportNotSupported;
      expect(result.reason.toLowerCase(), contains('csv'));
    });

    test('execute is synchronous and makes no network calls', () {
      final result = makeUseCase().execute();
      expect(result, isNotNull);
    });

    test('calling execute twice returns consistent result', () {
      final uc = makeUseCase();
      final r1 = uc.execute() as WishlistExportNotSupported;
      final r2 = uc.execute() as WishlistExportNotSupported;
      expect(r1.reason, r2.reason);
    });
  });
}
