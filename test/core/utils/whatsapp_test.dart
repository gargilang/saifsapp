import 'package:flutter_test/flutter_test.dart';
import 'package:sandiapp/core/utils/whatsapp.dart';

void main() {
  group('normalizePhoneId', () {
    test('null/empty -> null', () {
      expect(normalizePhoneId(null), isNull);
      expect(normalizePhoneId(''), isNull);
      expect(normalizePhoneId('abc'), isNull);
    });
    test('awalan 0 -> diganti 62', () {
      expect(normalizePhoneId('0812-3456-7890'), '6281234567890');
    });
    test('awalan 8 tanpa 0 -> ditambah 62', () {
      expect(normalizePhoneId('81234567890'), '6281234567890');
    });
    test('sudah 62 atau +62 -> dirapikan', () {
      expect(normalizePhoneId('+62 812 3456 7890'), '6281234567890');
      expect(normalizePhoneId('6281234567890'), '6281234567890');
    });
    test('terlalu pendek -> null', () {
      expect(normalizePhoneId('0812'), isNull);
    });
  });

  test('buildWaReminderUri', () {
    final uri = buildWaReminderUri(phone: '6281234567890', message: 'Halo Dunia');
    expect(uri.toString(), 'https://wa.me/6281234567890?text=Halo%20Dunia');
  });

  test('renderWaTemplate mengganti semua placeholder', () {
    final msg = renderWaTemplate(
      "Halo {nama}, sisa {sisa_hutang} untuk {bisnis}.",
      nama: 'WIWIK',
      sisaHutang: 750000,
    );
    expect(msg, 'Halo WIWIK, sisa Rp 750.000 untuk S&I Finance Solution.');
  });
}
