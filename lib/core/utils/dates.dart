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

/// 'Hari ini' / 'Kemarin' / 'N hari lalu' (< 7 hari) / fallback [tampilTanggal].
String relativeDay(DateTime d, DateTime today) {
  final days = DateTime(today.year, today.month, today.day)
      .difference(DateTime(d.year, d.month, d.day))
      .inDays;
  if (days <= 0) return 'Hari ini';
  if (days == 1) return 'Kemarin';
  if (days < 7) return '$days hari lalu';
  return tampilTanggal(d);
}

/// 'Agustus 2026'
String bulanTahun(int year, int month) =>
    DateFormat('MMMM yyyy', 'id_ID').format(DateTime(year, month));

/// Rentang bulan [awal inklusif, akhir eksklusif).
(DateTime, DateTime) monthRange(int year, int month) =>
    (DateTime(year, month), DateTime(year, month + 1));
