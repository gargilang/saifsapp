import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app_providers.dart';
import '../../core/utils/money.dart';
import '../../data/repositories/app_repository.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import 'customer_form_page.dart';

class CustomersPage extends ConsumerStatefulWidget {
  const CustomersPage({super.key});
  @override
  ConsumerState<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends ConsumerState<CustomersPage> {
  String _query = '';
  bool _sortByHutang = false;

  String _inisial(String nama) {
    final parts = nama.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return nama.isNotEmpty ? nama[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final data = ref.watch(customersProvider((
      query: _query,
      filter: CustomerFilter.semua,
      sort: _sortByHutang ? CustomerSort.hutang : CustomerSort.nama,
    )));
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'customers-fab',
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Tambah'),
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CustomerFormPage())),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Cari nama customer...',
                  prefixIcon: Icon(Icons.search, color: cs.onSurfaceVariant),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.outlined(
              tooltip: _sortByHutang ? 'Urut nama' : 'Urut hutang terbesar',
              icon: Icon(_sortByHutang ? Icons.sort_by_alpha : Icons.sort),
              onPressed: () => setState(() => _sortByHutang = !_sortByHutang),
            ),
          ]),
        ),
        Expanded(
          child: data.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => EmptyState(message: 'Gagal memuat data: $e'),
            data: (rows) => rows.isEmpty
                ? const EmptyState(message: 'Belum ada customer.')
                : RefreshIndicator(
                    onRefresh: () async => ref.invalidate(customersProvider),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: rows.length,
                      separatorBuilder: (ctx, i) => const SizedBox(height: 4),
                      itemBuilder: (_, i) {
                        final r = rows[i];
                        final lunas = r.totalHutang > 0 && r.sisa <= 0;
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: cs.primaryContainer,
                              child: Text(_inisial(r.customer.nama),
                                  style: TextStyle(
                                      color: cs.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13)),
                            ),
                            title: Text(r.customer.nama,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                            subtitle: lunas
                                ? Row(children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: cs.tertiary
                                            .withValues(alpha: 0.15),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: Text('LUNAS',
                                          style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: cs.tertiary)),
                                    ),
                                  ])
                                : Text('Sisa: ${formatRupiah(r.sisa)}',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium),
                            trailing: IconButton(
                              icon: Icon(Icons.delete_outline,
                                  size: 20, color: cs.onSurfaceVariant),
                              tooltip: 'Hapus customer',
                              onPressed: () async {
                                if (await confirmDialog(context,
                                    title: 'Hapus customer?',
                                    message:
                                        'Data ${r.customer.nama} disembunyikan (bisa dipulihkan lewat database).')) {
                                  await mutate(
                                      ref,
                                      () => ref
                                          .read(repoProvider)
                                          .deleteCustomer(r.customer.id));
                                }
                              },
                            ),
                            onTap: () =>
                                context.push('/customers/${r.customer.id}'),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ),
      ]),
    );
  }
}
