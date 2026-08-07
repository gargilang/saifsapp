import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app_providers.dart';
import '../../core/utils/money.dart';
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

  @override
  Widget build(BuildContext context) {
    final data =
        ref.watch(customersProvider((query: _query, sortByHutang: _sortByHutang)));
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'customers-fab',
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CustomerFormPage())),
        child: const Icon(Icons.person_add),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                    hintText: 'Cari nama customer...',
                    prefixIcon: Icon(Icons.search)),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            IconButton(
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
                    child: ListView.builder(
                      itemCount: rows.length,
                      itemBuilder: (_, i) {
                        final r = rows[i];
                        final lunas = r.totalHutang > 0 && r.sisa <= 0;
                        return ListTile(
                          title: Text(r.customer.nama),
                          subtitle: lunas
                              ? const Text('LUNAS')
                              : Text('Sisa: ${formatRupiah(r.sisa)}'),
                          trailing: lunas
                              ? const Icon(Icons.check_circle_outline,
                                  color: Colors.green)
                              : null,
                          onTap: () => context.push('/customers/${r.customer.id}'),
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
