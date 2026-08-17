import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sandiapp/app_providers.dart';
import 'package:sandiapp/data/models/customer.dart';
import 'package:sandiapp/data/models/purchase.dart';
import 'package:sandiapp/data/repositories/app_repository.dart';
import 'package:sandiapp/features/customers/customer_detail_page.dart';

import '../fakes/fake_backend.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));
  final t0 = DateTime.utc(2026, 1, 1);

  AppRepository makeRepo({String? noHp}) => AppRepository(
        FakeBackend(
          customers: [Customer(id: 'c1', nama: 'WIWIK', noHp: noHp, createdAt: t0, updatedAt: t0)],
          purchases: [
            Purchase(id: 'p1', customerId: 'c1', namaBarang: 'HP', hargaJual: 500000,
                tanggalBeli: DateTime(2026, 1, 1), createdAt: t0, updatedAt: t0),
            Purchase(id: 'p2', customerId: 'c1', namaBarang: 'TV', hargaJual: 500000,
                tanggalBeli: DateTime(2026, 2, 1), createdAt: t0, updatedAt: t0),
            Purchase(id: 'p3', customerId: 'c1', namaBarang: 'AC', hargaJual: 500000,
                tanggalBeli: DateTime(2026, 3, 1), createdAt: t0, updatedAt: t0),
          ],
          payments: const [],
        ),
        currentUserId: () => 'admin-1',
      );

  Future<void> pump(WidgetTester tester, AppRepository repo) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [repoProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: CustomerDetailPage(customerId: 'c1')),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('badge Nasabah Setia muncul untuk >= 3 transaksi + 360 section', (tester) async {
    await pump(tester, makeRepo());
    expect(find.text('Nasabah Setia'), findsOneWidget);
    await tester.dragUntilVisible(
        find.text('RINGKASAN CUSTOMER'), find.byType(CustomScrollView), const Offset(0, -300));
    expect(find.text('RINGKASAN CUSTOMER'), findsOneWidget);
  });

  testWidgets('tombol Ingatkan via WA disabled tanpa no_hp valid', (tester) async {
    await pump(tester, makeRepo());
    await tester.dragUntilVisible(
        find.text('Ingatkan via WA'), find.byType(CustomScrollView), const Offset(0, -300));
    final btn = tester.widget<OutlinedButton>(
        find.ancestor(of: find.text('Ingatkan via WA'), matching: find.byType(OutlinedButton)));
    expect(btn.onPressed, isNull);
  });

  testWidgets('tombol Ingatkan via WA aktif dengan no_hp valid', (tester) async {
    await pump(tester, makeRepo(noHp: '081234567890'));
    await tester.dragUntilVisible(
        find.text('Ingatkan via WA'), find.byType(CustomScrollView), const Offset(0, -300));
    final btn = tester.widget<OutlinedButton>(
        find.ancestor(of: find.text('Ingatkan via WA'), matching: find.byType(OutlinedButton)));
    expect(btn.onPressed, isNotNull);
  });
}
