// Platform web — stub no-op (web online-only langsung Supabase, tidak ada sync lokal).
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sync_ui_state.dart';

class SyncController extends Notifier<SyncUiState> {
  @override
  SyncUiState build() => const SyncUiState();

  void requestSync() {}

  Future<void> syncNow() async {}
}

final syncControllerProvider =
    NotifierProvider<SyncController, SyncUiState>(SyncController.new);
