import 'package:supabase_flutter/supabase_flutter.dart';

/// Akses generik per tabel ke Supabase (json key = nama kolom).
abstract class RemoteStore {
  /// Ambil semua row (semua kolom), atau hanya yang updated_at > [since].
  Future<List<Map<String, dynamic>>> fetchSince(String table, DateTime? since);
  Future<void> upsert(String table, List<Map<String, dynamic>> rows);
}

class SupabaseRemoteStore implements RemoteStore {
  final SupabaseClient _client;
  SupabaseRemoteStore(this._client);

  @override
  Future<List<Map<String, dynamic>>> fetchSince(String table, DateTime? since) {
    final query = _client.from(table).select();
    if (since != null) {
      return query.gt('updated_at', since.toIso8601String());
    }
    return query;
  }

  @override
  Future<void> upsert(String table, List<Map<String, dynamic>> rows) =>
      _client.from(table).upsert(rows);
}
