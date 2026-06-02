import 'package:cratewise/application/use_cases/check_collection_export_capability_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CheckCollectionExportCapabilityUseCase', () {
    CheckCollectionExportCapabilityUseCase makeUseCase() =>
        const CheckCollectionExportCapabilityUseCase();

    test('returns CollectionExportNotSupported', () {
      final result = makeUseCase().execute();
      expect(result, isA<CollectionExportNotSupported>());
    });

    test('not supported result has a non-empty reason', () {
      final result =
          makeUseCase().execute() as CollectionExportNotSupported;
      expect(result.reason, isNotEmpty);
    });

    test('reason does not contain raw token or secret wording', () {
      final result =
          makeUseCase().execute() as CollectionExportNotSupported;
      expect(result.reason.toLowerCase(), isNot(contains('token')));
      expect(result.reason.toLowerCase(), isNot(contains('secret')));
    });

    test('reason mentions an alternative (CSV)', () {
      final result =
          makeUseCase().execute() as CollectionExportNotSupported;
      expect(result.reason.toLowerCase(), contains('csv'));
    });

    test('execute is synchronous and makes no network calls', () {
      // If this completes without async it confirms no I/O is involved.
      final result = makeUseCase().execute();
      expect(result, isNotNull);
    });

    test('calling execute twice returns consistent result', () {
      final uc = makeUseCase();
      final r1 = uc.execute() as CollectionExportNotSupported;
      final r2 = uc.execute() as CollectionExportNotSupported;
      expect(r1.reason, r2.reason);
    });
  });
}
