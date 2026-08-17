import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app_providers.dart';
import '../../core/utils/money.dart';
import '../../data/repositories/app_repository.dart';
import '../../widgets/collectibility_dot.dart';
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
  CustomerFilter _filter = CustomerFilter.semua;
  CustomerSort _sort = CustomerSort.nama;

  static const _chips = [
    (CustomerFilter.semua, 'Semua'),
    (CustomerFilter.berhutang, 'Berhutang'),
    (CustomerFilter.macet, 'Macet'),
    (CustomerFilter.lunas, 'Lunas'),
    (CustomerFilter.arsip, 'Arsip'),
  ];

  static const _sorts = [
    (CustomerSort.nama, 'Nama A-Z'),
    (CustomerSort.hutang, 'Hutang terbesar'),
    (CustomerSort.terakhirBayar, 'Terakhir bayar'),
  ];

  String _inisial(String nama) {
    final parts = nama.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return nama.isNotEmpty ? nama[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final data = ref.watch(customersProvider((query: _query, filter: _filter, sort: _sort)));
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'customers-fab',
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Tambah'),
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const CustomerFormPage())),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Cari nama nasabah...',
                  prefixIcon: Icon(Icons.search, color: cs.onSurfaceVariant),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<CustomerSort>(
              tooltip: 'Urutkan',
              icon: const Icon(Icons.sort),
              initialValue: _sort,
              onSelected: (v) => setState(() => _sort = v),
              itemBuilder: (ctx) => [
                for (final s in _sorts) PopupMenuItem(value: s.$1, child: Text(s.$2)),
              ],
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final c in _chips) ...[
                ChoiceChip(
                  label: Text(c.$2),
                  selected: _filter == c.$1,
                  onSelected: (_) => setState(() => _filter = c.$1),
                ),
                const SizedBox(width: 8),
              ],
            ]),
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: data.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => EmptyState(message: 'Gagal memuat data: $e'),
            data: (rows) => rows.isEmpty
                ? EmptyState(
                    message: 'Belum ada nasabah.',
                    actionLabel: _filter == CustomerFilter.semua && _query.isEmpty
                        ? '+ Tambah Nasabah'
                        : null,
                    onAction: _filter == CustomerFilter.semua && _query.isEmpty
                        ? () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const CustomerFormPage()))
                        : null,
                  )
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
                                        color: cs.tertiary.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text('LUNAS',
                                          style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: cs.tertiary)),
                                    ),
                                  ])
                                : Row(children: [
                                    CollectibilityDot(status: r.collectibility),
                                    const SizedBox(width: 6),
                                    Text('Sisa: ${formatRupiah(r.sisa)}',
                                        style: Theme.of(context).textTheme.bodyMedium),
                                  ]),
                            trailing: IconButton(
                              icon: Icon(Icons.delete_outline,
                                  size: 20, color: cs.onSurfaceVariant),
                              tooltip: 'Hapus nasabah',
                              onPressed: () async {
                                final pesan = StringBuffer()
                                  ..writeln('Nasabah: ${r.customer.nama}')
                                  ..writeln()
                                  ..writeln('Semua transaksi dan pembayaran nasabah ini juga akan ikut dihapus.')
                                  ..writeln()
                                  ..write('Data tetap tersimpan dan bisa dipulihkan jika diperlukan.');

                                if (await confirmDialog(context,
                                    title: 'Hapus nasabah beserta semua datanya?',
                                    message: pesan.toString())) {
                                  await mutate(ref,
                                      () => ref.read(repoProvider).deleteCustomerCascade(r.customer.id));
                                }
                              },
                            ),
                            onTap: () => context.push('/customers/${r.customer.id}'),
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
