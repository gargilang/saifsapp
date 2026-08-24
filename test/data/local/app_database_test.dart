import 'package:flutter_test/flutter_test.dart';
import 'package:sandiapp/data/local/app_database.dart';
import 'package:sandiapp/data/models/customer.dart';
import 'package:sandiapp/data/models/fund_ledger_entry.dart';
import 'package:sandiapp/data/models/fund_source.dart';
import 'package:sandiapp/data/models/payment.dart';
import 'package:sandiapp/data/models/purchase.dart';

void main() {
  late AppDatabase db;
  final t0 = DateTime.utc(2026, 8, 8, 10);

  setUp(() => db = AppDatabase.memory());
  tearDown(() => db.close());

  test('upsert + baca aktif + dirty flag', () async {
    final c = Customer(id: 'c1', nama: 'WIWIK', createdAt: t0, updatedAt: t0);
    await db.upsertCustomerRow(c.toCompanion(dirty: true));
    expect((await db.activeCustomers()).single.nama, 'WIWIK');
    expect((await db.dirtyCustomerRows()).single.id, 'c1');
    expect(await db.dirtyCount(), 1);

    await db.clearCustomersDirty(['c1']);
    expect(await db.dirtyCount(), 0);
  });

  test(
    'soft delete menghilangkan dari activeCustomers tapi tetap bisa di-push',
    () async {
      final c = Customer(
        id: 'c1',
        nama: 'A',
        createdAt: t0,
        updatedAt: t0,
        deletedAt: t0.add(const Duration(days: 1)),
      );
      await db.upsertCustomerRow(c.toCompanion(dirty: true));
      expect(await db.activeCustomers(), isEmpty);
      expect((await db.dirtyCustomerRows()).single.deletedAt, isNotNull);
    },
  );

  test('applyRemote menulis tanpa dirty', () async {
    await db.applyRemotePayments([
      Payment(
        id: 'm1',
        customerId: 'c1',
        jumlah: 50000,
        tanggalBayar: DateTime(2026, 8, 1),
        createdAt: t0,
        updatedAt: t0,
      ),
    ]);
    expect((await db.activePayments()).single.jumlah, 50000);
    expect(await db.dirtyCount(), 0);
  });

  test('fund source dan ledger roundtrip + dirty count', () async {
    final sandi = FundSource(
      id: 'sandi',
      nama: 'Sandi',
      colorKey: 'green',
      createdAt: t0,
      updatedAt: t0,
    );
    final opening = FundLedgerEntry(
      id: 'opening-sandi',
      fundSourceId: sandi.id,
      tanggal: DateTime(2026, 8, 24),
      tipe: 'saldo_awal',
      jumlahDelta: 36100000,
      referenceType: 'migration',
      createdAt: t0,
      updatedAt: t0,
    );

    await db.upsertFundSourceRow(sandi.toCompanion(dirty: true));
    await db.upsertFundLedgerEntryRow(opening.toCompanion(dirty: true));

    expect((await db.activeFundSources()).single.nama, 'Sandi');
    expect((await db.activeFundLedgerEntries()).single.jumlahDelta, 36100000);
    expect(await db.dirtyCount(), 2);
  });

  test('fundSourceId purchase dan payment tersimpan', () async {
    final purchase = Purchase(
      id: 'p1',
      customerId: 'c1',
      namaBarang: 'HP',
      hargaJual: 2000000,
      tanggalBeli: DateTime(2026, 8, 24),
      fundSourceId: 'sandi',
      createdAt: t0,
      updatedAt: t0,
    );
    final payment = Payment(
      id: 'm1',
      customerId: 'c1',
      jumlah: 500000,
      tanggalBayar: DateTime(2026, 8, 24),
      fundSourceId: 'sandi',
      createdAt: t0,
      updatedAt: t0,
    );

    await db.upsertPurchaseRow(purchase.toCompanion(dirty: false));
    await db.upsertPaymentRow(payment.toCompanion(dirty: false));

    expect((await db.activePurchases()).single.toModel().fundSourceId, 'sandi');
    expect((await db.activePayments()).single.toModel().fundSourceId, 'sandi');
  });

  test('writeFundTransferAtomic menulis dua delta satu group', () async {
    final transfer = FundTransfer(
      keluar: FundLedgerEntry(
        id: 'out',
        fundSourceId: 'sandi',
        tanggal: DateTime(2026, 8, 24),
        tipe: 'alih_keluar',
        jumlahDelta: -1000000,
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
        jumlahDelta: 1000000,
        referenceType: 'transfer',
        transferGroupId: 'group-1',
        createdAt: t0,
        updatedAt: t0,
      ),
    );

    await db.writeFundTransferAtomic(transfer);

    final rows = await db.activeFundLedgerEntries();
    expect(
      rows.map((row) => row.jumlahDelta),
      containsAll([-1000000, 1000000]),
    );
    expect(rows.map((row) => row.transferGroupId).toSet(), {'group-1'});
    expect(await db.dirtyCount(), 2);
  });
}
