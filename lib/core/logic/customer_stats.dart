import '../../data/models/payment.dart';
import '../../data/models/purchase.dart';

class CustomerStats {
  final int jumlahTransaksi;
  final int totalBelanja;
  final int totalBayar;
  final int? rataRataCicilan;
  final int? kecepatanLunasHari;
  final DateTime? customerSejak;
  final bool customerSetia;
  const CustomerStats({
    required this.jumlahTransaksi,
    required this.totalBelanja,
    required this.totalBayar,
    required this.rataRataCicilan,
    required this.kecepatanLunasHari,
    required this.customerSejak,
    required this.customerSetia,
  });
}

/// Statistik "Customer 360" — murni dari purchases + payments satu customer.
CustomerStats customerStatsOf(List<Purchase> purchases, List<Payment> payments) {
  final verified = payments.where((p) => p.statusVerifikasi == 'verified').toList();
  final totalBayar = verified.fold<int>(0, (s, p) => s + p.jumlah);
  final totalBelanja = purchases.fold<int>(0, (s, p) => s + p.hargaJual);

  DateTime? sejak;
  for (final p in purchases) {
    if (sejak == null || p.tanggalBeli.isBefore(sejak)) sejak = p.tanggalBeli;
  }

  // Kecepatan lunas: untuk tiap barang (urut FIFO), hitung hari dari
  // tanggalBeli sampai kumulatif pembayaran mencapai kumulatif harga barang
  // tersebut. Hanya barang yang benar-benar lunas dihitung.
  int? kecepatan;
  if (purchases.isNotEmpty && verified.isNotEmpty) {
    final sortedP = [...purchases]..sort((a, b) {
        final c = a.tanggalBeli.compareTo(b.tanggalBeli);
        return c != 0 ? c : a.createdAt.compareTo(b.createdAt);
      });
    final sortedM = [...verified]..sort((a, b) => a.tanggalBayar.compareTo(b.tanggalBayar));

    final daysList = <int>[];
    var cumHarga = 0;
    var cumBayar = 0;
    var mi = 0;
    for (final p in sortedP) {
      cumHarga += p.hargaJual;
      while (mi < sortedM.length && cumBayar < cumHarga) {
        cumBayar += sortedM[mi].jumlah;
        mi++;
      }
      if (cumBayar >= cumHarga) {
        daysList.add(sortedM[mi - 1].tanggalBayar.difference(p.tanggalBeli).inDays);
      } else {
        break; // barang ini & sesudahnya belum lunas
      }
    }
    if (daysList.isNotEmpty) {
      kecepatan = (daysList.reduce((a, b) => a + b) / daysList.length).round();
    }
  }

  return CustomerStats(
    jumlahTransaksi: purchases.length,
    totalBelanja: totalBelanja,
    totalBayar: totalBayar,
    rataRataCicilan: verified.isEmpty ? null : (totalBayar / verified.length).round(),
    kecepatanLunasHari: kecepatan,
    customerSejak: sejak,
    customerSetia: purchases.length >= 3,
  );
}
