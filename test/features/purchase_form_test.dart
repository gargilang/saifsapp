import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sandiapp/app_providers.dart';
import 'package:sandiapp/data/models/fund_source.dart';
import 'package:sandiapp/data/repositories/app_repository.dart';
import 'package:sandiapp/features/purchases/purchase_form_page.dart';

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

  Future<void> pump(WidgetTester tester, FakeBackend backend) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repoProvider.overrideWithValue(
            AppRepository(backend, currentUserId: () => 'admin-1'),
          ),
        ],
        child: const MaterialApp(home: PurchaseFormPage(customerId: 'c1')),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> fillRequired(WidgetTester tester) async {
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'HP');
    await tester.enterText(fields.at(1), '2.000.000');
  }

  testWidgets('transaksi baru wajib memilih sumber dana', (tester) async {
    await pump(tester, FakeBackend(fundSources: [sandi, ika]));
    await fillRequired(tester);

    await tester.tap(find.text('Simpan'));
    await tester.pump();

    expect(find.text('Pilih sumber dana'), findsOneWidget);
  });

  testWidgets('pilihan Sandi tersimpan pada transaksi', (tester) async {
    final backend = FakeBackend(fundSources: [sandi, ika]);
    await pump(tester, backend);
    await tester.tap(find.text('Sandi'));
    await fillRequired(tester);

    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(backend.purchases.single.fundSourceId, sandi.id);
  });
}
