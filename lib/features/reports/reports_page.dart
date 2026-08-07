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
        if (!_bulanan) return _content(years, 'Tahunan', years);
        final monthlyAsync = ref.watch(profitMonthlyProvider(tahun));
        return monthlyAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => EmptyState(message: 'Gagal memuat: $e'),
          data: (rows) => _content(rows, 'Bulanan $tahun', years),
        );
      },
    );
  }

  Widget _content(List<ProfitRow> rows, String judul, List<ProfitRow> tahunList) {
    return ListView(padding: const EdgeInsets.all(12), children: [
      Row(children: [
        Expanded(
            child: Text('Keuntungan ($judul)',
                style: Theme.of(context).textTheme.titleMedium)),
        DropdownButton<int>(
          value: _tahun ?? tahunList.last.year,
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
      SizedBox(
        height: 220,
        child: rows.isEmpty
            ? const Center(child: Text('Tidak ada data pada periode ini.'))
            : BarChart(BarChartData(
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(
                    topTitles: AxisTitles(), rightTitles: AxisTitles()),
                barGroups: [
                  for (var i = 0; i < rows.length; i++)
                    BarChartGroupData(x: i, barRods: [
                      BarChartRodData(toY: rows[i].keuntungan / 1000000, width: 18),
                    ]),
                ],
              )),
      ),
      const Center(child: Text('Sumbu Y: juta rupiah')),
      const SizedBox(height: 12),
      for (final r in rows)
        ListTile(
          dense: true,
          title: Text(r.month == 0 ? '${r.year}' : bulanTahun(r.year, r.month)),
          subtitle: Text(
              '${r.qty} barang · jual ${formatRupiah(r.penjualan)} · modal ${formatRupiah(r.modal)}'),
          trailing: Text(formatRupiah(r.keuntungan),
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      if (_bulanan)
        TextButton(
            onPressed: () => setState(() => _bulanan = false),
            child: const Text('Lihat tahunan')),
      const Padding(
        padding: EdgeInsets.all(8),
        child: Text('Catatan: barang tanpa harga beli tidak dihitung.'),
      ),
    ]);
  }
}
