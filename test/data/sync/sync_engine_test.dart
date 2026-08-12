import 'package:flutter_test/flutter_test.dart';
import 'package:sandiapp/data/local/app_database.dart';
import 'package:sandiapp/data/models/customer.dart';
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
    engine = SyncEngine(db, remote, SyncStateStore(await SharedPreferences.getInstance()));
  });
  tearDown(() => db.close());

  test('push: row dirty terkirim ke remote & flag dibersihkan', () async {
    await db.upsertCustomerRow(
        Customer(id: 'c1', nama: 'WIWIK', createdAt: t0, updatedAt: t0)
            .toCompanion(dirty: true));
    await engine.syncAll();
    expect(remote.tables['customers']!['c1']!['nama'], 'WIWIK');
    expect(await db.dirtyCount(), 0);
  });

  test('pull: perubahan remote masuk ke lokal tanpa dirty', () async {
    await engine.syncAll(); // watermark awal
    remote.clock = () => DateTime.now().toUtc().add(const Duration(seconds: 1));
    await remote.upsert('customers', [
      Customer(id: 'c9', nama: 'DARI SERVER', createdAt: t0, updatedAt: t0).toJson()
    ]);
    await engine.syncAll();
    expect((await db.activeCustomers()).single.nama, 'DARI SERVER');
    expect(await db.dirtyCount(), 0);
  });

  test('soft delete lokal ikut ter-push', () async {
    await db.upsertCustomerRow(Customer(
            id: 'c1', nama: 'A', createdAt: t0, updatedAt: t0,
            deletedAt: t0.add(const Duration(days: 1)))
        .toCompanion(dirty: true));
    await engine.syncAll();
    expect(remote.tables['customers']!['c1']!['deleted_at'], isNotNull);
  });

  test('pull kedua tidak push apapun (tidak ada dirty)', () async {
    await engine.syncAll();
    final calls = remote.upsertCalls;
    await engine.syncAll();
    expect(remote.upsertCalls, calls);
  });
}
