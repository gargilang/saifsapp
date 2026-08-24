import 'package:sandiapp/data/remote/remote_store.dart';

class FakeRemoteStore implements RemoteStore {
  final Map<String, Map<String, Map<String, dynamic>>> tables = {};
  int upsertCalls = 0;
  final List<String> tableOrder = [];
  DateTime Function() clock = () => DateTime.now().toUtc();

  @override
  Future<List<Map<String, dynamic>>> fetchSince(
    String table,
    DateTime? since,
  ) async {
    tableOrder.add(table);
    final rows = (tables[table] ?? {}).values;
    if (since == null) {
      return [for (final row in rows) Map<String, dynamic>.from(row)];
    }
    return [
      for (final r in rows)
        if (DateTime.parse(r['updated_at'] as String).isAfter(since))
          Map<String, dynamic>.from(r),
    ];
  }

  @override
  Future<void> upsert(String table, List<Map<String, dynamic>> rows) async {
    tableOrder.add(table);
    upsertCalls++;
    final t = tables.putIfAbsent(table, () => {});
    for (final row in rows) {
      // simulasi trigger set_updated_at di server
      t[row['id'] as String] = {
        ...row,
        'updated_at': clock().toIso8601String(),
      };
    }
  }

  @override
  Future<Map<String, dynamic>> rpc(
    String name,
    Map<String, dynamic> params,
  ) async {
    if (name != 'record_fund_transfer') {
      throw UnimplementedError('RPC $name tidak dipakai di test ini');
    }
    final groupId = params['p_group_id'] as String;
    final ledger = tables.putIfAbsent('fund_ledger_entries', () => {});
    if (ledger.values.any((row) => row['transfer_group_id'] == groupId)) {
      return {'transfer_group_id': groupId, 'amount': params['p_amount']};
    }
    final timestamp = clock().toIso8601String();
    final kind = params['p_kind'] as String;
    final amount = params['p_amount'] as int;
    final common = {
      'tanggal': params['p_tanggal'],
      'reference_type': kind,
      'reference_id': groupId,
      'transfer_group_id': groupId,
      'catatan': params['p_catatan'],
      'created_by': null,
      'created_at': timestamp,
      'updated_at': timestamp,
      'deleted_at': null,
    };
    ledger[params['p_out_id'] as String] = {
      ...common,
      'id': params['p_out_id'],
      'fund_source_id': params['p_from_source_id'],
      'tipe': kind == 'adjustment' ? 'penyesuaian' : 'alih_keluar',
      'jumlah_delta': -amount,
    };
    ledger[params['p_in_id'] as String] = {
      ...common,
      'id': params['p_in_id'],
      'fund_source_id': params['p_to_source_id'],
      'tipe': kind == 'adjustment' ? 'penyesuaian' : 'alih_masuk',
      'jumlah_delta': amount,
    };
    return {'transfer_group_id': groupId, 'amount': amount};
  }

  @override
  Future<void> update(
    String table,
    String id,
    Map<String, dynamic> values,
  ) async {
    final t = tables.putIfAbsent(table, () => {});
    final existing = t[id];
    if (existing == null) return; // row tidak ada: no-op (0 rows affected)
    t[id] = {...existing, ...values, 'updated_at': clock().toIso8601String()};
  }

  @override
  Future<void> updateByCustomer(
    String table,
    String customerId,
    Map<String, dynamic> values,
  ) async {
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
