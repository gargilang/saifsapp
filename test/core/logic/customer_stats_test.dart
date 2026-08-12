import 'package:flutter_test/flutter_test.dart';
import 'package:sandiapp/core/logic/customer_stats.dart';
import 'package:sandiapp/data/models/payment.dart';
import 'package:sandiapp/data/models/purchase.dart';

void main() {
  final t0 = DateTime.utc(2026, 1, 1);
  Purchase p(String id, int harga, DateTime beli) => Purchase(
      id: id, customerId: 'c1', namaBarang: id, hargaJual: harga,
      tanggalBeli: beli, createdAt: t0, updatedAt: t0);
  Payment pm(String id, int jumlah, DateTime tgl, {String status = 'verified'}) => Payment(
      id: id, customerId: 'c1', jumlah: jumlah, tanggalBayar: tgl,
      statusVerifikasi: status, createdAt: t0, updatedAt: t0);

  test('tanpa data -> semua null/0, tidak setia', () {
    final s = customerStatsOf([], []);
    expect(s.jumlahTransaksi, 0);
    expect(s.totalBelanja, 0);
    expect(s.totalBayar, 0);
    expect(s.rataRataCicilan, isNull);
    expect(s.kecepatanLunasHari, isNull);
    expect(s.customerSejak, isNull);
    expect(s.customerSetia, isFalse);
  });

  test('>= 3 transaksi -> customerSetia true', () {
    final s = customerStatsOf(
        [p('p1', 100, DateTime(2026, 1, 1)), p('p2', 100, DateTime(2026, 2, 1)),
         p('p3', 100, DateTime(2026, 3, 1))], []);
    expect(s.customerSetia, isTrue);
    expect(s.customerSejak, DateTime(2026, 1, 1));
  });

  test('rataRataCicilan hanya dari payment verified', () {
    final s = customerStatsOf([p('p1', 1000000, DateTime(2026, 1, 1))], [
      pm('m1', 500000, DateTime(2026, 1, 10)),
      pm('m2', 300000, DateTime(2026, 1, 20)),
      pm('m3', 999999, DateTime(2026, 1, 25), status: 'pending'), // diabaikan
    ]);
    expect(s.totalBayar, 800000);
    expect(s.rataRataCicilan, 400000); // (500000+300000)/2
  });

  test('kecepatanLunasHari: rata-rata hari beli -> lunas per barang (FIFO)', () {
    final s = customerStatsOf(
      [p('p1', 1000000, DateTime(2026, 1, 1)), p('p2', 500000, DateTime(2026, 2, 1))],
      [
        pm('m1', 600000, DateTime(2026, 1, 11)),
        pm('m2', 400000, DateTime(2026, 1, 21)), // p1 lunas di 21 Jan -> 20 hari
        pm('m3', 500000, DateTime(2026, 2, 11)), // p2 lunas di 11 Feb -> 10 hari
      ],
    );
    expect(s.kecepatanLunasHari, 15); // (20+10)/2
  });

  test('barang belum lunas -> tidak dihitung ke kecepatanLunasHari', () {
    final s = customerStatsOf(
      [p('p1', 1000000, DateTime(2026, 1, 1)), p('p2', 500000, DateTime(2026, 2, 1))],
      [pm('m1', 1000000, DateTime(2026, 1, 11))], // hanya p1 lunas
    );
    expect(s.kecepatanLunasHari, 10);
  });
}
