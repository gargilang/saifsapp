import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sandiapp/core/utils/money.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));
  group('formatRupiah', () {
    test('format ribuan', () => expect(formatRupiah(1500000), 'Rp 1.500.000'));
    test('nol', () => expect(formatRupiah(0), 'Rp 0'));
  });
  group('parseRupiah', () {
    test('angka polos', () => expect(parseRupiah('1500000'), 1500000));
    test('dengan pemisah', () => expect(parseRupiah('Rp 1.500.000'), 1500000));
    test('kosong', () => expect(parseRupiah(''), 0));
  });
}
