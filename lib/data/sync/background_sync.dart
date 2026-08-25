import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart';

import '../local/app_database.dart';
import '../remote/remote_store.dart';
import 'sync_engine.dart';
import 'sync_state.dart';

const kSyncTask = 'sandiapp-periodic-sync';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await Supabase.initialize(
        url: const String.fromEnvironment('SUPABASE_URL'),
        publishableKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
      );
      final db = AppDatabase();
      final engine = SyncEngine(db, SupabaseRemoteStore(Supabase.instance.client),
          SyncStateStore(await SharedPreferences.getInstance()));
      await engine.syncAll();
      await db.close();
      return true;
    } catch (_) {
      return false; // best-effort; retrial dijadwalkan workmanager
    }
  });
}

Future<void> registerBackgroundSync() async {
  await Workmanager().initialize(callbackDispatcher);
  await Workmanager().registerPeriodicTask(
    kSyncTask,
    kSyncTask,
    frequency: const Duration(minutes: 15),
    constraints: Constraints(networkType: NetworkType.connected),
  );
}
