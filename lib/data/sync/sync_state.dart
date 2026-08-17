import 'package:shared_preferences/shared_preferences.dart';

/// Watermark pull per tabel (updated_at server terakhir yang sudah diambil).
class SyncStateStore {
  final SharedPreferences _prefs;
  SyncStateStore(this._prefs);

  Future<DateTime?> lastPull(String table) async {
    final s = _prefs.getString('last_pull_$table');
    return s == null ? null : DateTime.parse(s);
  }

  Future<void> setLastPull(String table, DateTime t) =>
      _prefs.setString('last_pull_$table', t.toIso8601String());

  /// Hapus watermark untuk [tables] (dipakai full resync).
  Future<void> clearAll(List<String> tables) async {
    for (final t in tables) {
      await _prefs.remove('last_pull_$t');
    }
  }
}
