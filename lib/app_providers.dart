import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/logic/budget.dart';
import 'core/logic/profit.dart';
import 'data/local/app_database.dart';
import 'data/local/drift_backend.dart';
import 'data/models/customer.dart';
import 'data/remote/remote_backend.dart';
import 'data/remote/remote_store.dart';
import 'data/repositories/app_repository.dart';
import 'data/repositories/backend.dart';
import 'data/sync/sync_controller.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final remoteStoreProvider =
    Provider<RemoteStore>((_) => SupabaseRemoteStore(Supabase.instance.client));

final backendProvider = Provider<Backend>((ref) => kIsWeb
    ? RemoteBackend(ref.watch(remoteStoreProvider))
    : DriftBackend(ref.watch(appDatabaseProvider)));

final repoProvider = Provider<AppRepository>((ref) => AppRepository(
      ref.watch(backendProvider),
      currentUserId: () => Supabase.instance.client.auth.currentUser?.id,
      onLocalWrite:
          kIsWeb ? null : () => ref.read(syncControllerProvider.notifier).requestSync(),
    ));

final authStateProvider =
    StreamProvider((ref) => Supabase.instance.client.auth.onAuthStateChange);

// ---- data providers (di-invalidate oleh mutate() / selesai sync) ----
final customersProvider = FutureProvider.autoDispose
    .family<List<CustomerWithBalance>, ({String query, bool sortByHutang})>(
        (ref, p) => ref
            .watch(repoProvider)
            .customers(query: p.query, sortByHutang: p.sortByHutang));

final customerDetailProvider =
    FutureProvider.autoDispose.family<CustomerDetailData, String>(
        (ref, id) => ref.watch(repoProvider).customerDetail(id));

final dashboardProvider = FutureProvider.autoDispose(
    (ref) => ref.watch(repoProvider).dashboardStats());

final profitYearlyProvider = FutureProvider.autoDispose(
    (ref) => ref.watch(repoProvider).profitYearly());

final profitMonthlyProvider = FutureProvider.autoDispose
    .family<List<ProfitRow>, int>(
        (ref, year) => ref.watch(repoProvider).profitMonthly(year));

final budgetMonthProvider = FutureProvider.autoDispose
    .family<List<BudgetLine>, (int, int)>(
        (ref, ym) => ref.watch(repoProvider).budgetMonth(ym.$1, ym.$2));

/// Jalankan mutasi lalu refresh semua data provider.
Future<T> mutate<T>(Ref ref, Future<T> Function() action) async {
  final r = await action();
  invalidateAllData(ref);
  return r;
}

void invalidateAllData(Ref ref) {
  ref.invalidate(customersProvider);
  ref.invalidate(customerDetailProvider);
  ref.invalidate(dashboardProvider);
  ref.invalidate(profitYearlyProvider);
  ref.invalidate(profitMonthlyProvider);
  ref.invalidate(budgetMonthProvider);
}
