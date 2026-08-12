import 'package:flutter_test/flutter_test.dart';
import 'package:sandiapp/core/logic/collectibility.dart';

void main() {
  final today = DateTime(2026, 8, 12);

  group('collectibilityOf — berdasar lastPayment', () {
    test('tepat 30 hari -> lancar', () => expect(
        collectibilityOf(lastPayment: DateTime(2026, 7, 13), firstPurchase: null, today: today),
        Collectibility.lancar));
    test('31 hari -> perhatian', () => expect(
        collectibilityOf(lastPayment: DateTime(2026, 7, 12), firstPurchase: null, today: today),
        Collectibility.perhatian));
    test('60 hari -> perhatian', () => expect(
        collectibilityOf(lastPayment: DateTime(2026, 6, 13), firstPurchase: null, today: today),
        Collectibility.perhatian));
    test('61 hari -> kurang lancar', () => expect(
        collectibilityOf(lastPayment: DateTime(2026, 6, 12), firstPurchase: null, today: today),
        Collectibility.kurangLancar));
    test('90 hari -> kurang lancar', () => expect(
        collectibilityOf(lastPayment: DateTime(2026, 5, 14), firstPurchase: null, today: today),
        Collectibility.kurangLancar));
    test('91 hari -> macet', () => expect(
        collectibilityOf(lastPayment: DateTime(2026, 5, 13), firstPurchase: null, today: today),
        Collectibility.macet));
  });

  test('belum pernah bayar -> pakai firstPurchase', () {
    expect(
        collectibilityOf(lastPayment: null, firstPurchase: DateTime(2026, 5, 1), today: today),
        Collectibility.macet); // > 90 hari sejak beli, belum bayar
    expect(
        collectibilityOf(lastPayment: null, firstPurchase: DateTime(2026, 8, 1), today: today),
        Collectibility.lancar);
  });

  test('tanpa jejak tanggal sama sekali -> macet (anomali)', () {
    expect(collectibilityOf(lastPayment: null, firstPurchase: null, today: today),
        Collectibility.macet);
  });

  test('collectibilityLabel', () {
    expect(collectibilityLabel(Collectibility.lancar), 'Lancar');
    expect(collectibilityLabel(Collectibility.perhatian), 'Dalam Perhatian');
    expect(collectibilityLabel(Collectibility.kurangLancar), 'Kurang Lancar');
    expect(collectibilityLabel(Collectibility.macet), 'Macet');
  });
}
