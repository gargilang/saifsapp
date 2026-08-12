import 'package:flutter_test/flutter_test.dart';
import 'package:sandiapp/core/logic/collectibility.dart';
import 'package:sandiapp/core/logic/fifo.dart';
import 'package:sandiapp/data/models/budget_entry.dart';
import 'package:sandiapp/data/models/customer.dart';
import 'package:sandiapp/data/models/payment.dart';
import 'package:sandiapp/data/models/purchase.dart';
import 'package:sandiapp/data/repositories/app_repository.dart';

import '../../fakes/fake_backend.dart';

void main() {
  final t0 = DateTime.utc(2026, 8, 1, 10);
  late FakeBackend backend;
  late AppRepository repo;
  var syncRequested = 0;

  Customer c(String id, String nama) =>
      Customer(id: id, nama: nama, createdAt: t0, updatedAt: t0);
  Purchase p(String id, String cid, int jual, DateTime beli, {int? beli_}) => Purchase(
      id: id, customerId: cid, namaBarang: id, hargaJual: jual, hargaBeli: beli_,
      tanggalBeli: beli, createdAt: t0, updatedAt: t0);
  Payment pm(String id, String cid, int jumlah, DateTime tgl) => Payment(
      id: id, customerId: cid, jumlah: jumlah, tanggalBayar: tgl,
      createdAt: t0, updatedAt: t0);

  setUp(() {
    syncRequested = 0;
    backend = FakeBackend(
      customers: [c('c1', 'WIWIK'), c('c2', 'IKA'), c('c3', 'ANAS')],
      purchases: [
        p('p1', 'c1', 2050000, DateTime(2026, 7, 1), beli_: 1700000),
        p('p2', 'c1', 1200000, DateTime(2026, 8, 2)),
        p('p3', 'c2', 5000000, DateTime(2026, 8, 3), beli_: 3000000),
      ],
      payments: [
        pm('m1', 'c1', 2500000, DateTime(2026, 8, 5)),
        pm('m2', 'c2', 1000000, DateTime(2026, 8, 6)),
      ],
    );
    repo = AppRepository(backend,
        currentUserId: () => 'admin-1', onLocalWrite: () => syncRequested++);
  });

  test('customers: saldo dihitung, search, sort', () async {
    final all = await repo.customers();
    final wiwik = all.singleWhere((e) => e.customer.id == 'c1');
    expect(wiwik.totalHutang, 3250000);
    expect(wiwik.totalBayar, 2500000);
    expect(wiwik.sisa, 750000);

    expect((await repo.customers(query: 'ika')).single.customer.nama, 'IKA');
    final sorted = await repo.customers(sort: CustomerSort.hutang);
    expect(sorted.first.customer.id, 'c2'); // sisa 4jt > 750rb > 0
  });

  test('customerDetail: FIFO + payments terbaru dulu', () async {
    final d = await repo.customerDetail('c1');
    expect(d.balance.sisa, 750000);
    expect(d.items.first.status, ItemStatus.lunas); // p1 tertua lunas
    expect(d.items.last.status, ItemStatus.sebagian); // sisa masuk ke p2
    expect(d.payments.single.id, 'm1');
  });

  test('dashboardStats', () async {
    final s = await repo.dashboardStats(now: t0);
    expect(s.totalPiutang, 4750000); // 750rb + 4jt
    expect(s.bayarBulanIni, 3500000); // m1 + m2, keduanya di Agustus 2026
    expect(s.customerBerhutang, 2);
    expect(s.topHutang.first.customer.id, 'c2');
  });

  test('savePayment: set createdBy, panggil onLocalWrite', () async {
    await repo.savePayment(pm('m9', 'c1', 100000, DateTime(2026, 8, 8)));
    expect(backend.payments.singleWhere((e) => e.id == 'm9').createdBy, 'admin-1');
    expect(syncRequested, 1);
  });

  test('deleteCustomer: soft delete, hilang dari read', () async {
    await repo.deleteCustomer('c3');
    final ids = (await repo.customers()).map((e) => e.customer.id);
    expect(ids, isNot(contains('c3')));
    expect(backend.customers.singleWhere((e) => e.id == 'c3').deletedAt, isNotNull);
  });

  test('budgetMonth: saldoAwal dari bulan sebelumnya', () async {
    backend.budget.addAll([
      BudgetEntry(id: 'b0', tanggal: DateTime(2026, 7, 1), namaTransaksi: 'x',
          tipe: 'pemasukan', jumlah: 1000000, createdAt: t0, updatedAt: t0),
      BudgetEntry(id: 'b1', tanggal: DateTime(2026, 8, 1), namaTransaksi: 'y',
          tipe: 'pengeluaran', jumlah: 250000, createdAt: t0, updatedAt: t0),
    ]);
    final lines = await repo.budgetMonth(2026, 8);
    expect(lines.single.saldo, 750000);
  });

  test('customers: kolektibilitas + filter macet/berhutang/lunas + sort terakhirBayar',
      () async {
    final t = DateTime(2026, 8, 12);
    final all = await repo.customers(today: t);
    final wiwik = all.singleWhere((e) => e.customer.id == 'c1');
    expect(wiwik.lastPaymentAt, DateTime(2026, 8, 5));
    expect(wiwik.collectibility, Collectibility.lancar); // 7 hari

    final anas = all.singleWhere((e) => e.customer.id == 'c3');
    expect(anas.collectibility, isNull); // tanpa pembelian -> tanpa hutang

    backend.customers.add(c('c4', 'BUDI'));
    backend.purchases.add(p('p9', 'c4', 1000000, DateTime(2026, 1, 1)));
    backend.payments.add(pm('m9', 'c4', 100000, DateTime(2026, 3, 1))); // 164 hari lalu

    final macet = await repo.customers(filter: CustomerFilter.macet, today: t);
    expect(macet.map((e) => e.customer.id), ['c4']);

    final berhutang = await repo.customers(filter: CustomerFilter.berhutang, today: t);
    expect(berhutang.map((e) => e.customer.id), containsAll(['c1', 'c2', 'c4']));

    final byLast = await repo.customers(sort: CustomerSort.terakhirBayar, today: t);
    expect(byLast.first.customer.id, 'c2'); // lastPaymentAt 8/6, paling baru
  });

  test('customerDetail: stats terisi dari customerStatsOf', () async {
    final d = await repo.customerDetail('c1');
    expect(d.stats.jumlahTransaksi, 2);
    expect(d.stats.totalBayar, 2500000);
  });

  test('dashboardStats: macet, tren 6 bulan, aktivitas terbaru', () async {
    final s = await repo.dashboardStats(now: DateTime(2026, 8, 12));
    expect(s.macetCount, 0); // m1/m2 baru 6-7 hari lalu
    expect(s.trend.length, 6);
    expect(s.trend.last.year, 2026);
    expect(s.trend.last.month, 8);
    expect(s.trend.last.total, 3500000);
    expect(s.trend.first.month, 3); // 5 bulan sebelum Agustus
    expect(s.aktivitas.first.payment.id, 'm2'); // 8/6, paling baru
    expect(s.aktivitas.first.customerName, 'IKA');
  });
}
