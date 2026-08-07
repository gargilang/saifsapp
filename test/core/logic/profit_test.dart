import 'package:flutter_test/flutter_test.dart';
import 'package:sandiapp/core/logic/profit.dart';
import 'package:sandiapp/data/models/purchase.dart';

void main() {
  final t0 = DateTime.utc(2026, 1, 1);

  Purchase p(int jual, int? beli, DateTime tgl) => Purchase(
      id: '$tgl-$jual', customerId: 'c1', namaBarang: 'x', hargaJual: jual,
      hargaBeli: beli, tanggalBeli: tgl, createdAt: t0, updatedAt: t0);

  final data = [
    p(2050000, 1700000, DateTime(2020, 12, 30)),
    p(5000000, 3000000, DateTime(2020, 12, 28)),
    p(2100000, 1750000, DateTime(2021, 1, 8)),
    p(1000000, null, DateTime(2021, 1, 20)), // tanpa harga beli: dikecualikan
  ];

  test('profitPerYear: grup + hitung, skip hargaBeli null', () {
    final rows = profitPerYear(data);
    expect(rows.length, 2);
    expect(rows[0].year, 2020);
    expect(rows[0].qty, 2);
    expect(rows[0].penjualan, 7050000);
    expect(rows[0].modal, 4700000);
    expect(rows[0].keuntungan, 2350000);
    expect(rows[1].year, 2021);
    expect(rows[1].qty, 1);
  });

  test('profitPerMonth: filter tahun, grup per bulan', () {
    final rows = profitPerMonth(data, 2020);
    expect(rows.single.month, 12);
    expect(rows.single.keuntungan, 2350000);
    expect(profitPerMonth(data, 2022), isEmpty);
  });
}
