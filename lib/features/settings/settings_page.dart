import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme_mode.dart';
import '../../core/utils/dates.dart';
import '../../data/sync/sync_controller.dart';
import '../../widgets/confirm_dialog.dart';
import '../auth/auth_controller.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = Supabase.instance.client.auth.currentUser?.email ?? '-';
    final themeMode = ref.watch(themeModeProvider);
    final sync = ref.watch(syncControllerProvider);
    return ListView(padding: const EdgeInsets.all(12), children: [
      ListTile(
          leading: const Icon(Icons.person_outline),
          title: Text(email),
          subtitle: const Text('Admin')),
      SwitchListTile(
        secondary: const Icon(Icons.dark_mode_outlined),
        title: const Text('Mode gelap'),
        value: themeMode == ThemeMode.dark,
        onChanged: (v) => ref
            .read(themeModeProvider.notifier)
            .setMode(v ? ThemeMode.dark : ThemeMode.light),
      ),
      if (!kIsWeb) ...[
        const Divider(),
        ListTile(
          leading: const Icon(Icons.sync),
          title: Text(sync.pending > 0
              ? '${sync.pending} data belum tersinkron'
              : 'Semua data tersinkron'),
          subtitle: Text(sync.lastSync == null
              ? 'Belum pernah sinkron'
              : 'Terakhir: ${tampilTanggal(sync.lastSync!)}'),
          trailing: TextButton(
            onPressed: () => ref.read(syncControllerProvider.notifier).syncNow(),
            child: const Text('Sinkronkan'),
          ),
        ),
      ],
      const Divider(),
      ListTile(
        leading: const Icon(Icons.logout),
        title: const Text('Keluar'),
        onTap: () async {
          if (await confirmDialog(context,
              title: 'Keluar?',
              message: 'Anda harus login kembali untuk membuka data.')) {
            await ref.read(authControllerProvider.notifier).signOut();
          }
        },
      ),
    ]);
  }
}
