import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app_providers.dart';
import '../../core/logic/fifo.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/money.dart';
import '../../core/utils/whatsapp.dart';
import '../../core/wa_template.dart';
import '../../data/models/payment.dart';
import '../../data/repositories/app_repository.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/stat_card.dart';
import '../payments/payment_form_page.dart';
import '../purchases/purchase_form_page.dart';
import '../statement/statement_data.dart';
import '../statement/statement_pdf.dart';
import 'customer_form_page.dart';

enum _DetailSort { terbaru, terlama }

class CustomerDetailPage extends ConsumerStatefulWidget {
  final String customerId;
  const CustomerDetailPage({super.key, required this.customerId});

  @override
  ConsumerState<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends ConsumerState<CustomerDetailPage> {
  static const _pageSize = 5;

  _DetailSort _purchaseSort = _DetailSort.terbaru;
  _DetailSort _paymentSort = _DetailSort.terbaru;
  int _visiblePurchases = _pageSize;
  int _visiblePayments = _pageSize;

  String _inisial(String nama) {
    final parts = nama.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return nama.isNotEmpty ? nama[0].toUpperCase() : '?';
  }

  List<({PurchaseStatus item, int number})> _orderedPurchases(
    List<PurchaseStatus> items,
  ) {
    final oldest = [...items]
      ..sort((a, b) {
        final byDate = a.purchase.tanggalBeli.compareTo(b.purchase.tanggalBeli);
        if (byDate != 0) return byDate;
        final byCreated = a.purchase.createdAt.compareTo(b.purchase.createdAt);
        return byCreated != 0
            ? byCreated
            : a.purchase.id.compareTo(b.purchase.id);
      });
    final numbered = [
      for (var index = 0; index < oldest.length; index++)
        (item: oldest[index], number: index + 1),
    ];
    return _purchaseSort == _DetailSort.terbaru
        ? numbered.reversed.toList()
        : numbered;
  }

  List<({Payment item, int number})> _orderedPayments(List<Payment> items) {
    final oldest = [...items]
      ..sort((a, b) {
        final byDate = a.tanggalBayar.compareTo(b.tanggalBayar);
        if (byDate != 0) return byDate;
        final byCreated = a.createdAt.compareTo(b.createdAt);
        return byCreated != 0 ? byCreated : a.id.compareTo(b.id);
      });
    final numbered = [
      for (var index = 0; index < oldest.length; index++)
        (item: oldest[index], number: index + 1),
    ];
    return _paymentSort == _DetailSort.terbaru
        ? numbered.reversed.toList()
        : numbered;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final customerId = widget.customerId;
    final data = ref.watch(customerDetailProvider(customerId));
    return Scaffold(
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(message: 'Gagal memuat: $e'),
        data: (d) {
          final purchaseRows = _orderedPurchases(d.items);
          final paymentRows = _orderedPayments(d.payments);
          final visiblePurchaseRows = purchaseRows
              .take(_visiblePurchases)
              .toList();
          final visiblePaymentRows = paymentRows
              .take(_visiblePayments)
              .toList();
          final remainingPurchases =
              purchaseRows.length - visiblePurchaseRows.length;
          final remainingPayments =
              paymentRows.length - visiblePaymentRows.length;
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(customerDetailProvider(customerId)),
            child: CustomScrollView(
              slivers: [
                // ── SliverAppBar ─────────────────────────────────────────────
                SliverAppBar(
                  floating: false,
                  pinned: true,
                  backgroundColor: cs.surface,
                  title: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: cs.primaryContainer,
                        child: Text(
                          _inisial(d.customer.nama),
                          style: TextStyle(
                            color: cs.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              d.customer.nama,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (d.stats.customerSetia)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star_rounded,
                                    size: 11,
                                    color: cs.primary,
                                  ),
                                  const SizedBox(width: 3),
                                  Flexible(
                                    child: Text(
                                      'Nasabah Setia',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: cs.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Edit nasabah',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CustomerFormPage(existing: d.customer),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Hapus nasabah',
                      onPressed: () async {
                        final jumlahTransaksi = d.items.length;
                        final jumlahPembayaran = d.payments.length;
                        final totalHutang = d.balance.totalHutang;
                        final totalBayar = d.balance.totalBayar;

                        final pesan = StringBuffer()
                          ..writeln('Nasabah: ${d.customer.nama}')
                          ..writeln()
                          ..writeln('Data berikut akan ikut dihapus:')
                          ..writeln('• $jumlahTransaksi transaksi')
                          ..writeln('• $jumlahPembayaran pembayaran')
                          ..writeln()
                          ..writeln(
                            'Total hutang: ${formatRupiah(totalHutang)}',
                          )
                          ..writeln('Total bayar: ${formatRupiah(totalBayar)}')
                          ..writeln()
                          ..write(
                            'Semua data tetap tersimpan dan bisa dipulihkan jika diperlukan.',
                          );

                        if (await confirmDialog(
                          context,
                          title: 'Hapus nasabah beserta semua datanya?',
                          message: pesan.toString(),
                        )) {
                          await mutate(
                            ref,
                            () => ref
                                .read(repoProvider)
                                .deleteCustomerCascade(customerId),
                          );
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
                      if (d.customer.noHp != null ||
                          d.customer.alamat != null) ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (d.customer.noHp != null)
                              Text(
                                d.customer.noHp!,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            if (d.customer.alamat != null)
                              Text(
                                d.customer.alamat!,
                                style: Theme.of(context).textTheme.bodyMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      // ── Stat cards ────────────────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              label: 'Total Belanja',
                              value: formatRupiah(d.balance.totalHutang),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: StatCard(
                              label: 'Total Bayar',
                              value: formatRupiah(d.balance.totalBayar),
                              valueColor: cs.tertiary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      StatCard(
                        label: 'Sisa Hutang',
                        value: formatRupiah(d.balance.sisa),
                        valueColor: d.balance.sisa > 0 ? cs.error : cs.tertiary,
                      ),
                      const SizedBox(height: 12),

                      // ── Aksi WA & PDF ─────────────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.chat_outlined, size: 18),
                              label: const Text('Ingatkan via WA'),
                              onPressed:
                                  normalizePhoneId(d.customer.noHp) == null
                                  ? null
                                  : () => _ingatkanWA(context, ref, d),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(
                                Icons.picture_as_pdf_outlined,
                                size: 18,
                              ),
                              label: const Text('Kartu Piutang'),
                              onPressed: () => _bagikanPdf(context, d),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Customer 360 ──────────────────────────────────────
                      Text(
                        'RINGKASAN CUSTOMER',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(height: 8),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _InfoItem(
                                      label: 'Nasabah Sejak',
                                      value: d.stats.customerSejak != null
                                          ? tampilTanggal(
                                              d.stats.customerSejak!,
                                            )
                                          : '-',
                                    ),
                                  ),
                                  Expanded(
                                    child: _InfoItem(
                                      label: 'Transaksi',
                                      value: '${d.stats.jumlahTransaksi}',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _InfoItem(
                                      label: 'Rata-rata Cicilan',
                                      value: d.stats.rataRataCicilan != null
                                          ? formatRupiah(
                                              d.stats.rataRataCicilan!,
                                            )
                                          : '-',
                                    ),
                                  ),
                                  Expanded(
                                    child: _InfoItem(
                                      label: 'Kecepatan Lunas',
                                      value: d.stats.kecepatanLunasHari != null
                                          ? '${d.stats.kecepatanLunasHari} hari'
                                          : '-',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Section Barang ────────────────────────────────────
                      _SectionHeader(
                        title: 'Barang',
                        sortTooltip: 'Urutkan barang',
                        sort: _purchaseSort,
                        onSortChanged: (sort) => setState(() {
                          _purchaseSort = sort;
                          _visiblePurchases = _pageSize;
                        }),
                        actionLabel: '+ Tambah',
                        onAction: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                PurchaseFormPage(customerId: customerId),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (d.items.isEmpty)
                        const EmptyState(message: 'Belum ada barang.')
                      else
                        Card(
                          child: Column(
                            children: [
                              for (
                                int i = 0;
                                i < visiblePurchaseRows.length;
                                i++
                              ) ...[
                                if (i > 0)
                                  Divider(
                                    height: 1,
                                    indent: 16,
                                    color: cs.surfaceContainerHighest,
                                  ),
                                ListTile(
                                  key: ValueKey(
                                    'purchase-${visiblePurchaseRows[i].item.purchase.id}',
                                  ),
                                  leading: _SequenceNumber(
                                    visiblePurchaseRows[i].number,
                                  ),
                                  title: Text(
                                    visiblePurchaseRows[i]
                                        .item
                                        .purchase
                                        .namaBarang,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${tampilTanggal(visiblePurchaseRows[i].item.purchase.tanggalBeli)} · ${formatRupiah(visiblePurchaseRows[i].item.purchase.hargaJual)}'
                                    '${visiblePurchaseRows[i].item.status == ItemStatus.sebagian ? ' · sisa ${formatRupiah(visiblePurchaseRows[i].item.sisa)}' : ''}',
                                  ),
                                  trailing: _StatusChip(
                                    status: visiblePurchaseRows[i].item.status,
                                  ),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PurchaseFormPage(
                                        customerId: customerId,
                                        existing: visiblePurchaseRows[i]
                                            .item
                                            .purchase,
                                      ),
                                    ),
                                  ),
                                  onLongPress: () async {
                                    if (await confirmDialog(
                                      context,
                                      title: 'Hapus barang?',
                                      message: visiblePurchaseRows[i]
                                          .item
                                          .purchase
                                          .namaBarang,
                                    )) {
                                      await mutate(
                                        ref,
                                        () => ref
                                            .read(repoProvider)
                                            .deletePurchase(
                                              visiblePurchaseRows[i]
                                                  .item
                                                  .purchase
                                                  .id,
                                            ),
                                      );
                                    }
                                  },
                                ),
                              ],
                              if (remainingPurchases > 0) ...[
                                Divider(
                                  height: 1,
                                  indent: 16,
                                  color: cs.surfaceContainerHighest,
                                ),
                                TextButton.icon(
                                  onPressed: () => setState(
                                    () => _visiblePurchases += _pageSize,
                                  ),
                                  icon: const Icon(Icons.expand_more),
                                  label: Text(
                                    'Muat 5 barang lagi ($remainingPurchases tersisa)',
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),

                      // ── Section Pembayaran ────────────────────────────────
                      _SectionHeader(
                        title: 'Riwayat Pembayaran',
                        sortTooltip: 'Urutkan pembayaran',
                        sort: _paymentSort,
                        onSortChanged: (sort) => setState(() {
                          _paymentSort = sort;
                          _visiblePayments = _pageSize;
                        }),
                        actionLabel: '+ Bayar',
                        onAction: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                PaymentFormPage(customerId: customerId),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (d.payments.isEmpty)
                        const EmptyState(message: 'Belum ada pembayaran.')
                      else
                        Card(
                          child: Column(
                            children: [
                              for (
                                int i = 0;
                                i < visiblePaymentRows.length;
                                i++
                              ) ...[
                                if (i > 0)
                                  Divider(
                                    height: 1,
                                    indent: 16,
                                    color: cs.surfaceContainerHighest,
                                  ),
                                ListTile(
                                  key: ValueKey(
                                    'payment-${visiblePaymentRows[i].item.id}',
                                  ),
                                  dense: true,
                                  leading: _SequenceNumber(
                                    visiblePaymentRows[i].number,
                                  ),
                                  title: Text(
                                    formatRupiah(
                                      visiblePaymentRows[i].item.jumlah,
                                    ),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${tampilTanggal(visiblePaymentRows[i].item.tanggalBayar)} · ${visiblePaymentRows[i].item.metode}',
                                  ),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PaymentFormPage(
                                        customerId: customerId,
                                        existing: visiblePaymentRows[i].item,
                                      ),
                                    ),
                                  ),
                                  onLongPress: () async {
                                    if (await confirmDialog(
                                      context,
                                      title: 'Hapus pembayaran?',
                                      message: formatRupiah(
                                        visiblePaymentRows[i].item.jumlah,
                                      ),
                                    )) {
                                      await mutate(
                                        ref,
                                        () => ref
                                            .read(repoProvider)
                                            .deletePayment(
                                              visiblePaymentRows[i].item.id,
                                            ),
                                      );
                                    }
                                  },
                                ),
                              ],
                              if (remainingPayments > 0) ...[
                                Divider(
                                  height: 1,
                                  indent: 16,
                                  color: cs.surfaceContainerHighest,
                                ),
                                TextButton.icon(
                                  onPressed: () => setState(
                                    () => _visiblePayments += _pageSize,
                                  ),
                                  icon: const Icon(Icons.expand_more),
                                  label: Text(
                                    'Muat 5 pembayaran lagi ($remainingPayments tersisa)',
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      const SizedBox(height: 80),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

Future<void> _ingatkanWA(
  BuildContext context,
  WidgetRef ref,
  CustomerDetailData d,
) async {
  final phone = normalizePhoneId(d.customer.noHp);
  if (phone == null) return; // tombol sudah disabled
  final template = ref.read(waTemplateProvider);
  final msg = renderWaTemplate(
    template,
    nama: d.customer.nama,
    sisaHutang: d.balance.sisa,
  );
  try {
    final ok = await launchUrl(
      buildWaReminderUri(phone: phone, message: msg),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak bisa membuka WhatsApp.')),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak bisa membuka WhatsApp.')),
      );
    }
  }
}

Future<void> _bagikanPdf(BuildContext context, CustomerDetailData d) async {
  try {
    final logo = await rootBundle.load('assets/brand/logo_pdf.png');
    final data = buildStatementData(d);
    final bytes = await buildStatementPdf(
      data,
      logoPng: logo.buffer.asUint8List(),
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'kartu-piutang-${d.customer.nama}.pdf',
    );
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membuat PDF. Coba lagi.')),
      );
    }
  }
}

class _InfoItem extends StatelessWidget {
  final String label, value;
  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: tt.labelSmall),
        const SizedBox(height: 4),
        Text(value, style: tt.titleMedium),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title, actionLabel, sortTooltip;
  final _DetailSort sort;
  final VoidCallback onAction;
  final ValueChanged<_DetailSort> onSortChanged;
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.sortTooltip,
    required this.sort,
    required this.onAction,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ),
      PopupMenuButton<_DetailSort>(
        initialValue: sort,
        tooltip: sortTooltip,
        icon: const Icon(Icons.sort),
        onSelected: onSortChanged,
        itemBuilder: (context) => [
          CheckedPopupMenuItem(
            value: _DetailSort.terbaru,
            checked: sort == _DetailSort.terbaru,
            child: const Text('Terbaru'),
          ),
          CheckedPopupMenuItem(
            value: _DetailSort.terlama,
            checked: sort == _DetailSort.terlama,
            child: const Text('Terlama'),
          ),
        ],
      ),
      TextButton(onPressed: onAction, child: Text(actionLabel)),
    ],
  );
}

class _SequenceNumber extends StatelessWidget {
  final int number;
  const _SequenceNumber(this.number);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: 16,
      backgroundColor: cs.primaryContainer,
      foregroundColor: cs.onPrimaryContainer,
      child: Text(
        '$number',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
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
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
