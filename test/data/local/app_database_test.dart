import 'package:flutter_test/flutter_test.dart';
import 'package:sandiapp/data/local/app_database.dart';
import 'package:sandiapp/data/models/customer.dart';
import 'package:sandiapp/data/models/payment.dart';

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

  test('soft delete menghilangkan dari activeCustomers tapi tetap bisa di-push', () async {
    final c = Customer(id: 'c1', nama: 'A', createdAt: t0, updatedAt: t0,
        deletedAt: t0.add(const Duration(days: 1)));
    await db.upsertCustomerRow(c.toCompanion(dirty: true));
    expect(await db.activeCustomers(), isEmpty);
    expect((await db.dirtyCustomerRows()).single.deletedAt, isNotNull);
  });

  test('applyRemote menulis tanpa dirty', () async {
    await db.applyRemotePayments([
      Payment(id: 'm1', customerId: 'c1', jumlah: 50000,
          tanggalBayar: DateTime(2026, 8, 1), createdAt: t0, updatedAt: t0),
    ]);
    expect((await db.activePayments()).single.jumlah, 50000);
    expect(await db.dirtyCount(), 0);
  });
}
