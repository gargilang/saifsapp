import 'package:intl/intl.dart';

final _rupiah = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

/// 1500000 -> 'Rp 1.500.000'
String formatRupiah(int value) => _rupiah.format(value);

/// 'Rp 1.500.000' / '1500000' -> 1500000. Input non-digit dibuang.
int parseRupiah(String input) {
  final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
  return digits.isEmpty ? 0 : int.parse(digits);
}
