import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sandiapp/app_providers.dart';
import 'package:sandiapp/data/models/fund_ledger_entry.dart';
import 'package:sandiapp/data/models/fund_source.dart';
import 'package:sandiapp/data/models/purchase.dart';
import 'package:sandiapp/data/repositories/app_repository.dart';
import 'package:sandiapp/features/budget/budget_page.dart';

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

  FakeBackend seededBackend({int sandiBalance = 36100000}) => FakeBackend(
    fundSources: [sandi, ika],
    fundLedger: [opening('sandi', sandiBalance), opening('ika', 80625000)],
    purchases: [
      Purchase(
        id: 'historical',
        customerId: 'c1',
        namaBarang: 'Saldo awal',
        hargaJual: 116725000,
        tanggalBeli: DateTime(2026, 8, 1),
        createdAt: now,
        updatedAt: now,
      ),
    ],
  );

  Future<void> pump(WidgetTester tester, FakeBackend backend) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repoProvider.overrideWithValue(
            AppRepository(backend, currentUserId: () => 'admin-1'),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: BudgetPage())),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('menampilkan Sandi, Ika, total piutang, dan saldo', (
    tester,
  ) async {
    await pump(tester, seededBackend());

    expect(find.text('Sumber dana'), findsOneWidget);
    expect(find.text('Sandi'), findsOneWidget);
    expect(find.text('Rp 36.100.000'), findsOneWidget);
    expect(find.text('Ika'), findsOneWidget);
    expect(find.text('Rp 80.625.000'), findsOneWidget);
    expect(find.text('Rp 116.725.000'), findsWidgets);
    expect(find.text('Saldo sesuai piutang'), findsOneWidget);
  });

  testWidgets('menampilkan warning saat total sumber tidak konsisten', (
    tester,
  ) async {
    await pump(tester, seededBackend(sandiBalance: 36000000));

    expect(
      find.text('Total sumber dana tidak sama dengan piutang'),
      findsOneWidget,
    );
  });

  testWidgets('alih modal mengurangi Sandi dan menambah Ika', (tester) async {
    await pump(tester, seededBackend());
    await tester.tap(find.byTooltip('Alih modal'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('fund-transfer-amount')),
        matching: find.byType(TextFormField),
      ),
      '1.000.000',
    );

    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(find.text('Rp 35.100.000'), findsOneWidget);
    expect(find.text('Rp 81.625.000'), findsOneWidget);
  });

  testWidgets('riwayat menggabungkan pasangan transfer', (tester) async {
    final backend = seededBackend();
    backend.fundLedger.addAll([
      FundLedgerEntry(
        id: 'out',
        fundSourceId: 'sandi',
        tanggal: DateTime(2026, 8, 25),
        tipe: 'alih_keluar',
        jumlahDelta: -1000000,
        referenceType: 'transfer',
        transferGroupId: 'group-1',
        createdAt: now.add(const Duration(minutes: 1)),
        updatedAt: now.add(const Duration(minutes: 1)),
      ),
      FundLedgerEntry(
        id: 'in',
        fundSourceId: 'ika',
        tanggal: DateTime(2026, 8, 25),
        tipe: 'alih_masuk',
        jumlahDelta: 1000000,
        referenceType: 'transfer',
        transferGroupId: 'group-1',
        createdAt: now.add(const Duration(minutes: 1)),
        updatedAt: now.add(const Duration(minutes: 1)),
      ),
    ]);
    await pump(tester, backend);

    await tester.tap(find.byTooltip('Riwayat sumber dana'));
    await tester.pumpAndSettle();

    expect(find.text('Sandi -> Ika'), findsOneWidget);
    expect(find.text('Alih modal'), findsOneWidget);
  });
}
