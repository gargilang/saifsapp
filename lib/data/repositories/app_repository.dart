import '../../core/logic/budget.dart';
import '../../core/logic/fifo.dart';
import '../../core/logic/profit.dart';
import '../models/budget_entry.dart';
import '../models/customer.dart';
import '../models/payment.dart';
import '../models/purchase.dart';
import 'backend.dart';

class CustomerDetailData {
  final Customer customer;
  final List<PurchaseStatus> items; // urut FIFO (tertua dulu)
  final List<Payment> payments; // urut terbaru dulu
  final Balance balance;
  const CustomerDetailData({
    required this.customer,
    required this.items,
    required this.payments,
    required this.balance,
  });
}

class DashboardStats {
  final int totalPiutang, bayarBulanIni, customerBerhutang;
  final List<CustomerWithBalance> topHutang; // maks 5, sisa > 0
  const DashboardStats({
    required this.totalPiutang,
    required this.bayarBulanIni,
    required this.customerBerhutang,
    required this.topHutang,
  });
}

/// Satu-satunya pintu data untuk UI. Platform beda hanya di [Backend].
class AppRepository {
  final Backend backend;
  final String? Function() currentUserId;
  final void Function()? onLocalWrite; // Android: minta sync; web: null

  AppRepository(this.backend, {required this.currentUserId, this.onLocalWrite});

  DateTime _now() => DateTime.now().toUtc();

  Future<List<CustomerWithBalance>> customers(
      {String query = '', bool includeArchived = false, bool sortByHutang = false}) async {
    final cs = await backend.readCustomers();
    final ps = await backend.readPurchases();
    final pm = await backend.readPayments();
    final rows = [
      for (final c in cs)
        if (includeArchived || !c.isArchived)
          () {
            final b = balanceOf(
              ps.where((p) => p.customerId == c.id).toList(),
              pm.where((p) => p.customerId == c.id).toList(),
            );
            return CustomerWithBalance(
                customer: c, totalHutang: b.totalHutang, totalBayar: b.totalBayar);
          }(),
    ];
    final q = query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? rows
        : rows.where((r) => r.customer.nama.toLowerCase().contains(q)).toList();
    filtered.sort((a, b) => sortByHutang
        ? b.sisa.compareTo(a.sisa)
        : a.customer.nama.toLowerCase().compareTo(b.customer.nama.toLowerCase()));
    return filtered;
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
    );
  }

  Future<DashboardStats> dashboardStats({DateTime? now}) async {
    final n = now ?? DateTime.now();
    final balances = await customers();
    final berhutang = balances.where((b) => b.sisa > 0).toList()
      ..sort((a, b) => b.sisa.compareTo(a.sisa));
    final pm = await backend.readPayments();
    final bayarBulanIni = pm
        .where((p) =>
            p.statusVerifikasi == 'verified' &&
            p.tanggalBayar.year == n.year &&
            p.tanggalBayar.month == n.month)
        .fold<int>(0, (s, p) => s + p.jumlah);
    return DashboardStats(
      totalPiutang: berhutang.fold(0, (s, b) => s + b.sisa),
      bayarBulanIni: bayarBulanIni,
      customerBerhutang: berhutang.length,
      topHutang: berhutang.take(5).toList(),
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
  Future<void> savePurchase(Purchase v) => _write(() => backend.writePurchase(
      v.copyWith(createdBy: v.createdBy ?? currentUserId(), updatedAt: _now())));
  Future<void> savePayment(Payment v) => _write(() => backend.writePayment(
      v.copyWith(createdBy: v.createdBy ?? currentUserId(), updatedAt: _now())));
  Future<void> saveBudgetEntry(BudgetEntry v) => _write(() => backend.writeBudgetEntry(
      v.copyWith(createdBy: v.createdBy ?? currentUserId(), updatedAt: _now())));

  Future<void> deleteCustomer(String id) =>
      _write(() => backend.deleteCustomer(id, _now()));
  Future<void> deletePurchase(String id) =>
      _write(() => backend.deletePurchase(id, _now()));
  Future<void> deletePayment(String id) =>
      _write(() => backend.deletePayment(id, _now()));
  Future<void> deleteBudgetEntry(String id) =>
      _write(() => backend.deleteBudgetEntry(id, _now()));

  Future<T> _write<T>(Future<T> Function() action) async {
    final r = await action();
    onLocalWrite?.call();
    return r;
  }
}
