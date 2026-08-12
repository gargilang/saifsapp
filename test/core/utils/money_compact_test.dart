import 'package:flutter_test/flutter_test.dart';
import 'package:sandiapp/core/utils/money.dart';

void main() {
  group('formatRupiahCompact', () {
    test('di bawah 100 rb -> format penuh', () {
      expect(formatRupiahCompact(0), 'Rp 0');
      expect(formatRupiahCompact(75000), 'Rp 75.000');
      expect(formatRupiahCompact(99999), 'Rp 99.999');
    });

    test('rentang ratusan ribu -> rb', () {
      expect(formatRupiahCompact(100000), 'Rp 100 rb');
      expect(formatRupiahCompact(850000), 'Rp 850 rb');
    });

    test('rentang jutaan -> jt, maks 2 desimal, trailing zero dibuang', () {
      expect(formatRupiahCompact(1000000), 'Rp 1 jt');
      expect(formatRupiahCompact(1250000), 'Rp 1,25 jt');
      expect(formatRupiahCompact(87500000), 'Rp 87,5 jt');
      expect(formatRupiahCompact(87590000), 'Rp 87,59 jt');
    });

    test('rentang miliar -> M', () {
      expect(formatRupiahCompact(5000000000), 'Rp 5 M');
      expect(formatRupiahCompact(1250000000), 'Rp 1,25 M');
    });

    test('negatif tetap terformat dengan tanda minus di depan', () {
      expect(formatRupiahCompact(-1250000), '-Rp 1,25 jt');
    });
  });
}
