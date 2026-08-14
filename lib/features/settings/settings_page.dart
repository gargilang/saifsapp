import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/pin_lock.dart';
import '../../core/utils/whatsapp.dart';
import '../../core/wa_template.dart';

import '../../core/theme_mode.dart';
import '../../core/utils/dates.dart';
import '../../data/sync/sync_controller.dart';
import '../../widgets/confirm_dialog.dart';
import '../auth/auth_controller.dart';
import 'admin_list_page.dart';
import 'admin_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  String _inisial(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final email = Supabase.instance.client.auth.currentUser?.email ?? '-';
    final themeMode = ref.watch(themeModeProvider);
    final sync = ref.watch(syncControllerProvider);
    final template = ref.watch(waTemplateProvider);
    final pin = ref.watch(pinLockProvider);
    final displayName = ref.watch(currentProfileProvider).valueOrNull ?? '';
    final namaAtauEmail = displayName.isNotEmpty ? displayName : email;
    return ListView(padding: const EdgeInsets.all(16), children: [
      // ── Profil ────────────────────────────────────────────────────────────
      Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: cs.primaryContainer,
              child: Text(_inisial(namaAtauEmail),
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
                    Text(namaAtauEmail,
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    Text('Admin · $email',
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
          Divider(height: 1, indent: 16, color: cs.surfaceContainerHighest),
          ListTile(
            leading: Icon(Icons.chat_outlined, color: cs.onSurfaceVariant),
            title: const Text('Template Pesan WA'),
            subtitle: Text(template, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: const Icon(Icons.edit_outlined, size: 18),
            onTap: () => _editWaTemplate(context, ref, template),
          ),
          Divider(height: 1, indent: 16, color: cs.surfaceContainerHighest),
          SwitchListTile(
            secondary: Icon(Icons.lock_outline, color: cs.onSurfaceVariant),
            title: const Text('Kunci PIN'),
            subtitle: const Text('Kunci aplikasi dengan PIN 4 digit'),
            value: pin.enabled,
            onChanged: (v) async {
              if (v) {
                await _setPinDialog(context, ref);
              } else {
                if (await confirmDialog(context,
                    title: 'Matikan kunci PIN?',
                    message: 'App tidak akan meminta PIN lagi.')) {
                  await ref.read(pinLockProvider.notifier).disable();
                }
              }
            },
          ),
        ]),
      ),
      const SizedBox(height: 16),

      // ── Manajemen Admin ───────────────────────────────────────────────────
      Card(
        child: ListTile(
          leading: Icon(Icons.manage_accounts_outlined, color: cs.onSurfaceVariant),
          title: const Text('Kelola Admin'),
          subtitle: const Text('Tambah atau hapus akun admin'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminListPage()),
          ),
        ),
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

Future<void> _setPinDialog(BuildContext context, WidgetRef ref) async {
  final ctrl = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Atur PIN'),
      content: TextField(
        controller: ctrl,
        obscureText: true,
        keyboardType: TextInputType.number,
        maxLength: 4,
        decoration: const InputDecoration(hintText: '4 digit PIN'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
        FilledButton(
          onPressed: ctrl.text.length == 4 ? () => Navigator.pop(ctx, true) : null,
          child: const Text('Aktifkan'),
        ),
      ],
    ),
  );
  if (ok == true && ctrl.text.length == 4) {
    await ref.read(pinLockProvider.notifier).enable(ctrl.text);
  }
  ctrl.dispose();
}

Future<void> _editWaTemplate(BuildContext context, WidgetRef ref, String current) async {
  final ctrl = TextEditingController(text: current);
  final saved = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Template Pesan WA'),
      content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Placeholder: {nama}, {sisa_hutang}, {bisnis}',
                style: Theme.of(ctx).textTheme.bodyMedium),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 5,
              decoration: const InputDecoration(hintText: 'Tulis template pesan...'),
            ),
          ]),
      actions: [
        TextButton(
          onPressed: () async {
            await ref.read(waTemplateProvider.notifier).reset();
            if (ctx.mounted) Navigator.pop(ctx, false);
          },
          child: const Text('Reset'),
        ),
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
        FilledButton(
          onPressed: () async {
            final v = ctrl.text.trim();
            await ref
                .read(waTemplateProvider.notifier)
                .setTemplate(v.isEmpty ? kDefaultWaTemplate : v);
            if (ctx.mounted) Navigator.pop(ctx, true);
          },
          child: const Text('Simpan'),
        ),
      ],
    ),
  );
  ctrl.dispose();
  if (saved == true && context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Template disimpan.')));
  }
}
