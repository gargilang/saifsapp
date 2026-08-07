import 'package:drift/drift.dart' show Value;

import '../models/budget_entry.dart';
import '../models/customer.dart';
import '../models/payment.dart';
import '../models/purchase.dart';
import '../repositories/backend.dart';
import 'app_database.dart';

/// Backend Android: SQLite lokal, semua tulis ditandai dirty untuk sync.
class DriftBackend implements Backend {
  final AppDatabase db;
  DriftBackend(this.db);

  @override
  Future<List<Customer>> readCustomers() async =>
      [for (final r in await db.activeCustomers()) r.toModel()];
  @override
  Future<List<Purchase>> readPurchases() async =>
      [for (final r in await db.activePurchases()) r.toModel()];
  @override
  Future<List<Payment>> readPayments() async =>
      [for (final r in await db.activePayments()) r.toModel()];
  @override
  Future<List<BudgetEntry>> readBudgetEntries() async =>
      [for (final r in await db.activeBudgetEntries()) r.toModel()];

  @override
  Future<void> writeCustomer(Customer v) => db.upsertCustomerRow(v.toCompanion(dirty: true));
  @override
  Future<void> writePurchase(Purchase v) => db.upsertPurchaseRow(v.toCompanion(dirty: true));
  @override
  Future<void> writePayment(Payment v) => db.upsertPaymentRow(v.toCompanion(dirty: true));
  @override
  Future<void> writeBudgetEntry(BudgetEntry v) =>
      db.upsertBudgetEntryRow(v.toCompanion(dirty: true));

  @override
  Future<void> deleteCustomer(String id, DateTime at) => db.upsertCustomerRow(
      CustomersCompanion(id: Value(id), deletedAt: Value(at),
          updatedAt: Value(at), isDirty: const Value(true)));
  @override
  Future<void> deletePurchase(String id, DateTime at) => db.upsertPurchaseRow(
      PurchasesCompanion(id: Value(id), deletedAt: Value(at),
          updatedAt: Value(at), isDirty: const Value(true)));
  @override
  Future<void> deletePayment(String id, DateTime at) => db.upsertPaymentRow(
      PaymentsCompanion(id: Value(id), deletedAt: Value(at),
          updatedAt: Value(at), isDirty: const Value(true)));
  @override
  Future<void> deleteBudgetEntry(String id, DateTime at) => db.upsertBudgetEntryRow(
      BudgetEntriesCompanion(id: Value(id), deletedAt: Value(at),
          updatedAt: Value(at), isDirty: const Value(true)));
}
