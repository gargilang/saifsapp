import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  @override
  SyncUiState build() => const SyncUiState();
  void requestSync() {}
  Future<void> syncNow() async {}
}

final syncControllerProvider =
    NotifierProvider<SyncController, SyncUiState>(SyncController.new);
