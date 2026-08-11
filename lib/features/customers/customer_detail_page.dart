import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app_providers.dart';
import '../../core/logic/fifo.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/money.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/stat_card.dart';
import '../payments/payment_form_page.dart';
import '../purchases/purchase_form_page.dart';
import 'customer_form_page.dart';

class CustomerDetailPage extends ConsumerWidget {
  final String customerId;
  const CustomerDetailPage({super.key, required this.customerId});

  String _inisial(String nama) {
    final parts = nama.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return nama.isNotEmpty ? nama[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final data = ref.watch(customerDetailProvider(customerId));
    return Scaffold(
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(message: 'Gagal memuat: $e'),
        data: (d) => RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(customerDetailProvider(customerId)),
          child: CustomScrollView(slivers: [
            // ── SliverAppBar ─────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 160,
              floating: false,
              pinned: true,
              backgroundColor: cs.surface,
              flexibleSpace: FlexibleSpaceBar(
                background: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: cs.primaryContainer,
                        child: Text(_inisial(d.customer.nama),
                            style: TextStyle(
                                color: cs.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 22)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(d.customer.nama,
                                  style: Theme.of(context).textTheme.titleLarge),
                              if (d.customer.noHp != null)
                                Text(d.customer.noHp!,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium),
                              if (d.customer.alamat != null)
                                Text(d.customer.alamat!,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                            ]),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit customer',
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              CustomerFormPage(existing: d.customer))),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Hapus customer',
                  onPressed: () async {
                    if (await confirmDialog(context,
                        title: 'Hapus customer?',
                        message:
                            'Data ${d.customer.nama} disembunyikan (bisa dipulihkan lewat database).')) {
                      await mutate(
                          ref,
                          () => ref
                              .read(repoProvider)
                              .deleteCustomer(customerId));
                      if (context.mounted) context.pop();
                    }
                  },
                ),
                const SizedBox(width: 4),
              ],
            ),

            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Stat cards ────────────────────────────────────────
                  Row(children: [
                    Expanded(
                        child: StatCard(
                            label: 'Total Belanja',
                            value: formatRupiah(d.balance.totalHutang))),
                    const SizedBox(width: 8),
                    Expanded(
                        child: StatCard(
                            label: 'Total Bayar',
                            value: formatRupiah(d.balance.totalBayar),
                            valueColor: cs.tertiary)),
                  ]),
                  const SizedBox(height: 8),
                  StatCard(
                    label: 'Sisa Hutang',
                    value: formatRupiah(d.balance.sisa),
                    valueColor: d.balance.sisa > 0 ? cs.error : cs.tertiary,
                  ),
                  const SizedBox(height: 24),

                  // ── Section Barang ────────────────────────────────────
                  _SectionHeader(
                    title: 'Barang',
                    actionLabel: '+ Tambah',
                    onAction: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                PurchaseFormPage(customerId: customerId))),
                  ),
                  const SizedBox(height: 8),
                  if (d.items.isEmpty)
                    const EmptyState(message: 'Belum ada barang.')
                  else
                    Card(
                      child: Column(children: [
                        for (int i = 0; i < d.items.length; i++) ...[
                          if (i > 0)
                            Divider(
                                height: 1,
                                indent: 16,
                                color: cs.surfaceContainerHighest),
                          ListTile(
                            title: Text(d.items[i].purchase.namaBarang,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text(
                                '${tampilTanggal(d.items[i].purchase.tanggalBeli)} · ${formatRupiah(d.items[i].purchase.hargaJual)}'
                                '${d.items[i].status == ItemStatus.sebagian ? ' · sisa ${formatRupiah(d.items[i].sisa)}' : ''}'),
                            trailing: _StatusChip(status: d.items[i].status),
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => PurchaseFormPage(
                                        customerId: customerId,
                                        existing: d.items[i].purchase))),
                            onLongPress: () async {
                              if (await confirmDialog(context,
                                  title: 'Hapus barang?',
                                  message: d.items[i].purchase.namaBarang)) {
                                await mutate(
                                    ref,
                                    () => ref
                                        .read(repoProvider)
                                        .deletePurchase(
                                            d.items[i].purchase.id));
                              }
                            },
                          ),
                        ],
                      ]),
                    ),
                  const SizedBox(height: 24),

                  // ── Section Pembayaran ────────────────────────────────
                  _SectionHeader(
                    title: 'Riwayat Pembayaran',
                    actionLabel: '+ Bayar',
                    onAction: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                PaymentFormPage(customerId: customerId))),
                  ),
                  const SizedBox(height: 8),
                  if (d.payments.isEmpty)
                    const EmptyState(message: 'Belum ada pembayaran.')
                  else
                    Card(
                      child: Column(children: [
                        for (int i = 0; i < d.payments.length; i++) ...[
                          if (i > 0)
                            Divider(
                                height: 1,
                                indent: 16,
                                color: cs.surfaceContainerHighest),
                          ListTile(
                            dense: true,
                            title: Text(formatRupiah(d.payments[i].jumlah),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text(
                                '${tampilTanggal(d.payments[i].tanggalBayar)} · ${d.payments[i].metode}'),
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => PaymentFormPage(
                                        customerId: customerId,
                                        existing: d.payments[i]))),
                            onLongPress: () async {
                              if (await confirmDialog(context,
                                  title: 'Hapus pembayaran?',
                                  message:
                                      formatRupiah(d.payments[i].jumlah))) {
                                await mutate(
                                    ref,
                                    () => ref
                                        .read(repoProvider)
                                        .deletePayment(d.payments[i].id));
                              }
                            },
                          ),
                        ],
                      ]),
                    ),
                  const SizedBox(height: 80),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title, actionLabel;
  final VoidCallback onAction;
  const _SectionHeader(
      {required this.title, required this.actionLabel, required this.onAction});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
              child: Text(title.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall)),
          TextButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      );
}

class _StatusChip extends StatelessWidget {
  final ItemStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (label, color) = switch (status) {
      ItemStatus.lunas => ('LUNAS', cs.tertiary),
      ItemStatus.sebagian => ('SEBAGIAN', const Color(0xFFF59E0B)),
      ItemStatus.belum => ('BELUM', cs.error),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}
