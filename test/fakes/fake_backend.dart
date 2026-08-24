import 'package:sandiapp/data/models/budget_entry.dart';
import 'package:sandiapp/data/models/customer.dart';
import 'package:sandiapp/data/models/fund_ledger_entry.dart';
import 'package:sandiapp/data/models/fund_source.dart';
import 'package:sandiapp/data/models/payment.dart';
import 'package:sandiapp/data/models/purchase.dart';
import 'package:sandiapp/data/repositories/backend.dart';

class FakeBackend implements Backend {
  List<Customer> customers;
  List<Purchase> purchases;
  List<Payment> payments;
  List<BudgetEntry> budget;
  List<FundSource> fundSources;
  List<FundLedgerEntry> fundLedger;
  FakeBackend({
    List<Customer>? customers,
    List<Purchase>? purchases,
    List<Payment>? payments,
    List<BudgetEntry>? budget,
    List<FundSource>? fundSources,
    List<FundLedgerEntry>? fundLedger,
  }) : customers = [...?customers],
       purchases = [...?purchases],
       payments = [...?payments],
       budget = [...?budget],
       fundSources = [...?fundSources],
       fundLedger = [...?fundLedger];

  @override
  Future<List<Customer>> readCustomers() async =>
      customers.where((e) => e.deletedAt == null).toList();
  @override
  Future<List<Purchase>> readPurchases() async =>
      purchases.where((e) => e.deletedAt == null).toList();
  @override
  Future<List<Payment>> readPayments() async =>
      payments.where((e) => e.deletedAt == null).toList();
  @override
  Future<List<BudgetEntry>> readBudgetEntries() async =>
      budget.where((e) => e.deletedAt == null).toList();
  @override
  Future<List<FundSource>> readFundSources() async => fundSources
      .where((entry) => entry.deletedAt == null && entry.isActive)
      .toList();
  @override
  Future<List<FundLedgerEntry>> readFundLedgerEntries() async =>
      fundLedger.where((entry) => entry.deletedAt == null).toList();

  @override
  Future<void> writeCustomer(Customer v) async {
    customers = [...customers.where((e) => e.id != v.id), v];
  }

  @override
  Future<void> writePurchase(Purchase v) async {
    purchases = [...purchases.where((e) => e.id != v.id), v];
  }

  @override
  Future<void> writePayment(Payment v) async {
    payments = [...payments.where((e) => e.id != v.id), v];
  }

  @override
  Future<void> writeBudgetEntry(BudgetEntry v) async {
    budget = [...budget.where((e) => e.id != v.id), v];
  }

  @override
  Future<void> writeFundTransfer(FundTransfer transfer) async {
    final groupId = transfer.keluar.transferGroupId;
    if (fundLedger.any((entry) => entry.transferGroupId == groupId)) return;
    fundLedger = [...fundLedger, transfer.keluar, transfer.masuk];
  }

  @override
  Future<void> deleteCustomer(String id, DateTime at) async {
    customers = [
      for (final c in customers) c.id == id ? c.copyWith(deletedAt: at) : c,
    ];
  }

  @override
  Future<void> deleteCustomerCascade(String id, DateTime at) async {
    customers = [
      for (final c in customers) c.id == id ? c.copyWith(deletedAt: at) : c,
    ];
    purchases = [
      for (final p in purchases)
        p.customerId == id ? p.copyWith(deletedAt: at) : p,
    ];
    payments = [
      for (final p in payments)
        p.customerId == id ? p.copyWith(deletedAt: at) : p,
    ];
  }

  @override
  Future<void> deletePurchase(String id, DateTime at) async {
    purchases = [
      for (final p in purchases) p.id == id ? p.copyWith(deletedAt: at) : p,
    ];
  }

  @override
  Future<void> deletePayment(String id, DateTime at) async {
    payments = [
      for (final p in payments) p.id == id ? p.copyWith(deletedAt: at) : p,
    ];
  }

  @override
  Future<void> deleteBudgetEntry(String id, DateTime at) async {
    budget = [
      for (final b in budget) b.id == id ? b.copyWith(deletedAt: at) : b,
    ];
  }
}
