import '../models/budget_entry.dart';
import '../models/customer.dart';
import '../models/payment.dart';
import '../models/purchase.dart';
import '../repositories/backend.dart';
import 'remote_store.dart';

/// Backend web: langsung Supabase, tanpa antrean sync.
class RemoteBackend implements Backend {
  final RemoteStore remote;
  RemoteBackend(this.remote);

  Future<List<T>> _read<T>(
          String table, T Function(Map<String, dynamic>) fromJson) async =>
      [
        for (final j in await remote.fetchSince(table, null))
          if (j['deleted_at'] == null) fromJson(j),
      ];

  @override
  Future<List<Customer>> readCustomers() => _read('customers', Customer.fromJson);
  @override
  Future<List<Purchase>> readPurchases() => _read('purchases', Purchase.fromJson);
  @override
  Future<List<Payment>> readPayments() => _read('payments', Payment.fromJson);
  @override
  Future<List<BudgetEntry>> readBudgetEntries() =>
      _read('budget_entries', BudgetEntry.fromJson);

  @override
  Future<void> writeCustomer(Customer v) => remote.upsert('customers', [v.toJson()]);
  @override
  Future<void> writePurchase(Purchase v) => remote.upsert('purchases', [v.toJson()]);
  @override
  Future<void> writePayment(Payment v) => remote.upsert('payments', [v.toJson()]);
  @override
  Future<void> writeBudgetEntry(BudgetEntry v) =>
      remote.upsert('budget_entries', [v.toJson()]);

  /// Soft delete: UPDATE saja, jangan upsert.
  /// Upsert dengan payload parsial bisa berubah jadi INSERT kalau row tidak
  /// ditemukan (mis. karena RLS), lalu gagal karena kolom NOT NULL lain
  /// (mis. `nama`) tidak disertakan.
  Future<void> _delete(String table, String id, DateTime at) =>
      remote.update(table, id, {
        'deleted_at': at.toIso8601String(),
        'updated_at': at.toIso8601String(),
      });

  @override
  Future<void> deleteCustomer(String id, DateTime at) => _delete('customers', id, at);

  @override
  Future<void> deleteCustomerCascade(String id, DateTime at) async {
    await _delete('customers', id, at);
    await remote.updateByCustomer('purchases', id, {
      'deleted_at': at.toIso8601String(),
      'updated_at': at.toIso8601String(),
    });
    await remote.updateByCustomer('payments', id, {
      'deleted_at': at.toIso8601String(),
      'updated_at': at.toIso8601String(),
    });
  }

  @override
  Future<void> deletePurchase(String id, DateTime at) => _delete('purchases', id, at);
  @override
  Future<void> deletePayment(String id, DateTime at) => _delete('payments', id, at);
  @override
  Future<void> deleteBudgetEntry(String id, DateTime at) =>
      _delete('budget_entries', id, at);
}
