import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app_providers.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/money.dart';
import '../../data/models/customer.dart';
import '../../data/repositories/app_repository.dart';
import '../../widgets/collectibility_dot.dart';
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
    final tanggal = DateFormat('EEEE, d MMMM y', 'id_ID').format(DateTime.now());

    return stats.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(message: 'Gagal memuat: $e'),
      data: (s) {
        final now = DateTime.now();
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(dashboardProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Greeting ────────────────────────────────────────────────
              Text('Halo, Admin 👋', style: textTheme.titleLarge),
              const SizedBox(height: 2),
              Text(tanggal, style: textTheme.bodyMedium),
              const SizedBox(height: 20),

              // ── Hero card piutang total ───────────────────────────────
              _HeroCard(totalPiutang: s.totalPiutang, customerBerhutang: s.customerBerhutang),
              const SizedBox(height: 12),

              // ── Stat cards: masuk bulan ini + macet ───────────────────
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      label: 'Masuk Bulan Ini',
                      value: formatRupiahCompact(s.bayarBulanIni),
                      valueColor: cs.tertiary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: StatCard(
                      label: s.macetCount == 0
                          ? 'Macet >90 Hari'
                          : 'Macet >90 Hari · ${s.macetCount}',
                      value: s.macetCount == 0 ? '—' : formatRupiahCompact(s.macetTotal),
                      valueColor: s.macetCount > 0 ? cs.error : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Tren pembayaran 6 bulan ────────────────────────────────
              Text('TREN PEMBAYARAN 6 BULAN', style: textTheme.labelSmall),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 16, 16, 4),
                  child: _TrendChart(trend: s.trend),
                ),
              ),
              const SizedBox(height: 20),

              // ── Aksi Cepat ──────────────────────────────────────────────
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
                            MaterialPageRoute(builder: (_) => const CustomerFormPage()),
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

              // ── Aktivitas Terakhir ──────────────────────────────────────
              Text('AKTIVITAS TERAKHIR', style: textTheme.labelSmall),
              const SizedBox(height: 8),
              if (s.aktivitas.isEmpty)
                const EmptyState(message: 'Belum ada pembayaran tercatat.')
              else
                Card(
                  child: Column(
                    children: [
                      for (int i = 0; i < s.aktivitas.length; i++) ...[
                        if (i > 0)
                          Divider(height: 1, indent: 72, color: cs.surfaceContainerHighest),
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: cs.primaryContainer,
                            child: Text(
                              _inisial(s.aktivitas[i].customerName),
                              style: TextStyle(
                                  color: cs.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13),
                            ),
                          ),
                          title: Text(
                            s.aktivitas[i].customerName,
                            style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(relativeDay(s.aktivitas[i].payment.tanggalBayar, now)),
                          trailing: Text(
                            '+${formatRupiahCompact(s.aktivitas[i].payment.jumlah)}',
                            style: textTheme.labelLarge?.copyWith(color: cs.tertiary),
                          ),
                          onTap: () =>
                              context.push('/customers/${s.aktivitas[i].payment.customerId}'),
                        ),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // ── Hutang Terbesar ─────────────────────────────────────────
              Text('HUTANG TERBESAR', style: textTheme.labelSmall),
              const SizedBox(height: 8),
              if (s.topHutang.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 42),
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
                        child: Icon(Icons.inventory_2_outlined, color: cs.primary, size: 28),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Tidak ada piutang berjalan.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
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
                              color: cs.surfaceContainerHighest),
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: cs.primaryContainer,
                            child: Text(
                              _inisial(s.topHutang[i].customer.nama),
                              style: TextStyle(
                                  color: cs.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13),
                            ),
                          ),
                          title: Text(
                            s.topHutang[i].customer.nama,
                            style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CollectibilityDot(status: s.topHutang[i].collectibility),
                              const SizedBox(width: 6),
                              Text(
                                formatRupiah(s.topHutang[i].sisa),
                                style: textTheme.labelLarge?.copyWith(color: cs.primary),
                              ),
                            ],
                          ),
                          onTap: () =>
                              context.push('/customers/${s.topHutang[i].customer.id}'),
                        ),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 80),
            ],
          ),
        );
      },
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

class _HeroCard extends StatelessWidget {
  final int totalPiutang, customerBerhutang;
  const _HeroCard({required this.totalPiutang, required this.customerBerhutang});

  Widget _circle(double d, Color c) =>
      Container(width: d, height: d, decoration: BoxDecoration(shape: BoxShape.circle, color: c));

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
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
              offset: const Offset(0, 12)),
        ],
      ),
      child: Stack(children: [
        Positioned(right: -40, top: -40, child: _circle(140, cs.primary.withValues(alpha: 0.06))),
        Positioned(right: 30, bottom: -50, child: _circle(100, cs.primary.withValues(alpha: 0.04))),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text('TOTAL PIUTANG AKTIF', style: textTheme.labelSmall)),
              Icon(Icons.trending_up_rounded, size: 20, color: cs.primary.withValues(alpha: 0.82)),
            ]),
            const SizedBox(height: 10),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: totalPiutang.toDouble()),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, v, child) => FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  formatRupiahCompact(v.round()),
                  style: textTheme.displayMedium
                      ?.copyWith(color: cs.primary, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text('dari $customerBerhutang customer berhutang', style: textTheme.bodyMedium),
          ],
        ),
      ]),
    );
  }
}

class _TrendChart extends StatelessWidget {
  final List<MonthlyTotal> trend;
  const _TrendChart({required this.trend});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final maxV = trend.fold<double>(0, (m, t) => t.total > m ? t.total.toDouble() : m);
    return SizedBox(
      height: 150,
      child: LineChart(LineChartData(
        minY: 0,
        maxY: maxV == 0 ? 1 : maxV * 1.2,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: 1,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= trend.length) return const SizedBox.shrink();
                final t = trend[i];
                return Text(
                  DateFormat('MMM', 'id_ID').format(DateTime(t.year, t.month)),
                  style: Theme.of(context).textTheme.labelSmall,
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < trend.length; i++)
                FlSpot(i.toDouble(), trend[i].total.toDouble())
            ],
            isCurved: true,
            color: cs.primary,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: cs.primary.withValues(alpha: 0.15)),
          ),
        ],
      )),
    );
  }
}
