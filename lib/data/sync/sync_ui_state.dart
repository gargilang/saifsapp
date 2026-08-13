import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State UI sync — dipakai native maupun web (stub).
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

final connectivityProvider = StreamProvider<bool>((ref) => Connectivity()
    .onConnectivityChanged
    .map((results) => results.any((r) => r != ConnectivityResult.none)));
