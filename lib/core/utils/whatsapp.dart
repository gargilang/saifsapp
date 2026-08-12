import '../brand.dart';
import 'money.dart';

const kDefaultWaTemplate =
    "Assalamu'alaikum {nama}, ini pengingat dari {bisnis}. "
    'Sisa pembayaran kredit Anda saat ini {sisa_hutang}. '
    'Terima kasih atas kerja samanya.';

/// Rapikan nomor HP Indonesia jadi format wa.me (62xxxxxxxxxx). null jika
/// tidak valid (kosong atau terlalu pendek/panjang).
String? normalizePhoneId(String? raw) {
  if (raw == null) return null;
  var d = raw.replaceAll(RegExp(r'\D'), '');
  if (d.isEmpty) return null;
  if (d.startsWith('0')) {
    d = '62${d.substring(1)}';
  } else if (d.startsWith('8')) {
    d = '62$d';
  }
  if (!d.startsWith('62')) return null;
  if (d.length < 10 || d.length > 15) return null;
  return d;
}

Uri buildWaReminderUri({required String phone, required String message}) =>
    Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(message)}');

/// Placeholder: {nama}, {sisa_hutang}, {bisnis}. {bisnis} selalu diisi [kBrandName].
String renderWaTemplate(String template, {required String nama, required int sisaHutang}) =>
    template
        .replaceAll('{nama}', nama)
        .replaceAll('{sisa_hutang}', formatRupiah(sisaHutang))
        .replaceAll('{bisnis}', kBrandName);
