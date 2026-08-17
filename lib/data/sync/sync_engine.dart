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

  /// Semua tabel yang disinkronkan (dipakai resyncAll untuk reset watermark).
  static const tables = ['customers', 'purchases', 'payments', 'budget_entries'];

  Future<void> syncAll() async {
    await _syncCustomers();
    await _syncPurchases();
    await _syncPayments();
    await _syncBudgetEntries();
  }

  /// Sinkron ulang penuh: kosongkan semua watermark lalu tarik semua data.
  /// Jaring pengaman jika ada data yang tertinggal tanpa perlu reinstall.
  Future<void> resyncAll() async {
    await state.clearAll(tables);
    await syncAll();
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
    final rows = await remote.fetchSince(table, since);
    await apply(rows);
    // Watermark = max(updated_at) server dari baris yang benar-benar ditarik.
    // JANGAN pakai DateTime.now() klien: jam klien bisa maju dari updated_at
    // server sehingga data yang ditulis dari sisi lain (mis. web) terlewat
    // permanen. Tanpa baris, watermark tidak dimajukan.
    final maxUpdated = _maxUpdatedAt(rows);
    if (maxUpdated != null) {
      await state.setLastPull(table, maxUpdated);
    }
  }

  DateTime? _maxUpdatedAt(List<Map<String, dynamic>> rows) {
    DateTime? max;
    for (final r in rows) {
      final raw = r['updated_at'];
      if (raw == null) continue;
      final t = DateTime.parse(raw as String).toUtc();
      if (max == null || t.isAfter(max)) max = t;
    }
    return max;
  }
}
