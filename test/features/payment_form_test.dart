import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sandiapp/app_providers.dart';
import 'package:sandiapp/data/repositories/app_repository.dart';
import 'package:sandiapp/features/payments/payment_form_page.dart';

import '../fakes/fake_backend.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  Future<void> pump(WidgetTester tester, FakeBackend backend) =>
      tester.pumpWidget(ProviderScope(
        overrides: [
          repoProvider.overrideWithValue(
              AppRepository(backend, currentUserId: () => 'admin-1')),
        ],
        child: const MaterialApp(home: PaymentFormPage(customerId: 'c1')),
      ));

  testWidgets('chip nominal cepat mengisi field terformat', (tester) async {
    await pump(tester, FakeBackend());
    await tester.pumpAndSettle();
    await tester.tap(find.text('100rb'));
    await tester.pump();
    expect(find.text('100.000'), findsOneWidget);
  });

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
    await tester.tap(find.text('200rb'));
    await tester.pump();
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(backend.payments.single.jumlah, 200000);
    expect(backend.payments.single.customerId, 'c1');
  });
}
