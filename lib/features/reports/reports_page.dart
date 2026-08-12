import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_providers.dart';
import '../../core/logic/profit.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/money.dart';
import '../../widgets/empty_state.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});
  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  bool _bulanan = false;
  int? _tahun;

  @override
  Widget build(BuildContext context) {
    final yearly = ref.watch(profitYearlyProvider);
    return yearly.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(message: 'Gagal memuat: $e'),
      data: (years) {
        if (years.isEmpty) {
          return const EmptyState(
              message: 'Belum ada data keuntungan.\nIsi harga beli pada barang.');
        }
        final tahun = _tahun ?? years.last.year;
        if (!_bulanan) return _content(years, years);
        final monthlyAsync = ref.watch(profitMonthlyProvider(tahun));
        return monthlyAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => EmptyState(message: 'Gagal memuat: $e'),
          data: (rows) => _content(rows, years),
        );
      },
    );
  }

  Widget _content(List<ProfitRow> rows, List<ProfitRow> tahunList) {
    final cs = Theme.of(context).colorScheme;
    return ListView(padding: const EdgeInsets.all(16), children: [
      // ── Header ──────────────────────────────────────────────────────────
      Row(children: [
        Expanded(
            child: Text('Keuntungan',
                style: Theme.of(context).textTheme.titleLarge)),
        DropdownButton<int>(
          value: _tahun ?? tahunList.last.year,
          underline: const SizedBox(),
          borderRadius: BorderRadius.circular(12),
          items: [
            for (final y in tahunList)
              DropdownMenuItem(value: y.year, child: Text('${y.year}')),
          ],
          onChanged: (v) => setState(() {
            _tahun = v;
            _bulanan = true;
          }),
        ),
      ]),
      const SizedBox(height: 12),
      SegmentedButton<bool>(
        segments: const [
          ButtonSegment(value: false, label: Text('Tahunan')),
          ButtonSegment(value: true, label: Text('Bulanan')),
        ],
        selected: {_bulanan},
        onSelectionChanged: (s) => setState(() => _bulanan = s.first),
      ),
      const SizedBox(height: 20),

      // ── Bar Chart ────────────────────────────────────────────────────────
      if (rows.isEmpty)
        const Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('Tidak ada data pada periode ini.')),
        )
      else ...[
        SizedBox(
          height: 220,
          child: BarChart(BarChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: cs.surfaceContainerHighest, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: const AxisTitles(),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, meta) {
                    final i = v.toInt();
                    if (i < 0 || i >= rows.length) return const SizedBox();
                    final label = rows[i].month == 0
                        ? '${rows[i].year}'
                        : '${rows[i].month}';
                    return Text(label,
                        style: TextStyle(
                            fontSize: 10, color: cs.onSurfaceVariant));
                  },
                ),
              ),
            ),
            barGroups: [
              for (var i = 0; i < rows.length; i++)
                BarChartGroupData(x: i, barRods: [
                  BarChartRodData(
                    toY: rows[i].keuntungan / 1000000,
                    width: 18,
                    color: cs.primary,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(6)),
                  ),
                ]),
            ],
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => cs.surfaceContainer,
                getTooltipItem: (group, groupIdx, rod, rodIdx) => BarTooltipItem(
                  formatRupiah((rod.toY * 1000000).toInt()),
                  TextStyle(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 12),
                ),
              ),
            ),
          )),
        ),
        const SizedBox(height: 4),
        Center(
            child: Text('Sumbu Y: juta rupiah',
                style: Theme.of(context).textTheme.labelSmall)),
        const SizedBox(height: 16),
      ],

      // ── List detail ──────────────────────────────────────────────────────
      if (rows.isNotEmpty)
        Card(
          child: Column(children: [
            for (int i = 0; i < rows.length; i++) ...[
              if (i > 0)
                Divider(height: 1, indent: 16, color: cs.surfaceContainerHighest),
              ListTile(
                dense: true,
                title: Text(
                    rows[i].month == 0
                        ? '${rows[i].year}'
                        : bulanTahun(rows[i].year, rows[i].month),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                    '${rows[i].qty} barang · modal ${formatRupiah(rows[i].modal)}'),
                trailing: Text(formatRupiah(rows[i].keuntungan),
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: cs.primary)),
              ),
            ],
          ]),
        ),
      const SizedBox(height: 8),
      Padding(
        padding: const EdgeInsets.all(8),
        child: Text('Catatan: barang tanpa harga beli tidak dihitung.',
            style: Theme.of(context).textTheme.labelSmall),
      ),
    ]);
  }
}
