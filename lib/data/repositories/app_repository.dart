import '../../core/logic/budget.dart';
import '../../core/logic/collectibility.dart';
import '../../core/logic/customer_stats.dart';
import '../../core/logic/fifo.dart';
import '../../core/logic/profit.dart';
import '../models/budget_entry.dart';
import '../models/customer.dart';
import '../models/payment.dart';
import '../models/purchase.dart';
import 'backend.dart';

enum CustomerFilter { semua, berhutang, macet, lunas, arsip }
enum CustomerSort { nama, hutang, terakhirBayar }

class MonthlyTotal {
  final int year, month, total;
  const MonthlyTotal({required this.year, required this.month, required this.total});
}

class PaymentActivityItem {
  final Payment payment;
  final String customerName;
  const PaymentActivityItem({required this.payment, required this.customerName});
}

class CustomerDetailData {
  final Customer customer;
  final List<PurchaseStatus> items; // urut FIFO (tertua dulu)
  final List<Payment> payments; // urut terbaru dulu
  final Balance balance;
  final CustomerStats stats;
  const CustomerDetailData({
    required this.customer,
    required this.items,
    required this.payments,
    required this.balance,
    required this.stats,
  });
}

class DashboardStats {
  final int totalPiutang, bayarBulanIni, customerBerhutang;
  final int macetTotal, macetCount;
  final List<CustomerWithBalance> topHutang; // maks 5, sisa > 0
  final List<MonthlyTotal> trend;            // 6 bulan terakhir, urut lama -> baru
  final List<PaymentActivityItem> aktivitas; // maks 8, terbaru dulu
  const DashboardStats({
    required this.totalPiutang,
    required this.bayarBulanIni,
    required this.customerBerhutang,
    required this.macetTotal,
    required this.macetCount,
    required this.topHutang,
    required this.trend,
    required this.aktivitas,
  });
}

/// Satu-satunya pintu data untuk UI. Platform beda hanya di [Backend].
class AppRepository {
  final Backend backend;
  final String? Function() currentUserId;
  final void Function()? onLocalWrite; // Android: minta sync; web: null

  AppRepository(this.backend, {required this.currentUserId, this.onLocalWrite});

  DateTime _now() => DateTime.now().toUtc();

  Future<List<CustomerWithBalance>> customers({
    String query = '',
    CustomerFilter filter = CustomerFilter.semua,
    CustomerSort sort = CustomerSort.nama,
    DateTime? today,
  }) async {
    final t = today ?? DateTime.now();
    final cs = await backend.readCustomers();
    final ps = await backend.readPurchases();
    final pm = await backend.readPayments();
    final rows = [
      for (final c in cs)
        () {
          final myP = ps.where((p) => p.customerId == c.id).toList();
          final myM = pm
              .where((p) => p.customerId == c.id && p.statusVerifikasi == 'verified')
              .toList();
          final b = balanceOf(myP, myM);
          final lastPay = myM.isEmpty
              ? null
              : myM.map((e) => e.tanggalBayar).reduce((a, b) => a.isAfter(b) ? a : b);
          final firstBuy = myP.isEmpty
              ? null
              : myP.map((e) => e.tanggalBeli).reduce((a, b) => a.isBefore(b) ? a : b);
          return CustomerWithBalance(
            customer: c,
            totalHutang: b.totalHutang,
            totalBayar: b.totalBayar,
            lastPaymentAt: lastPay,
            collectibility: b.sisa > 0
                ? collectibilityOf(lastPayment: lastPay, firstPurchase: firstBuy, today: t)
                : null,
          );
        }(),
    ];

    final q = query.trim().toLowerCase();
    Iterable<CustomerWithBalance> filtered =
        q.isEmpty ? rows : rows.where((r) => r.customer.nama.toLowerCase().contains(q));
    filtered = switch (filter) {
      CustomerFilter.arsip => filtered.where((r) => r.customer.isArchived),
      CustomerFilter.berhutang => filtered.where((r) => !r.customer.isArchived && r.sisa > 0),
      CustomerFilter.macet => filtered.where(
          (r) => !r.customer.isArchived && r.collectibility == Collectibility.macet),
      CustomerFilter.lunas => filtered.where(
          (r) => !r.customer.isArchived && r.totalHutang > 0 && r.sisa <= 0),
      CustomerFilter.semua => filtered.where((r) => !r.customer.isArchived),
    };

    final list = filtered.toList();
    list.sort((a, b) => switch (sort) {
          CustomerSort.hutang => b.sisa.compareTo(a.sisa),
          CustomerSort.terakhirBayar =>
            (b.lastPaymentAt ?? DateTime(1900)).compareTo(a.lastPaymentAt ?? DateTime(1900)),
          CustomerSort.nama =>
            a.customer.nama.toLowerCase().compareTo(b.customer.nama.toLowerCase()),
        });
    return list;
  }

  Future<CustomerDetailData> customerDetail(String customerId) async {
    final cs = await backend.readCustomers();
    final ps = await backend.readPurchases();
    final pm = await backend.readPayments();
    final customer = cs.singleWhere((c) => c.id == customerId);
    final myPurchases = ps.where((p) => p.customerId == customerId).toList();
    final myPayments = pm.where((p) => p.customerId == customerId).toList()
      ..sort((a, b) => b.tanggalBayar.compareTo(a.tanggalBayar));
    final balance = balanceOf(myPurchases, myPayments);
    return CustomerDetailData(
      customer: customer,
      items: allocateFifo(myPurchases, balance.totalBayar),
      payments: myPayments,
      balance: balance,
      stats: customerStatsOf(myPurchases, myPayments),
    );
  }

  Future<DashboardStats> dashboardStats({DateTime? now}) async {
    final n = now ?? DateTime.now();
    final balances = await customers(today: n);
    final berhutang = balances.where((b) => b.sisa > 0).toList()
      ..sort((a, b) => b.sisa.compareTo(a.sisa));
    final macet = berhutang.where((b) => b.collectibility == Collectibility.macet).toList();

    final pm = (await backend.readPayments())
        .where((p) => p.statusVerifikasi == 'verified')
        .toList();
    final bayarBulanIni = pm
        .where((p) => p.tanggalBayar.year == n.year && p.tanggalBayar.month == n.month)
        .fold<int>(0, (s, p) => s + p.jumlah);

    final trend = [
      for (var i = 5; i >= 0; i--)
        () {
          final m = DateTime(n.year, n.month - i);
          final total = pm
              .where((p) => p.tanggalBayar.year == m.year && p.tanggalBayar.month == m.month)
              .fold<int>(0, (s, p) => s + p.jumlah);
          return MonthlyTotal(year: m.year, month: m.month, total: total);
        }(),
    ];

    final cs = await backend.readCustomers();
    final namaById = {for (final c in cs) c.id: c.nama};
    final sortedPm = [...pm]..sort((a, b) {
        final c = b.tanggalBayar.compareTo(a.tanggalBayar);
        return c != 0 ? c : b.createdAt.compareTo(a.createdAt);
      });
    final aktivitas = [
      for (final p in sortedPm.take(8))
        if (namaById.containsKey(p.customerId))
          PaymentActivityItem(payment: p, customerName: namaById[p.customerId]!),
    ];

    return DashboardStats(
      totalPiutang: berhutang.fold(0, (s, b) => s + b.sisa),
      bayarBulanIni: bayarBulanIni,
      customerBerhutang: berhutang.length,
      macetTotal: macet.fold(0, (s, b) => s + b.sisa),
      macetCount: macet.length,
      topHutang: berhutang.take(5).toList(),
      trend: trend,
      aktivitas: aktivitas,
    );
  }

  Future<List<ProfitRow>> profitYearly() async =>
      profitPerYear(await backend.readPurchases());
  Future<List<ProfitRow>> profitMonthly(int year) async =>
      profitPerMonth(await backend.readPurchases(), year);

  Future<List<BudgetLine>> budgetMonth(int year, int month) async {
    final all = await backend.readBudgetEntries();
    final awalBulan = DateTime(year, month);
    final akhirBulan = DateTime(year, month + 1);
    final sebelum = all.where((e) => e.tanggal.isBefore(awalBulan)).toList();
    final saldoAwal =
        withRunningSaldo(sebelum).fold<int>(0, (_, l) => l.saldo);
    final bulanIni = all
        .where((e) =>
            !e.tanggal.isBefore(awalBulan) && e.tanggal.isBefore(akhirBulan))
        .toList();
    return withRunningSaldo(bulanIni, saldoAwal: saldoAwal);
  }

  Future<void> saveCustomer(Customer v) => _write(() => backend.writeCustomer(
      v.copyWith(createdBy: v.createdBy ?? currentUserId(), updatedAt: _now())));
  Future<void> savePurchase(Purchase v) => _write(() async {
    final now = _now();
    final userId = currentUserId();
    await backend.writePurchase(
        v.copyWith(createdBy: v.createdBy ?? userId, updatedAt: now));
    await _syncBudgetFromPurchase(v, now, userId);
  });
  Future<void> savePayment(Payment v) => _write(() async {
    final now = _now();
    final userId = currentUserId();
    await backend.writePayment(
        v.copyWith(createdBy: v.createdBy ?? userId, updatedAt: now));
    await _syncBudgetFromPayment(v, now, userId);
  });
  Future<void> saveBudgetEntry(BudgetEntry v) => _write(() => backend.writeBudgetEntry(
      v.copyWith(createdBy: v.createdBy ?? currentUserId(), updatedAt: _now())));

  Future<void> deleteCustomer(String id) =>
      _write(() => backend.deleteCustomer(id, _now()));
  /// Soft delete nasabah + semua transaksi & pembayarannya.
  Future<void> deleteCustomerCascade(String id) =>
      _write(() => backend.deleteCustomerCascade(id, _now()));
  Future<void> deletePurchase(String id) =>
      _write(() async {
        await backend.deletePurchase(id, _now());
        await _deleteBudgetBySource('purchase', id, _now());
      });
  Future<void> deletePayment(String id) =>
      _write(() async {
        await backend.deletePayment(id, _now());
        await _deleteBudgetBySource('payment', id, _now());
      });
  Future<void> deleteBudgetEntry(String id) =>
      _write(() => backend.deleteBudgetEntry(id, _now()));

  Future<T> _write<T>(Future<T> Function() action) async {
    final r = await action();
    onLocalWrite?.call();
    return r;
  }

  // ---- budget auto-sync helpers ----

  Future<void> _syncBudgetFromPurchase(
      Purchase p, DateTime now, String? userId) async {
    // Hapus budget lama jika ada (untuk handle edit)
    await _deleteBudgetBySource('purchase', p.id, now);
    // Buat entry baru
    final entry = BudgetEntry(
      id: 'budget-purchase-${p.id}',
      tanggal: p.tanggalBeli,
      namaTransaksi: '${await _namaCustomer(p.customerId)} - ${p.namaBarang}',
      tipe: 'pengeluaran',
      jumlah: p.hargaJual,
      createdBy: userId,
      sourceType: 'purchase',
      sourceId: p.id,
      createdAt: now,
      updatedAt: now,
    );
    await backend.writeBudgetEntry(entry);
  }

  Future<void> _syncBudgetFromPayment(
      Payment p, DateTime now, String? userId) async {
    // Hapus budget lama jika ada (untuk handle edit)
    await _deleteBudgetBySource('payment', p.id, now);
    // Buat entry baru
    final entry = BudgetEntry(
      id: 'budget-payment-${p.id}',
      tanggal: p.tanggalBayar,
      namaTransaksi: '${await _namaCustomer(p.customerId)} - Pembayaran',
      tipe: 'pemasukan',
      jumlah: p.jumlah,
      createdBy: userId,
      sourceType: 'payment',
      sourceId: p.id,
      createdAt: now,
      updatedAt: now,
    );
    await backend.writeBudgetEntry(entry);
  }

  Future<void> _deleteBudgetBySource(
      String sourceType, String sourceId, DateTime now) async {
    final all = await backend.readBudgetEntries();
    final existing = all.where((e) =>
        e.sourceType == sourceType && e.sourceId == sourceId).toList();
    for (final e in existing) {
      await backend.deleteBudgetEntry(e.id, now);
    }
  }

  Future<String> _namaCustomer(String customerId) async {
    final cs = await backend.readCustomers();
    final c = cs.where((c) => c.id == customerId).firstOrNull;
    return c?.nama ?? 'Nasabah';
  }
}
