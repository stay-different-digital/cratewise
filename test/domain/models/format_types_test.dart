import 'package:cratewise/domain/models/format_types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatTypes (US-143)', () {
    test('one format: the name before the first comma', () {
      expect(formatTypes('Vinyl, 12", 33 ⅓ RPM'), ['Vinyl']);
    });

    test('several formats, one per line, in order', () {
      expect(formatTypes('Vinyl, LP, Album\nFile, MP3, 320 kbps'), [
        'Vinyl',
        'File',
      ]);
    });

    test('a name without descriptions', () {
      expect(formatTypes('CD'), ['CD']);
      expect(formatTypes('File\nVinyl, LP'), ['File', 'Vinyl']);
    });

    test('duplicates collapse, first occurrence wins the order', () {
      expect(formatTypes('Vinyl, LP\nCD, Album\nVinyl, 7"'), ['Vinyl', 'CD']);
    });

    test('null, empty and blank lines give nothing', () {
      expect(formatTypes(null), isEmpty);
      expect(formatTypes(''), isEmpty);
      expect(formatTypes(' \n , LP'), isEmpty);
    });
  });
}
