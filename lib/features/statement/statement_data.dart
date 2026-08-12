import '../../core/logic/fifo.dart';
import '../../data/repositories/app_repository.dart';

class StatementItem {
  final String namaBarang, statusLabel;
  final DateTime tanggal;
  final int harga, sisa;
  const StatementItem({
    required this.namaBarang,
    required this.statusLabel,
    required this.tanggal,
    required this.harga,
    required this.sisa,
  });
}

class StatementPayment {
  final DateTime tanggal;
  final int jumlah;
  final String metode;
  const StatementPayment({required this.tanggal, required this.jumlah, required this.metode});
}

class StatementData {
  final String nama;
  final String? noHp, alamat;
  final int totalBelanja, totalBayar, sisaHutang;
  final List<StatementItem> items;
  final List<StatementPayment> payments;
  final DateTime generatedAt;
  const StatementData({
    required this.nama,
    this.noHp,
    this.alamat,
    required this.totalBelanja,
    required this.totalBayar,
    required this.sisaHutang,
    required this.items,
    required this.payments,
    required this.generatedAt,
  });
}

String _statusLabel(ItemStatus s) => switch (s) {
      ItemStatus.lunas => 'LUNAS',
      ItemStatus.sebagian => 'SEBAGIAN',
      ItemStatus.belum => 'BELUM',
    };

/// Rangkum [CustomerDetailData] jadi data siap-cetak (murni, tanpa I/O).
StatementData buildStatementData(CustomerDetailData d, {DateTime? now}) => StatementData(
      nama: d.customer.nama,
      noHp: d.customer.noHp,
      alamat: d.customer.alamat,
      totalBelanja: d.balance.totalHutang,
      totalBayar: d.balance.totalBayar,
      sisaHutang: d.balance.sisa,
      items: [
        for (final i in d.items)
          StatementItem(
            namaBarang: i.purchase.namaBarang,
            statusLabel: _statusLabel(i.status),
            tanggal: i.purchase.tanggalBeli,
            harga: i.purchase.hargaJual,
            sisa: i.sisa,
          ),
      ],
      payments: [
        for (final p in d.payments)
          StatementPayment(tanggal: p.tanggalBayar, jumlah: p.jumlah, metode: p.metode),
      ],
      generatedAt: now ?? DateTime.now(),
    );
