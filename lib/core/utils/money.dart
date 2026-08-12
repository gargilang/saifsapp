import 'package:intl/intl.dart';

final _rupiah = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

/// 1500000 -> 'Rp 1.500.000'
String formatRupiah(int value) => _rupiah.format(value);

/// 'Rp 1.500.000' / '1500000' -> 1500000. Input non-digit dibuang.
int parseRupiah(String input) {
  final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
  return digits.isEmpty ? 0 : int.parse(digits);
}

/// 87500000 -> 'Rp 87,5 jt' · 850000 -> 'Rp 850 rb' · 5000000000 -> 'Rp 5 M'.
/// Di bawah 100 rb -> format penuh [formatRupiah]. Maks 2 desimal, trailing zero dibuang.
String formatRupiahCompact(int value) {
  final sign = value < 0 ? '-' : '';
  final abs = value.abs();
  String trim(double v) {
    var s = v.toStringAsFixed(2);
    if (s.contains('.')) {
      s = s.replaceAll(RegExp(r'0+$'), '');
      if (s.endsWith('.')) s = s.substring(0, s.length - 1);
    }
    return s.replaceAll('.', ',');
  }
  if (abs >= 1000000000) return '${sign}Rp ${trim(abs / 1000000000)} M';
  if (abs >= 1000000) return '${sign}Rp ${trim(abs / 1000000)} jt';
  if (abs >= 100000) return '${sign}Rp ${trim(abs / 1000)} rb';
  return formatRupiah(value);
}
