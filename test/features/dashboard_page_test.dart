import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sandiapp/app_providers.dart';
import 'package:sandiapp/data/models/customer.dart';
import 'package:sandiapp/data/models/payment.dart';
import 'package:sandiapp/data/models/purchase.dart';
import 'package:sandiapp/data/repositories/app_repository.dart';
import 'package:sandiapp/features/dashboard/dashboard_page.dart';

import '../fakes/fake_backend.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));
  final now = DateTime.now();

  AppRepository makeRepo() => AppRepository(
        FakeBackend(
          customers: [
            Customer(id: 'c1', nama: 'WIWIK', createdAt: now, updatedAt: now),
            Customer(id: 'c2', nama: 'BUDI', createdAt: now, updatedAt: now),
          ],
          purchases: [
            Purchase(id: 'p1', customerId: 'c1', namaBarang: 'HP', hargaJual: 2000000,
                tanggalBeli: now.subtract(const Duration(days: 200)), createdAt: now, updatedAt: now),
            Purchase(id: 'p2', customerId: 'c2', namaBarang: 'TV', hargaJual: 1000000,
                tanggalBeli: now.subtract(const Duration(days: 10)), createdAt: now, updatedAt: now),
          ],
          payments: [
            Payment(id: 'm1', customerId: 'c1', jumlah: 500000,
                tanggalBayar: now.subtract(const Duration(days: 100)), createdAt: now, updatedAt: now),
            Payment(id: 'm2', customerId: 'c2', jumlah: 300000, tanggalBayar: now,
                createdAt: now, updatedAt: now),
          ],
        ),
        currentUserId: () => 'admin-1',
      );

  testWidgets('menampilkan hero, macet, tren, aktivitas terakhir', (tester) async {
    // ListView lazy — perbesar viewport agar semua section ter-build.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(ProviderScope(
      overrides: [repoProvider.overrideWithValue(makeRepo())],
      child: const MaterialApp(home: Scaffold(body: DashboardPage())),
    ));
    await tester.pumpAndSettle();

    expect(find.text('TOTAL PIUTANG AKTIF'), findsOneWidget);
    expect(find.text('Rp 2,2 jt'), findsOneWidget); // (2jt-500rb)+(1jt-300rb)
    expect(find.textContaining('MACET'), findsWidgets);
    expect(find.text('AKTIVITAS TERAKHIR'), findsOneWidget);
    expect(find.text('BUDI'), findsWidgets); // aktivitas + hutang terbesar
    expect(find.byType(LineChart), findsOneWidget);
  });
}
