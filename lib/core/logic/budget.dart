import '../../data/models/budget_entry.dart';

class BudgetLine {
  final BudgetEntry entry;
  final int saldo; // saldo setelah entri ini
  const BudgetLine({required this.entry, required this.saldo});
}

/// Saldo berjalan, urut (tanggal, createdAt). pemasukan +, pengeluaran -.
List<BudgetLine> withRunningSaldo(List<BudgetEntry> entries, {int saldoAwal = 0}) {
  final sorted = [...entries]..sort((a, b) {
      final c = a.tanggal.compareTo(b.tanggal);
      return c != 0 ? c : a.createdAt.compareTo(b.createdAt);
    });
  var saldo = saldoAwal;
  return [
    for (final e in sorted)
      BudgetLine(
          entry: e,
          saldo: saldo += e.tipe == 'pemasukan' ? e.jumlah : -e.jumlah),
  ];
}
