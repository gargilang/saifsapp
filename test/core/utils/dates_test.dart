import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sandiapp/core/utils/dates.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));
  final today = DateTime(2026, 8, 12);

  group('relativeDay', () {
    test('hari ini', () => expect(relativeDay(DateTime(2026, 8, 12), today), 'Hari ini'));
    test('kemarin', () => expect(relativeDay(DateTime(2026, 8, 11), today), 'Kemarin'));
    test('beberapa hari lalu (< 7 hari)',
        () => expect(relativeDay(DateTime(2026, 8, 7), today), '5 hari lalu'));
    test('>= 7 hari -> tanggal penuh',
        () => expect(relativeDay(DateTime(2026, 8, 5), today), '5 Agu 2026'));
    test('tanggal masa depan -> Hari ini (fallback aman)',
        () => expect(relativeDay(DateTime(2026, 8, 20), today), 'Hari ini'));
  });
}
