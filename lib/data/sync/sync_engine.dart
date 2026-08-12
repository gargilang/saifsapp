import '../local/app_database.dart';
import '../models/budget_entry.dart';
import '../models/customer.dart';
import '../models/payment.dart';
import '../models/purchase.dart';
import '../remote/remote_store.dart';
import 'sync_state.dart';

/// Push dirty -> pull delta. Last-write-wins by updated_at server.
/// Push gagal -> exception, flag dirty tetap, dicoba lagi di trigger berikutnya.
class SyncEngine {
  final AppDatabase db;
  final RemoteStore remote;
  final SyncStateStore state;

  SyncEngine(this.db, this.remote, this.state);

  Future<void> syncAll() async {
    await _syncCustomers();
    await _syncPurchases();
    await _syncPayments();
    await _syncBudgetEntries();
  }

  Future<void> _syncCustomers() async {
    final dirty = await db.dirtyCustomerRows();
    if (dirty.isNotEmpty) {
      await remote.upsert('customers', [for (final r in dirty) r.toModel().toJson()]);
      await db.clearCustomersDirty([for (final r in dirty) r.id]);
    }
    await _pull('customers', (rows) => db.applyRemoteCustomers(
        [for (final j in rows) Customer.fromJson(j)]));
  }

  Future<void> _syncPurchases() async {
    final dirty = await db.dirtyPurchaseRows();
    if (dirty.isNotEmpty) {
      await remote.upsert('purchases', [for (final r in dirty) r.toModel().toJson()]);
      await db.clearPurchasesDirty([for (final r in dirty) r.id]);
    }
    await _pull('purchases', (rows) => db.applyRemotePurchases(
        [for (final j in rows) Purchase.fromJson(j)]));
  }

  Future<void> _syncPayments() async {
    final dirty = await db.dirtyPaymentRows();
    if (dirty.isNotEmpty) {
      await remote.upsert('payments', [for (final r in dirty) r.toModel().toJson()]);
      await db.clearPaymentsDirty([for (final r in dirty) r.id]);
    }
    await _pull('payments', (rows) => db.applyRemotePayments(
        [for (final j in rows) Payment.fromJson(j)]));
  }

  Future<void> _syncBudgetEntries() async {
    final dirty = await db.dirtyBudgetEntryRows();
    if (dirty.isNotEmpty) {
      await remote.upsert(
          'budget_entries', [for (final r in dirty) r.toModel().toJson()]);
      await db.clearBudgetEntriesDirty([for (final r in dirty) r.id]);
    }
    await _pull('budget_entries', (rows) => db.applyRemoteBudgetEntries(
        [for (final j in rows) BudgetEntry.fromJson(j)]));
  }

  Future<void> _pull(String table,
      Future<void> Function(List<Map<String, dynamic>>) apply) async {
    final since = await state.lastPull(table);
    final started = DateTime.now().toUtc();
    final rows = await remote.fetchSince(table, since);
    await apply(rows);
    await state.setLastPull(table, started);
  }
}
