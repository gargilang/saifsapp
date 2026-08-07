import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app_providers.dart';
import 'sync_engine.dart';
import 'sync_state.dart';

class SyncUiState {
  final bool syncing, offline;
  final int pending;
  final DateTime? lastSync;
  const SyncUiState(
      {this.syncing = false, this.offline = false, this.pending = 0, this.lastSync});

  SyncUiState copyWith(
          {bool? syncing, bool? offline, int? pending, DateTime? lastSync}) =>
      SyncUiState(
          syncing: syncing ?? this.syncing,
          offline: offline ?? this.offline,
          pending: pending ?? this.pending,
          lastSync: lastSync ?? this.lastSync);
}

class SyncController extends Notifier<SyncUiState> {
  Timer? _debounce;
  bool _running = false;

  @override
  SyncUiState build() {
    ref.listen(connectivityProvider, (_, next) {
      if (next.value == true) requestSync();
    });
    ref.onDispose(() => _debounce?.cancel());
    _refreshPending();
    return const SyncUiState();
  }

  Future<void> _refreshPending() async {
    final n = await ref.read(appDatabaseProvider).dirtyCount();
    state = state.copyWith(pending: n);
  }

  void requestSync() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 5), syncNow);
  }

  Future<void> syncNow() async {
    if (_running) return;
    _running = true;
    state = state.copyWith(syncing: true);
    try {
      final db = ref.read(appDatabaseProvider);
      final engine = SyncEngine(db, ref.read(remoteStoreProvider),
          SyncStateStore(await SharedPreferences.getInstance()));
      await engine.syncAll();
      state = state.copyWith(
          syncing: false, offline: false, lastSync: DateTime.now());
      invalidateAllData(ref);
    } catch (_) {
      state = state.copyWith(syncing: false, offline: true);
    } finally {
      _running = false;
      await _refreshPending();
    }
  }
}

final syncControllerProvider =
    NotifierProvider<SyncController, SyncUiState>(SyncController.new);

final connectivityProvider = StreamProvider<bool>((ref) => Connectivity()
    .onConnectivityChanged
    .map((results) => results.any((r) => r != ConnectivityResult.none)));
