import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sandiapp/app.dart';
import 'package:sandiapp/core/pin_lock.dart';
import 'package:sandiapp/features/auth/login_page.dart';
import 'package:sandiapp/features/auth/pin_lock_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-publishable-key',
    );
  });

  testWidgets('seluruh konten aplikasi berada dalam SelectionArea', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(child: SandiApp()));
    await tester.pump();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(
      find.ancestor(
        of: find.byType(LoginPage),
        matching: find.byType(SelectionArea),
      ),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextFormField).first, 'admin@example.com');
    expect(find.text('admin@example.com'), findsOneWidget);
  });

  testWidgets('layar PIN tetap interaktif di dalam SelectionArea', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'pin_hash': hashPin('1234')});
    await tester.pumpWidget(const ProviderScope(child: SandiApp()));
    await tester.pumpAndSettle();

    expect(find.byType(PinLockPage), findsOneWidget);
    expect(
      find.ancestor(
        of: find.byType(PinLockPage),
        matching: find.byType(SelectionArea),
      ),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(TextButton, '1'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
