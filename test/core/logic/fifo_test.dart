import 'package:flutter_test/flutter_test.dart';
import 'package:sandiapp/core/logic/fifo.dart';
import 'package:sandiapp/data/models/purchase.dart';
import 'package:sandiapp/data/models/payment.dart';

void main() {
  final t0 = DateTime.utc(2026, 1, 1);

  Purchase p(String id, int harga, DateTime beli, {DateTime? created}) => Purchase(
      id: id, customerId: 'c1', namaBarang: id, hargaJual: harga,
      tanggalBeli: beli, createdAt: created ?? t0, updatedAt: t0);

  Payment pm(int jumlah, {String status = 'verified'}) => Payment(
      id: 'm$jumlah', customerId: 'c1', jumlah: jumlah, tanggalBayar: t0,
      statusVerifikasi: status, createdAt: t0, updatedAt: t0);

  group('balanceOf', () {
    test('total hutang, bayar, sisa', () {
      final b = balanceOf([p('a', 5000000, t0), p('b', 300000, t0)], [pm(2000000)]);
      expect(b.totalHutang, 5300000);
      expect(b.totalBayar, 2000000);
      expect(b.sisa, 3300000);
    });
    test('payment pending/rejected tidak dihitung', () {
      final b = balanceOf([p('a', 1000, t0)],
          [pm(500, status: 'pending'), pm(300, status: 'rejected'), pm(200)]);
      expect(b.totalBayar, 200);
    });
  });

  group('allocateFifo', () {
    test('contoh handoff: 5jt + 300rb + 1.2jt, bayar 5.3jt', () {
      final res = allocateFifo(
          [p('hp', 5000000, DateTime(2026, 1, 1)),
           p('cooker', 300000, DateTime(2026, 2, 1)),
           p('kulkas', 1200000, DateTime(2026, 3, 1))],
          5300000);
      expect(res[0].status, ItemStatus.lunas);
      expect(res[1].status, ItemStatus.lunas);
      expect(res[2].status, ItemStatus.belum);
      expect(res[2].sisa, 1200000);
    });
    test('sebagian: bayar 5.1jt', () {
      final res = allocateFifo(
          [p('a', 5000000, DateTime(2026, 1, 1)), p('b', 300000, DateTime(2026, 2, 1))],
          5100000);
      expect(res[0].status, ItemStatus.lunas);
      expect(res[1].status, ItemStatus.sebagian);
      expect(res[1].allocated, 100000);
      expect(res[1].sisa, 200000);
    });
    test('urut by tanggalBeli lalu createdAt; kelebihan bayar aman', () {
      final res = allocateFifo(
          [p('baru', 1000, DateTime(2026, 5, 1)), p('lama', 1000, DateTime(2026, 1, 1))],
          5000);
      expect(res[0].purchase.id, 'lama'); // tertua dulu
      expect(res.every((r) => r.status == ItemStatus.lunas), true);
    });
    test('tanpa pembayaran: semua belum', () {
      final res = allocateFifo([p('a', 1000, t0)], 0);
      expect(res.single.status, ItemStatus.belum);
    });
  });
}
