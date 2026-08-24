import '../models/budget_entry.dart';
import '../models/customer.dart';
import '../models/fund_ledger_entry.dart';
import '../models/fund_source.dart';
import '../models/payment.dart';
import '../models/purchase.dart';

/// Akses penyimpanan per platform. Baca = data aktif (non-deleted) saja.
abstract class Backend {
  Future<List<Customer>> readCustomers();
  Future<List<Purchase>> readPurchases();
  Future<List<Payment>> readPayments();
  Future<List<BudgetEntry>> readBudgetEntries();
  Future<List<FundSource>> readFundSources();
  Future<List<FundLedgerEntry>> readFundLedgerEntries();
  Future<void> writeCustomer(Customer v);
  Future<void> writePurchase(Purchase v);
  Future<void> writePayment(Payment v);
  Future<void> writeBudgetEntry(BudgetEntry v);
  Future<void> writeFundTransfer(FundTransfer transfer);
  Future<void> deleteCustomer(String id, DateTime at);

  /// Soft delete customer + semua purchases & payments terkait.
  Future<void> deleteCustomerCascade(String id, DateTime at);
  Future<void> deletePurchase(String id, DateTime at);
  Future<void> deletePayment(String id, DateTime at);
  Future<void> deleteBudgetEntry(String id, DateTime at);
}
