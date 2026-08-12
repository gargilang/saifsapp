/// Status kolektibilitas piutang (aging), dihitung dari hari sejak transaksi
/// terakhir. Hanya relevan untuk customer dengan sisa hutang > 0.
enum Collectibility { lancar, perhatian, kurangLancar, macet }

/// Tanggal acuan = pembayaran terakhir; jika belum pernah bayar -> pembelian
/// pertama. [today] disuntik supaya deterministik untuk test.
Collectibility collectibilityOf({
  required DateTime? lastPayment,
  required DateTime? firstPurchase,
  required DateTime today,
}) {
  final ref = lastPayment ?? firstPurchase;
  if (ref == null) return Collectibility.macet; // anomali: berhutang tanpa jejak tanggal
  final days = DateTime(today.year, today.month, today.day)
      .difference(DateTime(ref.year, ref.month, ref.day))
      .inDays;
  if (days <= 30) return Collectibility.lancar;
  if (days <= 60) return Collectibility.perhatian;
  if (days <= 90) return Collectibility.kurangLancar;
  return Collectibility.macet;
}

String collectibilityLabel(Collectibility c) => switch (c) {
      Collectibility.lancar => 'Lancar',
      Collectibility.perhatian => 'Dalam Perhatian',
      Collectibility.kurangLancar => 'Kurang Lancar',
      Collectibility.macet => 'Macet',
    };
