import 'package:flutter_test/flutter_test.dart';
import 'package:sandiapp/data/models/customer.dart';
import 'package:sandiapp/data/models/purchase.dart';
import 'package:sandiapp/data/models/payment.dart';
import 'package:sandiapp/data/models/budget_entry.dart';
import 'package:sandiapp/data/models/fund_ledger_entry.dart';
import 'package:sandiapp/data/models/fund_source.dart';

void main() {
  final now = DateTime.utc(2026, 8, 8, 10);

  test('Customer json roundtrip', () {
    final c = Customer(
      id: 'c1',
      nama: 'WIWIK',
      noHp: '0812',
      isArchived: false,
      createdAt: now,
      updatedAt: now,
    );
    final back = Customer.fromJson(c.toJson());
    expect(back.id, 'c1');
    expect(back.nama, 'WIWIK');
    expect(back.noHp, '0812');
    expect(back.isArchived, false);
    expect(back.deletedAt, isNull);
  });

  test('Purchase json roundtrip, tanggal date-only', () {
    final p = Purchase(
      id: 'p1',
      customerId: 'c1',
      namaBarang: 'HP',
      hargaJual: 2050000,
      hargaBeli: 1700000,
      tanggalBeli: DateTime(2020, 12, 30),
      fundSourceId: 'sandi',
      createdAt: now,
      updatedAt: now,
    );
    final j = p.toJson();
    expect(j['tanggal_beli'], '2020-12-30');
    final back = Purchase.fromJson(j);
    expect(back.hargaJual, 2050000);
    expect(back.hargaBeli, 1700000);
    expect(back.tanggalBeli, DateTime(2020, 12, 30));
    expect(back.fundSourceId, 'sandi');
    expect(back.copyWith(fundSourceId: () => null).fundSourceId, isNull);
  });

  test('Payment default metode/sumber/statusVerifikasi', () {
    final pm = Payment(
      id: 'm1',
      customerId: 'c1',
      jumlah: 300000,
      tanggalBayar: DateTime(2021, 1, 30),
      fundSourceId: 'ika',
      createdAt: now,
      updatedAt: now,
    );
    expect(pm.metode, 'tunai');
    expect(pm.sumber, 'admin');
    expect(pm.statusVerifikasi, 'verified');
    expect(Payment.fromJson(pm.toJson()).jumlah, 300000);
    expect(Payment.fromJson(pm.toJson()).fundSourceId, 'ika');
    expect(pm.copyWith(fundSourceId: () => null).fundSourceId, isNull);
  });

  test('FundSource json roundtrip', () {
    final source = FundSource(
      id: 'sandi',
      nama: 'Sandi',
      colorKey: 'green',
      createdBy: 'admin',
      createdAt: now,
      updatedAt: now,
    );
    final back = FundSource.fromJson(source.toJson());
    expect(back.id, 'sandi');
    expect(back.nama, 'Sandi');
    expect(back.colorKey, 'green');
    expect(back.isActive, isTrue);
  });

  test('FundLedgerEntry json roundtrip, tanggal date-only', () {
    final entry = FundLedgerEntry(
      id: 'entry',
      fundSourceId: 'sandi',
      tanggal: DateTime(2026, 8, 24),
      tipe: 'saldo_awal',
      jumlahDelta: 36100000,
      referenceType: 'migration',
      catatan: 'Saldo awal r2',
      createdAt: now,
      updatedAt: now,
    );
    final json = entry.toJson();
    expect(json['tanggal'], '2026-08-24');
    expect(json['fund_source_id'], 'sandi');
    expect(json['jumlah_delta'], 36100000);
    final back = FundLedgerEntry.fromJson(json);
    expect(back.tipe, 'saldo_awal');
    expect(back.tanggal, DateTime(2026, 8, 24));
  });

  test('BudgetEntry json roundtrip', () {
    final b = BudgetEntry(
      id: 'b1',
      tanggal: DateTime(2021, 4, 27),
      namaTransaksi: 'Belanja',
      tipe: 'pengeluaran',
      jumlah: 160000,
      createdAt: now,
      updatedAt: now,
    );
    final back = BudgetEntry.fromJson(b.toJson());
    expect(back.tipe, 'pengeluaran');
    expect(back.jumlah, 160000);
  });

  test('CustomerWithBalance.sisa', () {
    final c = Customer(id: 'c1', nama: 'A', createdAt: now, updatedAt: now);
    final wb = CustomerWithBalance(
      customer: c,
      totalHutang: 6500000,
      totalBayar: 5300000,
    );
    expect(wb.sisa, 1200000);
  });

  test('copyWith mengubah field', () {
    final c = Customer(id: 'c1', nama: 'A', createdAt: now, updatedAt: now);
    final c2 = c.copyWith(nama: 'B', isArchived: true);
    expect(c2.nama, 'B');
    expect(c2.isArchived, true);
    expect(c2.id, 'c1');
  });
}
