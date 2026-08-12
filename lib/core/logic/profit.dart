import '../../data/models/purchase.dart';

class ProfitRow {
  final int year, month; // month == 0 -> baris agregat tahunan
  final int qty, penjualan, modal;
  const ProfitRow({
    required this.year,
    required this.month,
    required this.qty,
    required this.penjualan,
    required this.modal,
  });
  int get keuntungan => penjualan - modal;
}

ProfitRow _aggregate(int year, int month, List<Purchase> items) => ProfitRow(
      year: year,
      month: month,
      qty: items.length,
      penjualan: items.fold(0, (s, p) => s + p.hargaJual),
      modal: items.fold(0, (s, p) => s + (p.hargaBeli ?? 0)),
    );

/// Keuntungan per bulan dalam [year]. Purchase tanpa hargaBeli dikecualikan.
List<ProfitRow> profitPerMonth(List<Purchase> purchases, int year) {
  final byMonth = <int, List<Purchase>>{};
  for (final p in purchases.where(
      (p) => p.hargaBeli != null && p.tanggalBeli.year == year)) {
    byMonth.putIfAbsent(p.tanggalBeli.month, () => []).add(p);
  }
  return [
    for (final m in byMonth.keys.toList()..sort()) _aggregate(year, m, byMonth[m]!),
  ];
}

/// Keuntungan per tahun (semua tahun yang ada datanya).
List<ProfitRow> profitPerYear(List<Purchase> purchases) {
  final byYear = <int, List<Purchase>>{};
  for (final p in purchases.where((p) => p.hargaBeli != null)) {
    byYear.putIfAbsent(p.tanggalBeli.year, () => []).add(p);
  }
  return [
    for (final y in byYear.keys.toList()..sort()) _aggregate(y, 0, byYear[y]!),
  ];
}
