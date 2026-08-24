import 'package:flutter_test/flutter_test.dart';
import 'package:sandiapp/core/logic/funds.dart';
import 'package:sandiapp/data/models/fund_ledger_entry.dart';
import 'package:sandiapp/data/models/fund_source.dart';
import 'package:sandiapp/data/models/payment.dart';
import 'package:sandiapp/data/models/purchase.dart';

void main() {
  final now = DateTime.utc(2026, 8, 24, 10);
  final sandi = FundSource(
    id: 'sandi',
    nama: 'Sandi',
    colorKey: 'green',
    createdAt: now,
    updatedAt: now,
  );
  final ika = FundSource(
    id: 'ika',
    nama: 'Ika',
    colorKey: 'gold',
    createdAt: now,
    updatedAt: now,
  );

  FundLedgerEntry opening(String id, int amount) => FundLedgerEntry(
    id: 'opening-$id',
    fundSourceId: id,
    tanggal: DateTime(2026, 8, 24),
    tipe: 'saldo_awal',
    jumlahDelta: amount,
    referenceType: 'migration',
    createdAt: now,
    updatedAt: now,
  );

  Purchase purchase({
    int jual = 2000000,
    String? fundSourceId,
    DateTime? deletedAt,
  }) => Purchase(
    id: 'purchase',
    customerId: 'customer',
    namaBarang: 'HP',
    hargaJual: jual,
    tanggalBeli: DateTime(2026, 8, 24),
    fundSourceId: fundSourceId,
    createdAt: now,
    updatedAt: now,
    deletedAt: deletedAt,
  );

  Payment payment({
    int jumlah = 500000,
    String? fundSourceId,
    String status = 'verified',
    DateTime? deletedAt,
  }) => Payment(
    id: 'payment',
    customerId: 'customer',
    jumlah: jumlah,
    tanggalBayar: DateTime(2026, 8, 24),
    fundSourceId: fundSourceId,
    statusVerifikasi: status,
    createdAt: now,
    updatedAt: now,
    deletedAt: deletedAt,
  );

  test('saldo sumber = ledger + transaksi - pembayaran verified', () {
    final result = calculateFundSummary(
      sources: [sandi, ika],
      ledger: [opening(sandi.id, 36100000), opening(ika.id, 80625000)],
      purchases: [purchase(fundSourceId: sandi.id)],
      payments: [payment(fundSourceId: sandi.id)],
      totalPiutang: 118225000,
    );

    expect(result.bySourceId(sandi.id).saldo, 37600000);
    expect(result.bySourceName('Ika').saldo, 80625000);
    expect(result.total, 118225000);
    expect(result.isConsistent, isTrue);
  });

  test('payment pending tidak mengurangi sumber', () {
    final result = calculateFundSummary(
      sources: [sandi, ika],
      ledger: [opening(sandi.id, 36100000), opening(ika.id, 80625000)],
      purchases: const [],
      payments: [payment(fundSourceId: sandi.id, status: 'pending')],
      totalPiutang: 116725000,
    );

    expect(result.bySourceId(sandi.id).saldo, 36100000);
    expect(result.isConsistent, isTrue);
  });

  test('soft-deleted rows tidak masuk kalkulasi', () {
    final result = calculateFundSummary(
      sources: [sandi, ika],
      ledger: [
        opening(sandi.id, 36100000),
        opening(ika.id, 80625000),
        opening(sandi.id, 1000000).copyWith(deletedAt: () => now),
      ],
      purchases: [purchase(fundSourceId: sandi.id, deletedAt: now)],
      payments: [payment(fundSourceId: sandi.id, deletedAt: now)],
      totalPiutang: 116725000,
    );

    expect(result.total, 116725000);
    expect(result.isConsistent, isTrue);
  });

  test('transfer berpasangan menjaga total nol', () {
    final transfer = FundTransfer(
      keluar: FundLedgerEntry(
        id: 'out',
        fundSourceId: sandi.id,
        tanggal: DateTime(2026, 8, 24),
        tipe: 'alih_keluar',
        jumlahDelta: -1000000,
        referenceType: 'transfer',
        transferGroupId: 'transfer-1',
        createdAt: now,
        updatedAt: now,
      ),
      masuk: FundLedgerEntry(
        id: 'in',
        fundSourceId: ika.id,
        tanggal: DateTime(2026, 8, 24),
        tipe: 'alih_masuk',
        jumlahDelta: 1000000,
        referenceType: 'transfer',
        transferGroupId: 'transfer-1',
        createdAt: now,
        updatedAt: now,
      ),
    );

    expect(transfer.keluar.jumlahDelta, -1000000);
    expect(transfer.masuk.jumlahDelta, 1000000);
    expect(transfer.keluar.jumlahDelta + transfer.masuk.jumlahDelta, 0);
  });
}
