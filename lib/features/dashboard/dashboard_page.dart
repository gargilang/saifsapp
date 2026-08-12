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

  Future<void> _pilihCustomerLalu(
    BuildContext context,
    WidgetRef ref,
    Widget Function(String customerId) pageBuilder,
  ) async {
    final customers = await ref.read(repoProvider).customers();
    if (!context.mounted) return;
    if (customers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belum ada customer. Tambah dulu.')),
      );
      return;
    }
    final cs = Theme.of(context).colorScheme;
    final chosen = await showModalBottomSheet<Customer>(
      context: context,
      backgroundColor: cs.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'Pilih Customer',
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
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
        context,
        MaterialPageRoute(builder: (_) => pageBuilder(chosen.id)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final stats = ref.watch(dashboardProvider);
    final tanggal = DateFormat(
      'EEEE, d MMMM y',
      'id_ID',
    ).format(DateTime.now());

    return stats.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(message: 'Gagal memuat: $e'),
      data: (s) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(dashboardProvider),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Greeting ────────────────────────────────────────────────────
            Text('Halo, Admin 👋', style: textTheme.titleLarge),
            const SizedBox(height: 2),
            Text(tanggal, style: textTheme.bodyMedium),
            const SizedBox(height: 20),

            // ── Hero card piutang total ──────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    cs.surfaceContainerHighest,
                    cs.surfaceContainer,
                    cs.surfaceContainerHighest.withValues(alpha: 0.74),
                  ],
                  stops: const [0, 0.55, 1],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cs.surfaceContainerHighest),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 20,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'TOTAL PIUTANG AKTIF',
                          style: textTheme.labelSmall,
                        ),
                      ),
                      Icon(
                        Icons.trending_up_rounded,
                        size: 20,
                        color: cs.primary.withValues(alpha: 0.82),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      formatRupiah(s.totalPiutang),
                      style: textTheme.displayMedium?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'dari ${s.customerBerhutang} customer berhutang',
                    style: textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Stat cards ──────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'Bayar Bulan Ini',
                    value: formatRupiah(s.bayarBulanIni),
                    valueColor: cs.tertiary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatCard(
                    label: 'Customer Berhutang',
                    value: '${s.customerBerhutang}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Aksi Cepat ──────────────────────────────────────────────────
            Text('AKSI CEPAT', style: textTheme.labelSmall),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final gap = constraints.maxWidth < 360 ? 8.0 : 10.0;
                final tileWidth = (constraints.maxWidth - (gap * 2)) / 3;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    SizedBox(
                      width: tileWidth,
                      child: _QuickActionButton(
                        icon: Icons.payments_outlined,
                        label: 'Bayar',
                        onPressed: () => _pilihCustomerLalu(
                          context,
                          ref,
                          (id) => PaymentFormPage(customerId: id),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: tileWidth,
                      child: _QuickActionButton(
                        icon: Icons.person_add_outlined,
                        label: 'Customer',
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CustomerFormPage(),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: tileWidth,
                      child: _QuickActionButton(
                        icon: Icons.add_shopping_cart_outlined,
                        label: 'Barang',
                        onPressed: () => _pilihCustomerLalu(
                          context,
                          ref,
                          (id) => PurchaseFormPage(customerId: id),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // ── Hutang Terbesar ─────────────────────────────────────────────
            Text('HUTANG TERBESAR', style: textTheme.labelSmall),
            const SizedBox(height: 8),
            if (s.topHutang.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 42,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: cs.surfaceContainerHighest),
                  color: cs.surfaceContainer.withValues(alpha: 0.38),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cs.primaryContainer.withValues(alpha: 0.38),
                      ),
                      child: Icon(
                        Icons.inventory_2_outlined,
                        color: cs.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Tidak ada piutang berjalan.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )
            else
              Card(
                child: Column(
                  children: [
                    for (int i = 0; i < s.topHutang.length; i++) ...[
                      if (i > 0)
                        Divider(
                          height: 1,
                          indent: 72,
                          color: cs.surfaceContainerHighest,
                        ),
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: cs.primaryContainer,
                          child: Text(
                            _inisial(s.topHutang[i].customer.nama),
                            style: TextStyle(
                              color: cs.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        title: Text(
                          s.topHutang[i].customer.nama,
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: Text(
                          formatRupiah(s.topHutang[i].sisa),
                          style: textTheme.labelLarge?.copyWith(
                            color: cs.primary,
                          ),
                        ),
                        onTap: () => context.push(
                          '/customers/${s.topHutang[i].customer.id}',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainer.withValues(alpha: 0.44),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.primary.withValues(alpha: 0.88)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: cs.primary),
              const SizedBox(width: 6),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    softWrap: false,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
