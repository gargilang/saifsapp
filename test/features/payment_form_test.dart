import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sandiapp/app_providers.dart';
import 'package:sandiapp/data/models/fund_ledger_entry.dart';
import 'package:sandiapp/data/models/fund_source.dart';
import 'package:sandiapp/data/models/purchase.dart';
import 'package:sandiapp/data/repositories/app_repository.dart';
import 'package:sandiapp/features/payments/payment_form_page.dart';

import '../fakes/fake_backend.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  final now = DateTime.utc(2026, 8, 25, 10);
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

  FundLedgerEntry opening(String sourceId, int amount) => FundLedgerEntry(
    id: 'opening-$sourceId',
    fundSourceId: sourceId,
    tanggal: DateTime(2026, 8, 25),
    tipe: 'saldo_awal',
    jumlahDelta: amount,
    referenceType: 'migration',
    createdAt: now,
    updatedAt: now,
  );

  Future<void> pump(WidgetTester tester, FakeBackend backend) =>
      tester.pumpWidget(
        ProviderScope(
          overrides: [
            repoProvider.overrideWithValue(
              AppRepository(backend, currentUserId: () => 'admin-1'),
            ),
          ],
          child: const MaterialApp(home: PaymentFormPage(customerId: 'c1')),
        ),
      );

  testWidgets('jumlah 0 ditolak validasi', (tester) async {
    await pump(tester, FakeBackend());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan'));
    await tester.pump();
    expect(find.text('Jumlah harus lebih dari 0'), findsOneWidget);
  });

  testWidgets('simpan pembayaran valid masuk backend', (tester) async {
    final backend = FakeBackend();
    await pump(tester, backend);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '200.000');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(backend.payments.single.jumlah, 200000);
    expect(backend.payments.single.customerId, 'c1');
  });

  testWidgets('metode default adalah Transfer', (tester) async {
    await pump(tester, FakeBackend());
    await tester.pumpAndSettle();
    // Cari dropdown dan verifikasi nilai default
    final dropdown = tester.widget<DropdownButtonFormField<String>>(
      find.byType(DropdownButtonFormField<String>),
    );
    expect(dropdown.initialValue, 'transfer');
  });

  testWidgets('pembayaran menampilkan Mengurangi dana', (tester) async {
    await pump(tester, FakeBackend(fundSources: [sandi, ika]));
    await tester.pumpAndSettle();

    expect(find.text('Mengurangi dana'), findsOneWidget);
    expect(find.text('Sandi'), findsOneWidget);
    expect(find.text('Ika'), findsOneWidget);
  });

  testWidgets('default sumber mengikuti transaksi FIFO aktif', (tester) async {
    final backend = FakeBackend(
      fundSources: [sandi, ika],
      fundLedger: [opening('sandi', 1000000)],
      purchases: [
        Purchase(
          id: 'p1',
          customerId: 'c1',
          namaBarang: 'HP',
          hargaJual: 1000000,
          tanggalBeli: DateTime(2026, 8, 1),
          fundSourceId: sandi.id,
          createdAt: now,
          updatedAt: now,
        ),
      ],
    );
    await pump(tester, backend);
    await tester.pumpAndSettle();

    final selector = tester.widget<SegmentedButton<String>>(
      find.byType(SegmentedButton<String>),
    );
    expect(selector.selected, {sandi.id});
  });

  testWidgets('saldo historis tidak memilih sumber secara otomatis', (
    tester,
  ) async {
    final backend = FakeBackend(
      fundSources: [sandi, ika],
      fundLedger: [opening('sandi', 1000000)],
      purchases: [
        Purchase(
          id: 'p1',
          customerId: 'c1',
          namaBarang: 'HP',
          hargaJual: 1000000,
          tanggalBeli: DateTime(2026, 8, 1),
          createdAt: now,
          updatedAt: now,
        ),
      ],
    );
    await pump(tester, backend);
    await tester.pumpAndSettle();

    final selector = tester.widget<SegmentedButton<String>>(
      find.byType(SegmentedButton<String>),
    );
    expect(selector.selected, isEmpty);
  });
}
