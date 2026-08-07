import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../models/budget_entry.dart';
import '../models/customer.dart';
import '../models/payment.dart';
import '../models/purchase.dart';

part 'app_database.g.dart';

@DataClassName('CustomerRow')
class Customers extends Table {
  TextColumn get id => text()();
  TextColumn get nama => text()();
  TextColumn get noHp => text().nullable()();
  TextColumn get alamat => text().nullable()();
  TextColumn get catatan => text().nullable()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  TextColumn get authUserId => text().nullable()();
  TextColumn get createdBy => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get isDirty => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PurchaseRow')
class Purchases extends Table {
  TextColumn get id => text()();
  TextColumn get customerId => text()();
  TextColumn get namaBarang => text()();
  IntColumn get hargaJual => integer()();
  IntColumn get hargaBeli => integer().nullable()();
  DateTimeColumn get tanggalBeli => dateTime()();
  TextColumn get catatan => text().nullable()();
  TextColumn get createdBy => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get isDirty => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PaymentRow')
class Payments extends Table {
  TextColumn get id => text()();
  TextColumn get customerId => text()();
  IntColumn get jumlah => integer()();
  DateTimeColumn get tanggalBayar => dateTime()();
  TextColumn get metode => text().withDefault(const Constant('tunai'))();
  TextColumn get catatan => text().nullable()();
  TextColumn get sumber => text().withDefault(const Constant('admin'))();
  TextColumn get statusVerifikasi => text().withDefault(const Constant('verified'))();
  TextColumn get buktiFotoUrl => text().nullable()();
  TextColumn get createdBy => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get isDirty => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('BudgetEntryRow')
class BudgetEntries extends Table {
  TextColumn get id => text()();
  DateTimeColumn get tanggal => dateTime()();
  TextColumn get namaTransaksi => text()();
  TextColumn get tipe => text()();
  IntColumn get jumlah => integer()();
  TextColumn get catatan => text().nullable()();
  TextColumn get createdBy => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get isDirty => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Customers, Purchases, Payments, BudgetEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'sandiapp'));
  AppDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

  // ---- customers ----
  Future<List<CustomerRow>> activeCustomers() =>
      (select(customers)..where((t) => t.deletedAt.isNull())).get();
  Future<void> upsertCustomerRow(CustomersCompanion c) =>
      into(customers).insertOnConflictUpdate(c);
  Future<List<CustomerRow>> dirtyCustomerRows() =>
      (select(customers)..where((t) => t.isDirty)).get();
  Future<void> clearCustomersDirty(List<String> ids) =>
      (update(customers)..where((t) => t.id.isIn(ids)))
          .write(const CustomersCompanion(isDirty: Value(false)));
  Future<void> applyRemoteCustomers(List<Customer> items) async =>
      batch((b) => b.insertAllOnConflictUpdate(
          customers, [for (final c in items) c.toCompanion(dirty: false)]));

  // ---- purchases ----
  Future<List<PurchaseRow>> activePurchases() =>
      (select(purchases)..where((t) => t.deletedAt.isNull())).get();
  Future<void> upsertPurchaseRow(PurchasesCompanion c) =>
      into(purchases).insertOnConflictUpdate(c);
  Future<List<PurchaseRow>> dirtyPurchaseRows() =>
      (select(purchases)..where((t) => t.isDirty)).get();
  Future<void> clearPurchasesDirty(List<String> ids) =>
      (update(purchases)..where((t) => t.id.isIn(ids)))
          .write(const PurchasesCompanion(isDirty: Value(false)));
  Future<void> applyRemotePurchases(List<Purchase> items) async =>
      batch((b) => b.insertAllOnConflictUpdate(
          purchases, [for (final p in items) p.toCompanion(dirty: false)]));

  // ---- payments ----
  Future<List<PaymentRow>> activePayments() =>
      (select(payments)..where((t) => t.deletedAt.isNull())).get();
  Future<void> upsertPaymentRow(PaymentsCompanion c) =>
      into(payments).insertOnConflictUpdate(c);
  Future<List<PaymentRow>> dirtyPaymentRows() =>
      (select(payments)..where((t) => t.isDirty)).get();
  Future<void> clearPaymentsDirty(List<String> ids) =>
      (update(payments)..where((t) => t.id.isIn(ids)))
          .write(const PaymentsCompanion(isDirty: Value(false)));
  Future<void> applyRemotePayments(List<Payment> items) async =>
      batch((b) => b.insertAllOnConflictUpdate(
          payments, [for (final p in items) p.toCompanion(dirty: false)]));

  // ---- budget_entries ----
  Future<List<BudgetEntryRow>> activeBudgetEntries() =>
      (select(budgetEntries)..where((t) => t.deletedAt.isNull())).get();
  Future<void> upsertBudgetEntryRow(BudgetEntriesCompanion c) =>
      into(budgetEntries).insertOnConflictUpdate(c);
  Future<List<BudgetEntryRow>> dirtyBudgetEntryRows() =>
      (select(budgetEntries)..where((t) => t.isDirty)).get();
  Future<void> clearBudgetEntriesDirty(List<String> ids) =>
      (update(budgetEntries)..where((t) => t.id.isIn(ids)))
          .write(const BudgetEntriesCompanion(isDirty: Value(false)));
  Future<void> applyRemoteBudgetEntries(List<BudgetEntry> items) async =>
      batch((b) => b.insertAllOnConflictUpdate(
          budgetEntries, [for (final e in items) e.toCompanion(dirty: false)]));

  Future<int> dirtyCount() async {
    Future<int> count(String table) async =>
        (await customSelect('SELECT COUNT(*) AS c FROM $table WHERE is_dirty = 1')
                .getSingle())
            .data['c'] as int;
    return await count('customers') +
        await count('purchases') +
        await count('payments') +
        await count('budget_entries');
  }
}

// ---- mapper row <-> model ----
extension CustomerRowX on CustomerRow {
  Customer toModel() => Customer(
      id: id, nama: nama, noHp: noHp, alamat: alamat, catatan: catatan,
      isArchived: isArchived, authUserId: authUserId, createdBy: createdBy,
      createdAt: createdAt, updatedAt: updatedAt, deletedAt: deletedAt);
}

extension CustomerX on Customer {
  CustomersCompanion toCompanion({required bool dirty}) => CustomersCompanion(
      id: Value(id), nama: Value(nama), noHp: Value(noHp), alamat: Value(alamat),
      catatan: Value(catatan), isArchived: Value(isArchived),
      authUserId: Value(authUserId), createdBy: Value(createdBy),
      createdAt: Value(createdAt), updatedAt: Value(updatedAt),
      deletedAt: Value(deletedAt), isDirty: Value(dirty));
}

extension PurchaseRowX on PurchaseRow {
  Purchase toModel() => Purchase(
      id: id, customerId: customerId, namaBarang: namaBarang, hargaJual: hargaJual,
      hargaBeli: hargaBeli, tanggalBeli: tanggalBeli, catatan: catatan,
      createdBy: createdBy, createdAt: createdAt, updatedAt: updatedAt,
      deletedAt: deletedAt);
}

extension PurchaseX on Purchase {
  PurchasesCompanion toCompanion({required bool dirty}) => PurchasesCompanion(
      id: Value(id), customerId: Value(customerId), namaBarang: Value(namaBarang),
      hargaJual: Value(hargaJual), hargaBeli: Value(hargaBeli),
      tanggalBeli: Value(tanggalBeli), catatan: Value(catatan),
      createdBy: Value(createdBy), createdAt: Value(createdAt),
      updatedAt: Value(updatedAt), deletedAt: Value(deletedAt),
      isDirty: Value(dirty));
}

extension PaymentRowX on PaymentRow {
  Payment toModel() => Payment(
      id: id, customerId: customerId, jumlah: jumlah, tanggalBayar: tanggalBayar,
      metode: metode, catatan: catatan, sumber: sumber,
      statusVerifikasi: statusVerifikasi, buktiFotoUrl: buktiFotoUrl,
      createdBy: createdBy, createdAt: createdAt, updatedAt: updatedAt,
      deletedAt: deletedAt);
}

extension PaymentX on Payment {
  PaymentsCompanion toCompanion({required bool dirty}) => PaymentsCompanion(
      id: Value(id), customerId: Value(customerId), jumlah: Value(jumlah),
      tanggalBayar: Value(tanggalBayar), metode: Value(metode),
      catatan: Value(catatan), sumber: Value(sumber),
      statusVerifikasi: Value(statusVerifikasi), buktiFotoUrl: Value(buktiFotoUrl),
      createdBy: Value(createdBy), createdAt: Value(createdAt),
      updatedAt: Value(updatedAt), deletedAt: Value(deletedAt),
      isDirty: Value(dirty));
}

extension BudgetEntryRowX on BudgetEntryRow {
  BudgetEntry toModel() => BudgetEntry(
      id: id, tanggal: tanggal, namaTransaksi: namaTransaksi, tipe: tipe,
      jumlah: jumlah, catatan: catatan, createdBy: createdBy,
      createdAt: createdAt, updatedAt: updatedAt, deletedAt: deletedAt);
}

extension BudgetEntryX on BudgetEntry {
  BudgetEntriesCompanion toCompanion({required bool dirty}) =>
      BudgetEntriesCompanion(
          id: Value(id), tanggal: Value(tanggal),
          namaTransaksi: Value(namaTransaksi), tipe: Value(tipe),
          jumlah: Value(jumlah), catatan: Value(catatan),
          createdBy: Value(createdBy), createdAt: Value(createdAt),
          updatedAt: Value(updatedAt), deletedAt: Value(deletedAt),
          isDirty: Value(dirty));
}
