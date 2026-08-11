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

  String _inisial(String email) =>
      email.isNotEmpty ? email[0].toUpperCase() : '?';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final email = Supabase.instance.client.auth.currentUser?.email ?? '-';
    final themeMode = ref.watch(themeModeProvider);
    final sync = ref.watch(syncControllerProvider);
    return ListView(padding: const EdgeInsets.all(16), children: [
      // ── Profil ────────────────────────────────────────────────────────────
      Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: cs.primaryContainer,
              child: Text(_inisial(email),
                  style: TextStyle(
                      color: cs.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 20)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(email,
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    Text('Admin',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ]),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 16),

      // ── Preferensi ────────────────────────────────────────────────────────
      Card(
        child: Column(children: [
          SwitchListTile(
            secondary:
                Icon(Icons.dark_mode_outlined, color: cs.onSurfaceVariant),
            title: const Text('Mode gelap'),
            value: themeMode == ThemeMode.dark,
            onChanged: (v) => ref
                .read(themeModeProvider.notifier)
                .setMode(v ? ThemeMode.dark : ThemeMode.light),
          ),
          if (!kIsWeb) ...[
            Divider(height: 1, indent: 16, color: cs.surfaceContainerHighest),
            ListTile(
              leading: Icon(Icons.sync, color: cs.onSurfaceVariant),
              title: Text(sync.pending > 0
                  ? '${sync.pending} data belum tersinkron'
                  : 'Semua data tersinkron'),
              subtitle: Text(sync.lastSync == null
                  ? 'Belum pernah sinkron'
                  : 'Terakhir: ${tampilTanggal(sync.lastSync!)}'),
              trailing: TextButton(
                onPressed: () =>
                    ref.read(syncControllerProvider.notifier).syncNow(),
                child: const Text('Sinkronkan'),
              ),
            ),
          ],
        ]),
      ),
      const SizedBox(height: 16),

      // ── Logout ────────────────────────────────────────────────────────────
      OutlinedButton.icon(
        icon: const Icon(Icons.logout),
        label: const Text('Keluar'),
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.error,
          side: BorderSide(color: cs.error),
          minimumSize: const Size(double.infinity, 48),
        ),
        onPressed: () async {
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
