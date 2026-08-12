import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sync/sync_controller.dart';

/// Ikon status sync di AppBar (Android saja): jumlah pending / tersinkron.
class SyncBadge extends ConsumerWidget {
  const SyncBadge({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (kIsWeb) return const SizedBox.shrink();
    final s = ref.watch(syncControllerProvider);
    if (s.syncing) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox.square(
            dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    return IconButton(
      tooltip: s.pending > 0 ? '${s.pending} belum tersinkron' : 'Tersinkron',
      icon: Icon(
          s.pending > 0 ? Icons.cloud_upload_outlined : Icons.cloud_done_outlined),
      onPressed: () => ref.read(syncControllerProvider.notifier).syncNow(),
    );
  }
}
