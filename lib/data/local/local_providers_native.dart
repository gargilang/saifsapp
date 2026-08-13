// Platform native (Android) — menggunakan drift/SQLite.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';
import 'drift_backend.dart';
import '../repositories/backend.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

Backend buildLocalBackend(AppDatabase db) => DriftBackend(db);
