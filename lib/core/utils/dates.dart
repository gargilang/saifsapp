import 'package:intl/intl.dart';

final _iso = DateFormat('yyyy-MM-dd');

/// DateTime -> 'yyyy-MM-dd' (untuk kolom date Postgres)
String dateOnly(DateTime d) => _iso.format(d);

/// Hari ini tanpa komponen jam.
DateTime today() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

/// '8 Agu 2026'
String tampilTanggal(DateTime d) => DateFormat('d MMM yyyy', 'id_ID').format(d);

/// 'Agustus 2026'
String bulanTahun(int year, int month) =>
    DateFormat('MMMM yyyy', 'id_ID').format(DateTime(year, month));

/// Rentang bulan [awal inklusif, akhir eksklusif).
(DateTime, DateTime) monthRange(int year, int month) =>
    (DateTime(year, month), DateTime(year, month + 1));
