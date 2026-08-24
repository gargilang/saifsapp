import 'package:flutter_test/flutter_test.dart';
import 'package:sandiapp/data/local/app_database.dart';
import 'package:sandiapp/data/models/customer.dart';
import 'package:sandiapp/data/models/fund_ledger_entry.dart';
import 'package:sandiapp/data/models/fund_source.dart';
import 'package:sandiapp/data/sync/sync_engine.dart';
import 'package:sandiapp/data/sync/sync_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../fakes/fake_remote_store.dart';

void main() {
  late AppDatabase db;
  late FakeRemoteStore remote;
  late SyncEngine engine;
  final t0 = DateTime.utc(2026, 8, 8, 10);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.memory();
    remote = FakeRemoteStore();
    engine = SyncEngine(
      db,
      remote,
      SyncStateStore(await SharedPreferences.getInstance()),
    );
  });
  tearDown(() => db.close());

  test('push: row dirty terkirim ke remote & flag dibersihkan', () async {
    await db.upsertCustomerRow(
      Customer(
        id: 'c1',
        nama: 'WIWIK',
        createdAt: t0,
        updatedAt: t0,
      ).toCompanion(dirty: true),
    );
    await engine.syncAll();
    expect(remote.tables['customers']!['c1']!['nama'], 'WIWIK');
    expect(await db.dirtyCount(), 0);
  });

  test('pull: perubahan remote masuk ke lokal tanpa dirty', () async {
    await engine.syncAll(); // watermark awal
    remote.clock = () => DateTime.now().toUtc().add(const Duration(seconds: 1));
    await remote.upsert('customers', [
      Customer(
        id: 'c9',
        nama: 'DARI SERVER',
        createdAt: t0,
        updatedAt: t0,
      ).toJson(),
    ]);
    await engine.syncAll();
    expect((await db.activeCustomers()).single.nama, 'DARI SERVER');
    expect(await db.dirtyCount(), 0);
  });

  test('soft delete lokal ikut ter-push', () async {
    await db.upsertCustomerRow(
      Customer(
        id: 'c1',
        nama: 'A',
        createdAt: t0,
        updatedAt: t0,
        deletedAt: t0.add(const Duration(days: 1)),
      ).toCompanion(dirty: true),
    );
    await engine.syncAll();
    expect(remote.tables['customers']!['c1']!['deleted_at'], isNotNull);
  });

  test('pull kedua tidak push apapun (tidak ada dirty)', () async {
    await engine.syncAll();
    final calls = remote.upsertCalls;
    await engine.syncAll();
    expect(remote.upsertCalls, calls);
  });

  test(
    'pull menarik baris yang updated_at < now klien tapi > watermark lama',
    () async {
      // Regresi bug: data ditulis di server pada t=10:00, lalu Android sync pada
      // t=12:00. Watermark tidak boleh melompat ke 12:00 dan menelan data 10:00.
      final state = SyncStateStore(await SharedPreferences.getInstance());
      final engine2 = SyncEngine(db, remote, state);

      // Sync pertama pada waktu awal (belum ada data) -> watermark tetap null
      // karena tidak ada baris.
      await engine2.syncAll();
      expect(await state.lastPull('customers'), isNull);

      // Server punya baris dengan updated_at lama (sebelum "sekarang" klien).
      remote.tables['customers'] = {
        'c1': Customer(
          id: 'c1',
          nama: 'DARI WEB',
          createdAt: t0,
          updatedAt: t0,
        ).toJson(),
      };

      // Sync kedua: klien-nya "sekarang" jauh setelah t0. Data t0 harus tetap masuk.
      await engine2.syncAll();
      expect((await db.activeCustomers()).single.nama, 'DARI WEB');
    },
  );

  test(
    'watermark tersimpan = max(updated_at) baris yang ditarik, bukan now',
    () async {
      final state = SyncStateStore(await SharedPreferences.getInstance());
      final engine2 = SyncEngine(db, remote, state);

      final tA = DateTime.utc(2026, 8, 10, 9);
      final tB = DateTime.utc(2026, 8, 10, 11);
      remote.tables['customers'] = {
        'a': Customer(
          id: 'a',
          nama: 'A',
          createdAt: tA,
          updatedAt: tA,
        ).toJson(),
        'b': Customer(
          id: 'b',
          nama: 'B',
          createdAt: tB,
          updatedAt: tB,
        ).toJson(),
      };

      await engine2.syncAll();

      expect(await state.lastPull('customers'), tB);
    },
  );

  test('pull tanpa baris tidak memajukan watermark', () async {
    final state = SyncStateStore(await SharedPreferences.getInstance());
    final engine2 = SyncEngine(db, remote, state);

    final tA = DateTime.utc(2026, 8, 10, 9);
    remote.tables['customers'] = {
      'a': Customer(id: 'a', nama: 'A', createdAt: tA, updatedAt: tA).toJson(),
    };
    await engine2.syncAll();
    expect(await state.lastPull('customers'), tA);

    // Sync lagi tanpa data baru: watermark tetap tA (tidak maju ke now).
    await engine2.syncAll();
    expect(await state.lastPull('customers'), tA);
  });

  test(
    'resyncAll menarik ulang semua baris meski watermark sudah maju',
    () async {
      final state = SyncStateStore(await SharedPreferences.getInstance());
      final engine2 = SyncEngine(db, remote, state);

      final tA = DateTime.utc(2026, 8, 10, 9);
      remote.tables['customers'] = {
        'a': Customer(
          id: 'a',
          nama: 'A',
          createdAt: tA,
          updatedAt: tA,
        ).toJson(),
      };
      await engine2.syncAll();
      // Hapus lokal untuk simulasi "data hilang".
      await db.delete(db.customers).go();
      expect(await db.activeCustomers(), isEmpty);

      // Full resync harus menarik ulang meski watermark sudah di tA.
      await engine2.resyncAll();
      expect((await db.activeCustomers()).single.nama, 'A');
    },
  );

  test('SyncStateStore.clearAll menghapus watermark', () async {
    final state = SyncStateStore(await SharedPreferences.getInstance());
    await state.setLastPull('customers', DateTime.utc(2026, 8, 10));
    await state.setLastPull('purchases', DateTime.utc(2026, 8, 10));

    await state.clearAll([
      'customers',
      'purchases',
      'payments',
      'budget_entries',
    ]);

    expect(await state.lastPull('customers'), isNull);
    expect(await state.lastPull('purchases'), isNull);
  });

  test('sync sumber sebelum purchase dan ledger sesudah payment', () async {
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

    await engine.syncAll();

    expect(
      remote.tableOrder,
      containsAllInOrder([
        'fund_sources',
        'customers',
        'purchases',
        'payments',
        'fund_ledger_entries',
        'budget_entries',
      ]),
    );
    expect(remote.tables['fund_sources']!['sandi']!['nama'], 'Sandi');
    expect(
      remote.tables['fund_ledger_entries']!['opening-sandi']!['jumlah_delta'],
      36100000,
    );
    expect(await db.dirtyCount(), 0);
  });

  test('resyncAll mengelola watermark tabel sumber dana', () async {
    final state = SyncStateStore(await SharedPreferences.getInstance());
    final source = FundSource(
      id: 'ika',
      nama: 'Ika',
      colorKey: 'gold',
      createdAt: t0,
      updatedAt: t0,
    );
    remote.tables['fund_sources'] = {'ika': source.toJson()};

    await SyncEngine(db, remote, state).resyncAll();

    expect(await state.lastPull('fund_sources'), t0);
    expect((await db.activeFundSources()).single.nama, 'Ika');
  });
}
