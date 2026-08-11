import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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

  String _inisial(String nama) {
    final parts = nama.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return nama.isNotEmpty ? nama[0].toUpperCase() : '?';
  }

  Future<void> _pilihCustomerLalu(BuildContext context, WidgetRef ref,
      Widget Function(String customerId) pageBuilder) async {
    final customers = await ref.read(repoProvider).customers();
    if (!context.mounted) return;
    if (customers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Belum ada customer. Tambah dulu.')));
      return;
    }
    final cs = Theme.of(context).colorScheme;
    final chosen = await showModalBottomSheet<Customer>(
      context: context,
      backgroundColor: cs.surfaceContainer,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text('Pilih Customer',
                style: Theme.of(ctx).textTheme.titleMedium),
          ),
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
    final cs = Theme.of(context).colorScheme;
    final stats = ref.watch(dashboardProvider);
    final tanggal = DateFormat('EEEE, d MMMM y', 'id_ID').format(DateTime.now());

    return stats.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(message: 'Gagal memuat: $e'),
      data: (s) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(dashboardProvider),
        child: ListView(padding: const EdgeInsets.all(16), children: [
          // ── Greeting ────────────────────────────────────────────────────
          Text('Halo, Admin 👋',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 2),
          Text(tanggal, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),

          // ── Hero card piutang total ──────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [cs.surfaceContainer, cs.surfaceContainerHighest],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cs.surfaceContainerHighest),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('TOTAL PIUTANG AKTIF',
                  style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 8),
              Text(formatRupiah(s.totalPiutang),
                  style: Theme.of(context)
                      .textTheme
                      .displayMedium
                      ?.copyWith(color: cs.primary)),
              const SizedBox(height: 4),
              Text('dari ${s.customerBerhutang} customer berhutang',
                  style: Theme.of(context).textTheme.bodyMedium),
            ]),
          ),
          const SizedBox(height: 12),

          // ── Stat cards ──────────────────────────────────────────────────
          Row(children: [
            Expanded(
                child: StatCard(
                    label: 'Bayar Bulan Ini',
                    value: formatRupiah(s.bayarBulanIni),
                    valueColor: cs.tertiary)),
            const SizedBox(width: 8),
            Expanded(
                child: StatCard(
                    label: 'Customer Berhutang',
                    value: '${s.customerBerhutang}')),
          ]),
          const SizedBox(height: 20),

          // ── Aksi Cepat ──────────────────────────────────────────────────
          Text('AKSI CEPAT',
              style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.payments_outlined, size: 18),
                label: const Text('Bayar'),
                onPressed: () => _pilihCustomerLalu(
                    context, ref, (id) => PaymentFormPage(customerId: id)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.person_add_outlined, size: 18),
                label: const Text('Customer'),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CustomerFormPage())),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add_shopping_cart_outlined, size: 18),
                label: const Text('Barang'),
                onPressed: () => _pilihCustomerLalu(
                    context, ref, (id) => PurchaseFormPage(customerId: id)),
              ),
            ),
          ]),
          const SizedBox(height: 24),

          // ── Hutang Terbesar ─────────────────────────────────────────────
          Text('HUTANG TERBESAR',
              style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 8),
          if (s.topHutang.isEmpty)
            const EmptyState(message: 'Tidak ada piutang berjalan.')
          else
            Card(
              child: Column(children: [
                for (int i = 0; i < s.topHutang.length; i++) ...[
                  if (i > 0)
                    Divider(
                        height: 1,
                        indent: 72,
                        color: cs.surfaceContainerHighest),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: cs.primaryContainer,
                      child: Text(_inisial(s.topHutang[i].customer.nama),
                          style: TextStyle(
                              color: cs.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                    ),
                    title: Text(s.topHutang[i].customer.nama,
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    trailing: Text(formatRupiah(s.topHutang[i].sisa),
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(color: cs.primary)),
                    onTap: () => context
                        .push('/customers/${s.topHutang[i].customer.id}'),
                  ),
                ],
              ]),
            ),
          const SizedBox(height: 80),
        ]),
      ),
    );
  }
}
