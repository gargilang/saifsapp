import '../../data/models/fund_ledger_entry.dart';
import '../../data/models/fund_source.dart';
import '../../data/models/payment.dart';
import '../../data/models/purchase.dart';

class FundBalance {
  final FundSource source;
  final int saldo;

  const FundBalance({required this.source, required this.saldo});
}

class FundSummary {
  final List<FundBalance> balances;
  final int totalPiutang;

  const FundSummary({required this.balances, required this.totalPiutang});

  factory FundSummary.fromBalances(
    List<FundSource> sources,
    Map<String, int> values, {
    required int totalPiutang,
  }) => FundSummary(
    balances: [
      for (final source in sources)
        FundBalance(source: source, saldo: values[source.id] ?? 0),
    ],
    totalPiutang: totalPiutang,
  );

  int get total => balances.fold(0, (sum, row) => sum + row.saldo);

  bool get isConsistent => total == totalPiutang;

  FundBalance bySourceId(String id) =>
      balances.singleWhere((row) => row.source.id == id);

  FundBalance bySourceName(String name) =>
      balances.singleWhere((row) => row.source.nama == name);
}

FundSummary calculateFundSummary({
  required List<FundSource> sources,
  required List<FundLedgerEntry> ledger,
  required List<Purchase> purchases,
  required List<Payment> payments,
  required int totalPiutang,
}) {
  final balances = {for (final source in sources) source.id: 0};
  for (final entry in ledger.where((entry) => entry.deletedAt == null)) {
    balances.update(entry.fundSourceId, (value) => value + entry.jumlahDelta);
  }
  for (final purchase in purchases.where(
    (purchase) => purchase.deletedAt == null && purchase.fundSourceId != null,
  )) {
    balances.update(
      purchase.fundSourceId!,
      (value) => value + purchase.hargaJual,
    );
  }
  for (final payment in payments.where(
    (payment) =>
        payment.deletedAt == null &&
        payment.statusVerifikasi == 'verified' &&
        payment.fundSourceId != null,
  )) {
    balances.update(payment.fundSourceId!, (value) => value - payment.jumlah);
  }
  return FundSummary.fromBalances(
    sources,
    balances,
    totalPiutang: totalPiutang,
  );
}
