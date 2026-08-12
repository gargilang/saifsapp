import 'package:flutter_test/flutter_test.dart';
import 'package:sandiapp/core/logic/customer_stats.dart';
import 'package:sandiapp/core/logic/fifo.dart';
import 'package:sandiapp/data/models/customer.dart';
import 'package:sandiapp/data/models/payment.dart';
import 'package:sandiapp/data/models/purchase.dart';
import 'package:sandiapp/data/repositories/app_repository.dart';
import 'package:sandiapp/features/statement/statement_data.dart';

void main() {
  final t0 = DateTime.utc(2026, 1, 1);
  final customer = Customer(id: 'c1', nama: 'WIWIK', noHp: '0812', createdAt: t0, updatedAt: t0);
  final p1 = Purchase(id: 'p1', customerId: 'c1', namaBarang: 'HP', hargaJual: 2000000,
      tanggalBeli: DateTime(2026, 1, 1), createdAt: t0, updatedAt: t0);
  final p2 = Purchase(id: 'p2', customerId: 'c1', namaBarang: 'TV', hargaJual: 1000000,
      tanggalBeli: DateTime(2026, 2, 1), createdAt: t0, updatedAt: t0);
  final m1 = Payment(id: 'm1', customerId: 'c1', jumlah: 1500000, tanggalBayar: DateTime(2026, 1, 15),
      createdAt: t0, updatedAt: t0);

  test('buildStatementData merangkum saldo, barang, dan pembayaran', () {
    final balance = balanceOf([p1, p2], [m1]);
    final items = allocateFifo([p1, p2], balance.totalBayar);
    final detail = CustomerDetailData(
      customer: customer,
      items: items,
      payments: [m1],
      balance: balance,
      stats: customerStatsOf([p1, p2], [m1]),
    );

    final data = buildStatementData(detail, now: DateTime(2026, 8, 12));

    expect(data.nama, 'WIWIK');
    expect(data.noHp, '0812');
    expect(data.totalBelanja, 3000000);
    expect(data.totalBayar, 1500000);
    expect(data.sisaHutang, 1500000);
    expect(data.items.length, 2);
    expect(data.items[0].statusLabel, 'SEBAGIAN'); // p1: 2jt, alokasi 1.5jt
    expect(data.items[0].sisa, 500000);
    expect(data.items[1].statusLabel, 'BELUM'); // p2: belum ter-cover
    expect(data.payments.single.jumlah, 1500000);
    expect(data.generatedAt, DateTime(2026, 8, 12));
  });
}
