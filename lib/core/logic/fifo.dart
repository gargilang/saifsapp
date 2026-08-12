import '../../data/models/payment.dart';
import '../../data/models/purchase.dart';

enum ItemStatus { lunas, sebagian, belum }

class PurchaseStatus {
  final Purchase purchase;
  final int allocated; // bagian total bayar yang meng-cover barang ini (FIFO)
  const PurchaseStatus({required this.purchase, required this.allocated});

  int get sisa => purchase.hargaJual - allocated;
  ItemStatus get status {
    if (allocated <= 0) return ItemStatus.belum;
    if (allocated >= purchase.hargaJual) return ItemStatus.lunas;
    return ItemStatus.sebagian;
  }
}

class Balance {
  final int totalHutang, totalBayar;
  const Balance(this.totalHutang, this.totalBayar);
  int get sisa => totalHutang - totalBayar;
}

/// Total hutang & bayar satu customer. Hanya payment 'verified' yang dihitung.
Balance balanceOf(List<Purchase> purchases, List<Payment> payments) {
  final hutang = purchases.fold<int>(0, (s, p) => s + p.hargaJual);
  final bayar = payments
      .where((p) => p.statusVerifikasi == 'verified')
      .fold<int>(0, (s, p) => s + p.jumlah);
  return Balance(hutang, bayar);
}

/// Alokasi totalBayar ke barang tertua dulu (FIFO). Hasil urut tertua -> termuda.
List<PurchaseStatus> allocateFifo(List<Purchase> purchases, int totalBayar) {
  final sorted = [...purchases]..sort((a, b) {
      final c = a.tanggalBeli.compareTo(b.tanggalBeli);
      return c != 0 ? c : a.createdAt.compareTo(b.createdAt);
    });
  var remaining = totalBayar;
  return [
    for (final p in sorted)
      () {
        final alloc = remaining <= 0
            ? 0
            : (remaining >= p.hargaJual ? p.hargaJual : remaining);
        remaining -= alloc;
        return PurchaseStatus(purchase: p, allocated: alloc);
      }()
  ];
}
