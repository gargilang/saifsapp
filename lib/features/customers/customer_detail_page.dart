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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(customerDetailProvider(customerId));
    return data.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(message: 'Gagal memuat: $e'),
      data: (d) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(customerDetailProvider(customerId)),
        child: ListView(padding: const EdgeInsets.all(12), children: [
          Row(children: [
            Expanded(
              child: Text(d.customer.nama,
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit customer',
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => CustomerFormPage(existing: d.customer))),
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
                      ref, () => ref.read(repoProvider).deleteCustomer(customerId));
                  if (context.mounted) context.pop();
                }
              },
            ),
          ]),
          if (d.customer.noHp != null) Text('HP: ${d.customer.noHp}'),
          if (d.customer.alamat != null) Text('Alamat: ${d.customer.alamat}'),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
                child: StatCard(
                    label: 'Total Belanja',
                    value: formatRupiah(d.balance.totalHutang))),
            Expanded(
                child: StatCard(
                    label: 'Total Bayar',
                    value: formatRupiah(d.balance.totalBayar))),
          ]),
          StatCard(
            label: 'Sisa Hutang',
            value: formatRupiah(d.balance.sisa),
            valueColor: d.balance.sisa > 0
                ? Theme.of(context).colorScheme.error
                : Colors.green,
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
                child: Text('Barang',
                    style: Theme.of(context).textTheme.titleMedium)),
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Tambah'),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => PurchaseFormPage(customerId: customerId))),
            ),
          ]),
          if (d.items.isEmpty) const ListTile(title: Text('Belum ada barang.')),
          for (final item in d.items)
            ListTile(
              title: Text(item.purchase.namaBarang),
              subtitle: Text(
                  '${tampilTanggal(item.purchase.tanggalBeli)} · ${formatRupiah(item.purchase.hargaJual)}'
                  '${item.status == ItemStatus.sebagian ? ' · sisa ${formatRupiah(item.sisa)}' : ''}'),
              trailing: _StatusChip(status: item.status),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => PurchaseFormPage(
                          customerId: customerId, existing: item.purchase))),
              onLongPress: () async {
                if (await confirmDialog(context,
                    title: 'Hapus barang?',
                    message: item.purchase.namaBarang)) {
                  await mutate(ref,
                      () => ref.read(repoProvider).deletePurchase(item.purchase.id));
                }
              },
            ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
                child: Text('Riwayat Pembayaran',
                    style: Theme.of(context).textTheme.titleMedium)),
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Bayar'),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => PaymentFormPage(customerId: customerId))),
            ),
          ]),
          if (d.payments.isEmpty)
            const ListTile(title: Text('Belum ada pembayaran.')),
          for (final p in d.payments)
            ListTile(
              dense: true,
              title: Text(formatRupiah(p.jumlah)),
              subtitle: Text('${tampilTanggal(p.tanggalBayar)} · ${p.metode}'),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          PaymentFormPage(customerId: customerId, existing: p))),
              onLongPress: () async {
                if (await confirmDialog(context,
                    title: 'Hapus pembayaran?',
                    message: formatRupiah(p.jumlah))) {
                  await mutate(
                      ref, () => ref.read(repoProvider).deletePayment(p.id));
                }
              },
            ),
          const SizedBox(height: 80),
        ]),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final ItemStatus status;
  const _StatusChip({required this.status});
  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ItemStatus.lunas => ('LUNAS', Colors.green),
      ItemStatus.sebagian => ('SEBAGIAN', Colors.orange),
      ItemStatus.belum => ('BELUM', Colors.red),
    };
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      backgroundColor: color.withValues(alpha: 0.15),
      side: BorderSide.none,
    );
  }
}
