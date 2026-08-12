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

  testWidgets('filter chip Macet menyaring customer yang macet', (tester) async {
    final now = DateTime.now();
    final repo = AppRepository(
      FakeBackend(
        customers: [
          Customer(id: 'c1', nama: 'WIWIK', createdAt: now, updatedAt: now),
          Customer(id: 'c2', nama: 'IKA', createdAt: now, updatedAt: now),
        ],
        purchases: [
          Purchase(id: 'p1', customerId: 'c1', namaBarang: 'HP', hargaJual: 2000000,
              tanggalBeli: now.subtract(const Duration(days: 120)), createdAt: now, updatedAt: now),
          Purchase(id: 'p2', customerId: 'c2', namaBarang: 'TV', hargaJual: 1000000,
              tanggalBeli: now.subtract(const Duration(days: 5)), createdAt: now, updatedAt: now),
        ],
        payments: [
          Payment(id: 'm1', customerId: 'c1', jumlah: 500000,
              tanggalBayar: now.subtract(const Duration(days: 100)), createdAt: now, updatedAt: now),
          Payment(id: 'm2', customerId: 'c2', jumlah: 200000,
              tanggalBayar: now.subtract(const Duration(days: 1)), createdAt: now, updatedAt: now),
        ],
      ),
      currentUserId: () => 'admin-1',
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [repoProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: Scaffold(body: CustomersPage())),
    ));
    await tester.pumpAndSettle();
    expect(find.text('WIWIK'), findsOneWidget);
    expect(find.text('IKA'), findsOneWidget);

    await tester.tap(find.text('Macet'));
    await tester.pumpAndSettle();
    expect(find.text('WIWIK'), findsOneWidget); // macet, 100 hari lalu
    expect(find.text('IKA'), findsNothing);     // lancar, 1 hari lalu
  });
}
