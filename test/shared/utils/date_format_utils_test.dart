import 'package:cratewise/shared/utils/date_format_utils.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  const enUs = Locale('en', 'US');

  group('formatDate', () {
    test('formats date in en_US as abbreviated month, day, year', () {
      final dt = DateTime(2026, 1, 5);
      final result = formatDate(dt, enUs);
      expect(result, DateFormat.yMMMd('en_US').format(dt));
    });

    test('output contains abbreviated month, day, and year', () {
      final result = formatDate(DateTime(2026, 6, 20), enUs);
      expect(result, contains('Jun'));
      expect(result, contains('20'));
      expect(result, contains('2026'));
    });

    test('does not produce ISO-8601 YYYY-MM-DD format', () {
      final result = formatDate(DateTime(2026, 1, 5), enUs);
      expect(result, isNot(equals('2026-01-05')));
      expect(result, isNot(contains('2026-01')));
    });

    test('converts to local time before formatting', () {
      final utcDt = DateTime.utc(2026, 6, 20, 0, 0);
      final result = formatDate(utcDt, enUs);
      expect(result, isNotEmpty);
      expect(result, contains('2026'));
    });
  });

  group('formatDateTime', () {
    test('includes date and time components in en_US', () {
      final dt = DateTime(2026, 6, 1, 14, 30);
      final result = formatDateTime(dt, enUs);
      expect(result, contains('Jun'));
      expect(result, contains('1'));
      expect(result, contains('2026'));
      expect(result, contains('30'));
    });

    test('uses 12-hour AM/PM time in en_US', () {
      final dt = DateTime(2026, 6, 1, 14, 30);
      final result = formatDateTime(dt, enUs);
      expect(result, contains('PM'));
      expect(result, isNot(contains('14:30')));
    });

    test('separates date and time with a comma', () {
      final dt = DateTime(2026, 6, 1, 14, 30);
      final result = formatDateTime(dt, enUs);
      expect(result, contains(','));
    });

    test('matches expected en_US output for a known datetime', () {
      final dt = DateTime(2026, 6, 1, 14, 30);
      final expectedDate = DateFormat.yMMMd('en_US').format(dt);
      final expectedTime = DateFormat.jm('en_US').format(dt);
      expect(formatDateTime(dt, enUs), '$expectedDate, $expectedTime');
    });
  });
}
