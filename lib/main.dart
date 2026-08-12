import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'data/sync/background_sync.dart';
import 'data/sync/sync_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await registerBackgroundSync();
  }
  final container = ProviderContainer();
  if (!kIsWeb) {
    // sync awal saat app start (best effort; gagal = tetap jalan offline)
    Future(() => container.read(syncControllerProvider.notifier).syncNow());
  }
  runApp(UncontrolledProviderScope(container: container, child: const SandiApp()));
}
