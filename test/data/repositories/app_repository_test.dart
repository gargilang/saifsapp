import 'package:flutter_test/flutter_test.dart';
import 'package:sandiapp/core/logic/collectibility.dart';
import 'package:sandiapp/core/logic/fifo.dart';
import 'package:sandiapp/data/models/budget_entry.dart';
import 'package:sandiapp/data/models/customer.dart';
import 'package:sandiapp/data/models/fund_ledger_entry.dart';
import 'package:sandiapp/data/models/fund_source.dart';
import 'package:sandiapp/data/models/payment.dart';
import 'package:sandiapp/data/models/purchase.dart';
import 'package:sandiapp/data/repositories/app_repository.dart';

import '../../fakes/fake_backend.dart';

void main() {
  final t0 = DateTime.utc(2026, 8, 1, 10);
  late FakeBackend backend;
  late AppRepository repo;
  var syncRequested = 0;

  FundSource source(String id, String nama, String colorKey) => FundSource(
    id: id,
    nama: nama,
    colorKey: colorKey,
    createdAt: t0,
    updatedAt: t0,
  );
  FundLedgerEntry opening(String sourceId, int amount) => FundLedgerEntry(
    id: 'opening-$sourceId',
    fundSourceId: sourceId,
    tanggal: DateTime(2026, 8, 1),
    tipe: 'saldo_awal',
    jumlahDelta: amount,
    referenceType: 'migration',
    createdAt: t0,
    updatedAt: t0,
  );

  Customer c(String id, String nama) =>
      Customer(id: id, nama: nama, createdAt: t0, updatedAt: t0);
  Purchase p(
    String id,
    String cid,
    int jual,
    DateTime beli, {
    int? beli_,
    String? fundSourceId,
  }) => Purchase(
    id: id,
    customerId: cid,
    namaBarang: id,
    hargaJual: jual,
    hargaBeli: beli_,
    tanggalBeli: beli,
    fundSourceId: fundSourceId,
    createdAt: t0,
    updatedAt: t0,
  );
  Payment pm(
    String id,
    String cid,
    int jumlah,
    DateTime tgl, {
    String? fundSourceId,
    String status = 'verified',
  }) => Payment(
    id: id,
    customerId: cid,
    jumlah: jumlah,
    tanggalBayar: tgl,
    fundSourceId: fundSourceId,
    statusVerifikasi: status,
    createdAt: t0,
    updatedAt: t0,
  );

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
      fundSources: [
        source('sandi', 'Sandi', 'green'),
        source('ika', 'Ika', 'gold'),
      ],
      fundLedger: [opening('sandi', 750000), opening('ika', 4000000)],
    );
    repo = AppRepository(
      backend,
      currentUserId: () => 'admin-1',
      onLocalWrite: () => syncRequested++,
    );
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
    await repo.savePayment(
      pm('m9', 'c1', 100000, DateTime(2026, 8, 8), fundSourceId: 'sandi'),
    );
    expect(
      backend.payments.singleWhere((e) => e.id == 'm9').createdBy,
      'admin-1',
    );
    expect(syncRequested, 1);
  });

  test('deleteCustomer: soft delete, hilang dari read', () async {
    await repo.deleteCustomer('c3');
    final ids = (await repo.customers()).map((e) => e.customer.id);
    expect(ids, isNot(contains('c3')));
    expect(
      backend.customers.singleWhere((e) => e.id == 'c3').deletedAt,
      isNotNull,
    );
  });

  test(
    'deleteCustomerCascade: soft delete customer + purchases + payments',
    () async {
      await repo.deleteCustomerCascade('c1');
      final ids = (await repo.customers()).map((e) => e.customer.id);
      expect(ids, isNot(contains('c1')));
      expect(
        backend.customers.singleWhere((e) => e.id == 'c1').deletedAt,
        isNotNull,
      );
      // purchases c1 ikut terhapus
      expect(
        backend.purchases.singleWhere((e) => e.id == 'p1').deletedAt,
        isNotNull,
      );
      expect(
        backend.purchases.singleWhere((e) => e.id == 'p2').deletedAt,
        isNotNull,
      );
      // payments c1 ikut terhapus
      expect(
        backend.payments.singleWhere((e) => e.id == 'm1').deletedAt,
        isNotNull,
      );
      // customer lain tidak terpengaruh
      expect(
        backend.customers.singleWhere((e) => e.id == 'c2').deletedAt,
        isNull,
      );
      expect(
        backend.purchases.singleWhere((e) => e.id == 'p3').deletedAt,
        isNull,
      );
      expect(
        backend.payments.singleWhere((e) => e.id == 'm2').deletedAt,
        isNull,
      );
    },
  );

  test('savePurchase: auto-create budget entry pengeluaran', () async {
    await repo.savePurchase(
      p('p9', 'c1', 500000, DateTime(2026, 8, 10), fundSourceId: 'sandi'),
    );
    final budget = backend.budget.singleWhere((e) => e.sourceId == 'p9');
    expect(budget.sourceType, 'purchase');
    expect(budget.tipe, 'pengeluaran');
    expect(budget.jumlah, 500000);
    expect(budget.namaTransaksi, contains('WIWIK'));
    expect(budget.namaTransaksi, contains('p9'));
  });

  test('savePayment: auto-create budget entry pemasukan', () async {
    await repo.savePayment(
      pm('m9', 'c1', 300000, DateTime(2026, 8, 10), fundSourceId: 'sandi'),
    );
    final budget = backend.budget.singleWhere((e) => e.sourceId == 'm9');
    expect(budget.sourceType, 'payment');
    expect(budget.tipe, 'pemasukan');
    expect(budget.jumlah, 300000);
    expect(budget.namaTransaksi, contains('WIWIK'));
    expect(budget.namaTransaksi, contains('Pembayaran'));
  });

  test('deletePurchase: auto-delete budget entry terkait', () async {
    await repo.savePurchase(
      p('p9', 'c1', 500000, DateTime(2026, 8, 10), fundSourceId: 'sandi'),
    );
    expect(backend.budget.any((e) => e.sourceId == 'p9'), isTrue);
    await repo.deletePurchase('p9');
    expect(
      backend.budget.any((e) => e.sourceId == 'p9' && e.deletedAt == null),
      isFalse,
    );
  });

  test('deletePayment: auto-delete budget entry terkait', () async {
    await repo.savePayment(
      pm('m9', 'c1', 300000, DateTime(2026, 8, 10), fundSourceId: 'sandi'),
    );
    expect(backend.budget.any((e) => e.sourceId == 'm9'), isTrue);
    await repo.deletePayment('m9');
    expect(
      backend.budget.any((e) => e.sourceId == 'm9' && e.deletedAt == null),
      isFalse,
    );
  });

  test('budgetMonth: saldoAwal dari bulan sebelumnya', () async {
    backend.budget.addAll([
      BudgetEntry(
        id: 'b0',
        tanggal: DateTime(2026, 7, 1),
        namaTransaksi: 'x',
        tipe: 'pemasukan',
        jumlah: 1000000,
        createdAt: t0,
        updatedAt: t0,
      ),
      BudgetEntry(
        id: 'b1',
        tanggal: DateTime(2026, 8, 1),
        namaTransaksi: 'y',
        tipe: 'pengeluaran',
        jumlah: 250000,
        createdAt: t0,
        updatedAt: t0,
      ),
    ]);
    final lines = await repo.budgetMonth(2026, 8);
    expect(lines.single.saldo, 750000);
  });

  test(
    'customers: kolektibilitas + filter macet/berhutang/lunas + sort terakhirBayar',
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
      backend.payments.add(
        pm('m9', 'c4', 100000, DateTime(2026, 3, 1)),
      ); // 164 hari lalu

      final macet = await repo.customers(
        filter: CustomerFilter.macet,
        today: t,
      );
      expect(macet.map((e) => e.customer.id), ['c4']);

      final berhutang = await repo.customers(
        filter: CustomerFilter.berhutang,
        today: t,
      );
      expect(
        berhutang.map((e) => e.customer.id),
        containsAll(['c1', 'c2', 'c4']),
      );

      final byLast = await repo.customers(
        sort: CustomerSort.terakhirBayar,
        today: t,
      );
      expect(byLast.first.customer.id, 'c2'); // lastPaymentAt 8/6, paling baru
    },
  );

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

  test(
    'payment non-verified diabaikan dari balance, lastPaymentAt, dan aktivitas',
    () async {
      backend.payments.add(
        pm(
          'm8',
          'c1',
          999999,
          DateTime(2026, 8, 10),
        ).copyWith(statusVerifikasi: 'pending'),
      );
      final all = await repo.customers(today: DateTime(2026, 8, 12));
      final wiwik = all.singleWhere((e) => e.customer.id == 'c1');
      expect(wiwik.totalBayar, 2500000); // tidak berubah oleh payment pending
      expect(wiwik.lastPaymentAt, DateTime(2026, 8, 5)); // bukan 8/10

      final s = await repo.dashboardStats(now: DateTime(2026, 8, 12));
      expect(s.bayarBulanIni, 3500000); // tidak berubah
      expect(s.aktivitas.map((e) => e.payment.id), isNot(contains('m8')));
    },
  );

  test('fundSummary cocok dengan total piutang', () async {
    final summary = await repo.fundSummary();

    expect(summary.totalPiutang, 4750000);
    expect(summary.total, summary.totalPiutang);
    expect(summary.isConsistent, isTrue);
  });

  test('row baru wajib sumber, edit historis null tetap boleh', () async {
    await expectLater(
      repo.savePurchase(p('new', 'c1', 100000, DateTime(2026, 8, 12))),
      throwsArgumentError,
    );
    await expectLater(
      repo.savePayment(pm('new', 'c1', 100000, DateTime(2026, 8, 12))),
      throwsArgumentError,
    );

    final historical = backend.purchases.singleWhere((row) => row.id == 'p1');
    await expectLater(
      repo.savePurchase(historical.copyWith(fundSourceId: () => 'sandi')),
      throwsArgumentError,
    );
    await repo.savePurchase(historical.copyWith(namaBarang: 'HP diperbarui'));
    expect(
      backend.purchases.singleWhere((row) => row.id == 'p1').namaBarang,
      'HP diperbarui',
    );
  });

  test('pembayaran ditolak jika membuat saldo sumber negatif', () async {
    await expectLater(
      repo.savePayment(
        pm(
          'too-much',
          'c1',
          800000,
          DateTime(2026, 8, 12),
          fundSourceId: 'sandi',
        ),
      ),
      throwsStateError,
    );
    expect(backend.payments.any((row) => row.id == 'too-much'), isFalse);
  });

  test('saran sumber pembayaran mengikuti purchase FIFO aktif', () async {
    expect(await repo.suggestedPaymentFundSource('c1'), isNull);
    backend.purchases = [
      for (final row in backend.purchases)
        if (row.id == 'p2') row.copyWith(fundSourceId: () => 'sandi') else row,
    ];

    expect(await repo.suggestedPaymentFundSource('c1'), 'sandi');
  });

  test('alih modal menjaga total sumber dana', () async {
    final transfer = FundTransfer(
      keluar: FundLedgerEntry(
        id: 'out',
        fundSourceId: 'sandi',
        tanggal: DateTime(2026, 8, 24),
        tipe: 'alih_keluar',
        jumlahDelta: -100000,
        referenceType: 'transfer',
        transferGroupId: 'group-1',
        createdAt: t0,
        updatedAt: t0,
      ),
      masuk: FundLedgerEntry(
        id: 'in',
        fundSourceId: 'ika',
        tanggal: DateTime(2026, 8, 24),
        tipe: 'alih_masuk',
        jumlahDelta: 100000,
        referenceType: 'transfer',
        transferGroupId: 'group-1',
        createdAt: t0,
        updatedAt: t0,
      ),
    );

    await repo.transferFund(transfer);

    final summary = await repo.fundSummary();
    expect(summary.bySourceName('Sandi').saldo, 650000);
    expect(summary.bySourceName('Ika').saldo, 4100000);
    expect(summary.total, 4750000);
    expect(summary.isConsistent, isTrue);
    expect(syncRequested, 1);
  });
}
