import 'package:flutter_test/flutter_test.dart';
import 'package:sandiapp/main.dart';

void main() {
  testWidgets('smoke: app renders', (tester) async {
    await tester.pumpWidget(const SandiApp());
    expect(find.text('SandiApp'), findsOneWidget);
  });
}
