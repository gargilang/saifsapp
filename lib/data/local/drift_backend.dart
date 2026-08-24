import '../models/budget_entry.dart';
import '../models/customer.dart';
import '../models/fund_ledger_entry.dart';
import '../models/fund_source.dart';
import '../models/payment.dart';
import '../models/purchase.dart';
import '../repositories/backend.dart';
import 'app_database.dart';

/// Backend Android: SQLite lokal, semua tulis ditandai dirty untuk sync.
class DriftBackend implements Backend {
  final AppDatabase db;
  DriftBackend(this.db);

  @override
  Future<List<Customer>> readCustomers() async => [
    for (final r in await db.activeCustomers()) r.toModel(),
  ];
  @override
  Future<List<Purchase>> readPurchases() async => [
    for (final r in await db.activePurchases()) r.toModel(),
  ];
  @override
  Future<List<Payment>> readPayments() async => [
    for (final r in await db.activePayments()) r.toModel(),
  ];
  @override
  Future<List<BudgetEntry>> readBudgetEntries() async => [
    for (final r in await db.activeBudgetEntries()) r.toModel(),
  ];
  @override
  Future<List<FundSource>> readFundSources() async => [
    for (final row in await db.activeFundSources()) row.toModel(),
  ];
  @override
  Future<List<FundLedgerEntry>> readFundLedgerEntries() async => [
    for (final row in await db.activeFundLedgerEntries()) row.toModel(),
  ];

  @override
  Future<void> writeCustomer(Customer v) =>
      db.upsertCustomerRow(v.toCompanion(dirty: true));
  @override
  Future<void> writePurchase(Purchase v) =>
      db.upsertPurchaseRow(v.toCompanion(dirty: true));
  @override
  Future<void> writePayment(Payment v) =>
      db.upsertPaymentRow(v.toCompanion(dirty: true));
  @override
  Future<void> writeBudgetEntry(BudgetEntry v) =>
      db.upsertBudgetEntryRow(v.toCompanion(dirty: true));
  @override
  Future<void> writeFundTransfer(FundTransfer transfer) =>
      db.writeFundTransferAtomic(transfer);

  @override
  Future<void> deleteCustomer(String id, DateTime at) =>
      db.softDeleteCustomerRow(id, at);

  @override
  Future<void> deleteCustomerCascade(String id, DateTime at) async {
    await db.softDeleteCustomerRow(id, at);
    await db.softDeletePurchasesByCustomer(id, at);
    await db.softDeletePaymentsByCustomer(id, at);
  }

  @override
  Future<void> deletePurchase(String id, DateTime at) =>
      db.softDeletePurchaseRow(id, at);
  @override
  Future<void> deletePayment(String id, DateTime at) =>
      db.softDeletePaymentRow(id, at);
  @override
  Future<void> deleteBudgetEntry(String id, DateTime at) =>
      db.softDeleteBudgetEntryRow(id, at);
}
