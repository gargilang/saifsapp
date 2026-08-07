import 'package:flutter_test/flutter_test.dart';
import 'package:sandiapp/core/logic/budget.dart';
import 'package:sandiapp/data/models/budget_entry.dart';

void main() {
  final t0 = DateTime.utc(2021, 4, 27, 8);

  BudgetEntry e(String id, String tipe, int jumlah, DateTime tgl, DateTime created) =>
      BudgetEntry(id: id, tanggal: tgl, namaTransaksi: id, tipe: tipe,
          jumlah: jumlah, createdAt: created, updatedAt: created);

  test('saldo berjalan sesuai Sheet3 Excel', () {
    final lines = withRunningSaldo([
      e('a', 'pemasukan', 5000000, DateTime(2021, 4, 27), t0),
      e('b', 'pengeluaran', 160000, DateTime(2021, 4, 27), t0.add(const Duration(minutes: 1))),
      e('c', 'pengeluaran', 100000, DateTime(2021, 4, 27), t0.add(const Duration(minutes: 2))),
    ]);
    expect(lines.map((l) => l.saldo), [5000000, 4840000, 4740000]);
  });

  test('urut by tanggal lalu createdAt, saldoAwal diperhitungkan', () {
    final lines = withRunningSaldo([
      e('nanti', 'pemasukan', 1000, DateTime(2021, 5, 1), t0),
      e('dulu', 'pemasukan', 2000, DateTime(2021, 4, 1), t0),
    ], saldoAwal: 100);
    expect(lines.first.entry.id, 'dulu');
    expect(lines.map((l) => l.saldo), [2100, 3100]);
  });
}
