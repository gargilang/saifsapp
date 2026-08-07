import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app_providers.dart';
import '../../core/utils/money.dart';
import '../../data/models/customer.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/stat_card.dart';
import '../customers/customer_form_page.dart';
import '../payments/payment_form_page.dart';
import '../purchases/purchase_form_page.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  Future<void> _pilihCustomerLalu(BuildContext context, WidgetRef ref,
      Widget Function(String customerId) pageBuilder) async {
    final customers = await ref.read(repoProvider).customers();
    if (!context.mounted) return;
    if (customers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Belum ada customer. Tambah dulu.')));
      return;
    }
    final chosen = await showModalBottomSheet<Customer>(
      context: context,
      builder: (ctx) => ListView(
        children: [
          for (final c in customers)
            ListTile(
              title: Text(c.customer.nama),
              subtitle: Text('Sisa: ${formatRupiah(c.sisa)}'),
              onTap: () => Navigator.pop(ctx, c.customer),
            ),
        ],
      ),
    );
    if (chosen != null && context.mounted) {
      await Navigator.push(
          context, MaterialPageRoute(builder: (_) => pageBuilder(chosen.id)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardProvider);
    return stats.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(message: 'Gagal memuat: $e'),
      data: (s) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(dashboardProvider),
        child: ListView(padding: const EdgeInsets.all(12), children: [
          StatCard(
              label: 'Total Piutang Berjalan',
              value: formatRupiah(s.totalPiutang)),
          Row(children: [
            Expanded(
                child: StatCard(
                    label: 'Masuk Bulan Ini',
                    value: formatRupiah(s.bayarBulanIni))),
            Expanded(
                child: StatCard(
                    label: 'Customer Berhutang',
                    value: '${s.customerBerhutang}')),
          ]),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            FilledButton.tonalIcon(
              icon: const Icon(Icons.payments_outlined),
              label: const Text('Pembayaran'),
              onPressed: () => _pilihCustomerLalu(
                  context, ref, (id) => PaymentFormPage(customerId: id)),
            ),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Customer'),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CustomerFormPage())),
            ),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Barang'),
              onPressed: () => _pilihCustomerLalu(
                  context, ref, (id) => PurchaseFormPage(customerId: id)),
            ),
          ]),
          const SizedBox(height: 16),
          Text('Hutang Terbesar',
              style: Theme.of(context).textTheme.titleMedium),
          if (s.topHutang.isEmpty)
            const ListTile(title: Text('Tidak ada piutang berjalan.')),
          for (final c in s.topHutang)
            ListTile(
              title: Text(c.customer.nama),
              trailing: Text(formatRupiah(c.sisa)),
              onTap: () => context.push('/customers/${c.customer.id}'),
            ),
        ]),
      ),
    );
  }
}
