import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sandiapp/app_providers.dart';
import 'package:sandiapp/data/models/customer.dart';
import 'package:sandiapp/data/models/payment.dart';
import 'package:sandiapp/data/models/purchase.dart';
import 'package:sandiapp/data/repositories/app_repository.dart';
import 'package:sandiapp/features/customers/customer_detail_page.dart';

import '../fakes/fake_backend.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));
  final t0 = DateTime.utc(2026, 1, 1);

  AppRepository makeRepo({String? noHp}) => AppRepository(
    FakeBackend(
      customers: [
        Customer(
          id: 'c1',
          nama: 'WIWIK',
          noHp: noHp,
          createdAt: t0,
          updatedAt: t0,
        ),
      ],
      purchases: [
        Purchase(
          id: 'p1',
          customerId: 'c1',
          namaBarang: 'HP',
          hargaJual: 500000,
          tanggalBeli: DateTime(2026, 1, 1),
          createdAt: t0,
          updatedAt: t0,
        ),
        Purchase(
          id: 'p2',
          customerId: 'c1',
          namaBarang: 'TV',
          hargaJual: 500000,
          tanggalBeli: DateTime(2026, 2, 1),
          createdAt: t0,
          updatedAt: t0,
        ),
        Purchase(
          id: 'p3',
          customerId: 'c1',
          namaBarang: 'AC',
          hargaJual: 500000,
          tanggalBeli: DateTime(2026, 3, 1),
          createdAt: t0,
          updatedAt: t0,
        ),
      ],
      payments: const [],
    ),
    currentUserId: () => 'admin-1',
  );

  AppRepository makeLongRepo() => AppRepository(
    FakeBackend(
      customers: [
        Customer(id: 'c1', nama: 'WIWIK', createdAt: t0, updatedAt: t0),
      ],
      purchases: [
        for (var i = 1; i <= 7; i++)
          Purchase(
            id: 'p$i',
            customerId: 'c1',
            namaBarang: 'Barang $i',
            hargaJual: 500000,
            tanggalBeli: DateTime(2026, 1, i),
            createdAt: DateTime.utc(2026, 1, i),
            updatedAt: DateTime.utc(2026, 1, i),
          ),
      ],
      payments: [
        for (var i = 1; i <= 7; i++)
          Payment(
            id: 'm$i',
            customerId: 'c1',
            jumlah: i * 100000,
            tanggalBayar: DateTime(2026, 2, i),
            createdAt: DateTime.utc(2026, 2, i),
            updatedAt: DateTime.utc(2026, 2, i),
          ),
      ],
    ),
    currentUserId: () => 'admin-1',
  );

  Future<void> pump(WidgetTester tester, AppRepository repo) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [repoProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: CustomerDetailPage(customerId: 'c1')),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('badge Nasabah Setia muncul untuk >= 3 transaksi + 360 section', (
    tester,
  ) async {
    await pump(tester, makeRepo());
    expect(find.text('W'), findsOneWidget);
    expect(find.text('Nasabah Setia'), findsOneWidget);
    await tester.dragUntilVisible(
      find.text('RINGKASAN CUSTOMER'),
      find.byType(CustomScrollView),
      const Offset(0, -300),
    );
    expect(find.text('RINGKASAN CUSTOMER'), findsOneWidget);
  });

  testWidgets('tombol Ingatkan via WA disabled tanpa no_hp valid', (
    tester,
  ) async {
    await pump(tester, makeRepo());
    await tester.dragUntilVisible(
      find.text('Ingatkan via WA'),
      find.byType(CustomScrollView),
      const Offset(0, -300),
    );
    final btn = tester.widget<OutlinedButton>(
      find.ancestor(
        of: find.text('Ingatkan via WA'),
        matching: find.byType(OutlinedButton),
      ),
    );
    expect(btn.onPressed, isNull);
  });

  testWidgets('tombol Ingatkan via WA aktif dengan no_hp valid', (
    tester,
  ) async {
    await pump(tester, makeRepo(noHp: '081234567890'));
    await tester.dragUntilVisible(
      find.text('Ingatkan via WA'),
      find.byType(CustomScrollView),
      const Offset(0, -300),
    );
    final btn = tester.widget<OutlinedButton>(
      find.ancestor(
        of: find.text('Ingatkan via WA'),
        matching: find.byType(OutlinedButton),
      ),
    );
    expect(btn.onPressed, isNotNull);
  });

  testWidgets(
    'default menampilkan lima barang dan pembayaran terbaru bernomor',
    (tester) async {
      await pump(tester, makeLongRepo());

      await tester.dragUntilVisible(
        find.byKey(const ValueKey('purchase-p7')),
        find.byType(CustomScrollView),
        const Offset(0, -300),
      );
      expect(find.byKey(const ValueKey('purchase-p7')), findsOneWidget);
      expect(find.byKey(const ValueKey('purchase-p3')), findsOneWidget);
      expect(find.byKey(const ValueKey('purchase-p2')), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('purchase-p7')),
          matching: find.text('7'),
        ),
        findsOneWidget,
      );

      await tester.dragUntilVisible(
        find.byKey(const ValueKey('payment-m7')),
        find.byType(CustomScrollView),
        const Offset(0, -300),
      );
      expect(find.byKey(const ValueKey('payment-m7')), findsOneWidget);
      expect(find.byKey(const ValueKey('payment-m3')), findsOneWidget);
      expect(find.byKey(const ValueKey('payment-m2')), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('payment-m7')),
          matching: find.text('7'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('muat selanjutnya menambah barang tanpa menambah pembayaran', (
    tester,
  ) async {
    await pump(tester, makeLongRepo());

    final loadMore = find.text('Muat 5 barang lagi (2 tersisa)');
    await tester.dragUntilVisible(
      loadMore,
      find.byType(CustomScrollView),
      const Offset(0, -300),
    );
    await tester.ensureVisible(loadMore);
    await tester.pumpAndSettle();
    await tester.tap(loadMore);
    await tester.pump();

    expect(find.byKey(const ValueKey('purchase-p1')), findsOneWidget);
    expect(find.byKey(const ValueKey('payment-m2')), findsNothing);
    expect(loadMore, findsNothing);
  });

  testWidgets('urutan barang dan pembayaran dapat diubah secara independen', (
    tester,
  ) async {
    await pump(tester, makeLongRepo());

    final purchaseSort = find.byTooltip('Urutkan barang');
    await tester.dragUntilVisible(
      purchaseSort,
      find.byType(CustomScrollView),
      const Offset(0, -300),
    );
    await tester.tap(purchaseSort);
    await tester.pumpAndSettle();
    await tester.tap(
      find
          .ancestor(
            of: find.text('Terlama').last,
            matching: find.byWidgetPredicate(
              (widget) => widget is PopupMenuItem,
            ),
          )
          .last,
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('purchase-p1')), findsOneWidget);
    expect(find.byKey(const ValueKey('purchase-p7')), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('purchase-p1')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
    await tester.dragUntilVisible(
      find.byKey(const ValueKey('payment-m7')),
      find.byType(CustomScrollView),
      const Offset(0, -300),
    );
    expect(find.byKey(const ValueKey('payment-m7')), findsOneWidget);
    expect(find.byKey(const ValueKey('payment-m1')), findsNothing);

    final paymentSort = find.byTooltip('Urutkan pembayaran');
    await tester.dragUntilVisible(
      paymentSort,
      find.byType(CustomScrollView),
      const Offset(0, -300),
    );
    await tester.tap(paymentSort);
    await tester.pumpAndSettle();
    await tester.tap(
      find
          .ancestor(
            of: find.text('Terlama').last,
            matching: find.byWidgetPredicate(
              (widget) => widget is PopupMenuItem,
            ),
          )
          .last,
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('payment-m1')), findsOneWidget);
    expect(find.byKey(const ValueKey('payment-m7')), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('payment-m1')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('pagination dan reset sort kedua bagian tetap independen', (
    tester,
  ) async {
    await pump(tester, makeLongRepo());

    final loadPurchases = find.text('Muat 5 barang lagi (2 tersisa)');
    await tester.dragUntilVisible(
      loadPurchases,
      find.byType(CustomScrollView),
      const Offset(0, -300),
    );
    await tester.ensureVisible(loadPurchases);
    await tester.pumpAndSettle();
    await tester.tap(loadPurchases);
    await tester.pump();
    expect(find.byKey(const ValueKey('purchase-p1')), findsOneWidget);

    final loadPayments = find.text('Muat 5 pembayaran lagi (2 tersisa)');
    await tester.dragUntilVisible(
      loadPayments,
      find.byType(CustomScrollView),
      const Offset(0, -300),
    );
    await tester.ensureVisible(loadPayments);
    await tester.pumpAndSettle();
    await tester.tap(loadPayments);
    await tester.pump();
    expect(find.byKey(const ValueKey('payment-m1')), findsOneWidget);

    final purchaseSort = find.byTooltip('Urutkan barang');
    await tester.dragUntilVisible(
      purchaseSort,
      find.byType(CustomScrollView),
      const Offset(0, 300),
    );
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 120));
    await tester.pumpAndSettle();
    await tester.tap(purchaseSort);
    await tester.pumpAndSettle();
    await tester.tap(
      find
          .ancestor(
            of: find.text('Terlama').last,
            matching: find.byWidgetPredicate(
              (widget) => widget is PopupMenuItem,
            ),
          )
          .last,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('purchase-p1')), findsOneWidget);
    expect(find.byKey(const ValueKey('purchase-p5')), findsOneWidget);
    expect(find.byKey(const ValueKey('purchase-p6')), findsNothing);

    await tester.dragUntilVisible(
      find.byKey(const ValueKey('payment-m1')),
      find.byType(CustomScrollView),
      const Offset(0, -300),
    );
    expect(find.byKey(const ValueKey('payment-m1')), findsOneWidget);
    expect(find.byKey(const ValueKey('payment-m7')), findsOneWidget);

    final paymentSort = find.byTooltip('Urutkan pembayaran');
    await tester.ensureVisible(paymentSort);
    await tester.tap(paymentSort);
    await tester.pumpAndSettle();
    await tester.tap(
      find
          .ancestor(
            of: find.text('Terlama').last,
            matching: find.byWidgetPredicate(
              (widget) => widget is PopupMenuItem,
            ),
          )
          .last,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('payment-m1')), findsOneWidget);
    expect(find.byKey(const ValueKey('payment-m5')), findsOneWidget);
    expect(find.byKey(const ValueKey('payment-m6')), findsNothing);
  });

  testWidgets('long press barang terbaru menargetkan barang yang ditampilkan', (
    tester,
  ) async {
    await pump(tester, makeLongRepo());

    final newest = find.byKey(const ValueKey('purchase-p7'));
    await tester.dragUntilVisible(
      newest,
      find.byType(CustomScrollView),
      const Offset(0, -300),
    );
    await tester.ensureVisible(newest);
    await tester.pumpAndSettle();
    await tester.longPress(newest);
    await tester.pumpAndSettle();

    expect(find.text('Hapus barang?'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Barang 7'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('identitas nasabah tetap terlihat setelah halaman digulir', (
    tester,
  ) async {
    await pump(tester, makeLongRepo());

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1200));
    await tester.pumpAndSettle();

    expect(find.text('WIWIK').hitTestable(), findsOneWidget);
    expect(find.text('W').hitTestable(), findsOneWidget);
    expect(find.text('Nasabah Setia').hitTestable(), findsOneWidget);
  });
}
