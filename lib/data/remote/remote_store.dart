import 'package:supabase_flutter/supabase_flutter.dart';

import 'paginate.dart';

/// Akses generik per tabel ke Supabase (json key = nama kolom).
abstract class RemoteStore {
  /// Ambil semua row (semua kolom), atau hanya yang updated_at > [since].
  Future<List<Map<String, dynamic>>> fetchSince(String table, DateTime? since);
  Future<void> upsert(String table, List<Map<String, dynamic>> rows);

  /// Panggil Postgres RPC dan kembalikan object JSON hasilnya.
  Future<Map<String, dynamic>> rpc(String name, Map<String, dynamic> params);

  /// Update satu row berdasarkan [id]. Hanya kirim kolom yang mau diubah.
  Future<void> update(String table, String id, Map<String, dynamic> values);

  /// Update semua row dengan customer_id = [customerId].
  Future<void> updateByCustomer(
    String table,
    String customerId,
    Map<String, dynamic> values,
  );

  /// Panggil Supabase Edge Function.
  /// [method] default 'POST'. Gunakan 'GET' untuk operasi baca tanpa body.
  Future<Map<String, dynamic>> callFunction(
    String name, {
    String method = 'POST',
    Map<String, dynamic>? body,
  });
}

class SupabaseRemoteStore implements RemoteStore {
  final SupabaseClient _client;
  SupabaseRemoteStore(this._client);

  @override
  Future<List<Map<String, dynamic>>> fetchSince(String table, DateTime? since) {
    // Paginasi: PostgREST membatasi 1000 baris/request. Tanpa ini, tabel
    // dengan >1000 baris (mis. payments) tersinkron tidak lengkap → saldo salah.
    return fetchAllPaged((from, to) async {
      var query = _client.from(table).select();
      if (since != null) {
        query = query.gt('updated_at', since.toIso8601String());
      }
      // range inklusif, urut stabil by id agar paginasi konsisten.
      final rows = await query.order('id', ascending: true).range(from, to);
      return List<Map<String, dynamic>>.from(rows);
    });
  }

  @override
  Future<void> upsert(String table, List<Map<String, dynamic>> rows) =>
      _client.from(table).upsert(rows);

  @override
  Future<Map<String, dynamic>> rpc(
    String name,
    Map<String, dynamic> params,
  ) async {
    final result = await _client.rpc(name, params: params);
    return Map<String, dynamic>.from(result as Map);
  }

  @override
  Future<void> update(String table, String id, Map<String, dynamic> values) =>
      _client.from(table).update(values).eq('id', id);

  @override
  Future<void> updateByCustomer(
    String table,
    String customerId,
    Map<String, dynamic> values,
  ) => _client.from(table).update(values).eq('customer_id', customerId);

  @override
  Future<Map<String, dynamic>> callFunction(
    String name, {
    String method = 'POST',
    Map<String, dynamic>? body,
  }) async {
    final httpMethod = HttpMethod.values.firstWhere(
      (m) => m.name.toUpperCase() == method.toUpperCase(),
      orElse: () => HttpMethod.post,
    );
    final response = await _client.functions.invoke(
      name,
      method: httpMethod,
      body: body,
    );
    if (response.data == null) {
      throw Exception('Edge Function $name: response kosong');
    }
    final data = response.data as Map<String, dynamic>;
    if (data.containsKey('error')) {
      throw Exception(data['error'] as String);
    }
    return data;
  }
}
