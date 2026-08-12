import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import 'admin_form_page.dart';
import 'admin_providers.dart';

class AdminListPage extends ConsumerWidget {
  const AdminListPage({super.key});

  String _inisial(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final adminsAsync = ref.watch(adminListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Admin')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'admin-fab',
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Tambah'),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminFormPage()),
        ),
      ),
      body: adminsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(message: 'Gagal memuat: $e'),
        data: (admins) => admins.isEmpty
            ? const EmptyState(message: 'Belum ada admin.')
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(adminListProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: admins.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 4),
                  itemBuilder: (ctx, i) {
                    final admin = admins[i];
                    final isSelf = admin.id == currentUserId;
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: cs.primaryContainer,
                          child: Text(
                            _inisial(admin.displayName),
                            style: TextStyle(
                                color: cs.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13),
                          ),
                        ),
                        title: Text(
                          '${admin.displayName}${isSelf ? ' (kamu)' : ''}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(admin.email),
                        trailing: isSelf
                            ? null
                            : IconButton(
                                icon: Icon(Icons.delete_outline,
                                    size: 20, color: cs.onSurfaceVariant),
                                tooltip: 'Hapus admin',
                                onPressed: () async {
                                  if (await confirmDialog(context,
                                      title: 'Hapus admin?',
                                      message:
                                          '${admin.displayName} (${admin.email}) tidak akan bisa login lagi.')) {
                                    try {
                                      await ref
                                          .read(adminRepositoryProvider)
                                          .deleteAdmin(admin.id);
                                      ref.invalidate(adminListProvider);
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                          content: Text(
                                              'Gagal: ${e.toString().replaceAll("Exception: ", "")}'),
                                        ));
                                      }
                                    }
                                  }
                                },
                              ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
