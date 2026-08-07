import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sandiapp/app_providers.dart';
import 'package:sandiapp/data/models/customer.dart';
import 'package:sandiapp/data/models/payment.dart';
import 'package:sandiapp/data/models/purchase.dart';
import 'package:sandiapp/data/repositories/app_repository.dart';
import 'package:sandiapp/features/customers/customers_page.dart';

import '../fakes/fake_backend.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));
  final t0 = DateTime.utc(2026, 8, 1);

  AppRepository makeRepo() => AppRepository(
        FakeBackend(
          customers: [
            Customer(id: 'c1', nama: 'WIWIK', createdAt: t0, updatedAt: t0),
            Customer(id: 'c2', nama: 'IKA', createdAt: t0, updatedAt: t0),
          ],
          purchases: [
            Purchase(id: 'p1', customerId: 'c1', namaBarang: 'HP', hargaJual: 2000000,
                tanggalBeli: t0, createdAt: t0, updatedAt: t0),
          ],
          payments: [
            Payment(id: 'm1', customerId: 'c1', jumlah: 500000, tanggalBayar: t0,
                createdAt: t0, updatedAt: t0),
          ],
        ),
        currentUserId: () => 'admin-1',
      );

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(ProviderScope(
        overrides: [repoProvider.overrideWithValue(makeRepo())],
        child: const MaterialApp(home: Scaffold(body: CustomersPage())),
      ));

  testWidgets('menampilkan customer + sisa hutang terformat', (tester) async {
    await pump(tester);
    await tester.pumpAndSettle();
    expect(find.text('WIWIK'), findsOneWidget);
    expect(find.text('IKA'), findsOneWidget);
    expect(find.textContaining('1.500.000'), findsOneWidget); // sisa WIWIK
  });

  testWidgets('search memfilter nama', (tester) async {
    await pump(tester);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'ika');
    await tester.pumpAndSettle();
    expect(find.text('WIWIK'), findsNothing);
    expect(find.text('IKA'), findsOneWidget);
  });
}
