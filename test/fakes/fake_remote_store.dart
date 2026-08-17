import 'package:sandiapp/data/remote/remote_store.dart';

class FakeRemoteStore implements RemoteStore {
  final Map<String, Map<String, Map<String, dynamic>>> tables = {};
  int upsertCalls = 0;
  DateTime Function() clock = () => DateTime.now().toUtc();

  @override
  Future<List<Map<String, dynamic>>> fetchSince(String table, DateTime? since) async {
    final rows = (tables[table] ?? {}).values;
    if (since == null) return [for (final r in rows) Map<String, dynamic>.from(r)];
    return [
      for (final r in rows)
        if (DateTime.parse(r['updated_at'] as String).isAfter(since))
          Map<String, dynamic>.from(r),
    ];
  }

  @override
  Future<void> upsert(String table, List<Map<String, dynamic>> rows) async {
    upsertCalls++;
    final t = tables.putIfAbsent(table, () => {});
    for (final row in rows) {
      // simulasi trigger set_updated_at di server
      t[row['id'] as String] = {...row, 'updated_at': clock().toIso8601String()};
    }
  }

  @override
  Future<void> update(String table, String id, Map<String, dynamic> values) async {
    final t = tables.putIfAbsent(table, () => {});
    final existing = t[id];
    if (existing == null) return; // row tidak ada: no-op (0 rows affected)
    t[id] = {...existing, ...values, 'updated_at': clock().toIso8601String()};
  }

  @override
  Future<void> updateByCustomer(
      String table, String customerId, Map<String, dynamic> values) async {
    final t = tables.putIfAbsent(table, () => {});
    for (final entry in t.entries.toList()) {
      if (entry.value['customer_id'] == customerId) {
        t[entry.key] = {
          ...entry.value,
          ...values,
          'updated_at': clock().toIso8601String(),
        };
      }
    }
  }

  @override
  Future<Map<String, dynamic>> callFunction(
    String name, {
    String method = 'POST',
    Map<String, dynamic>? body,
  }) async {
    throw UnimplementedError('callFunction tidak dipakai di test ini');
  }
}
