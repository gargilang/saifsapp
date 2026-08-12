import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sandiapp/widgets/brand_logo.dart';

void main() {
  testWidgets('BrandLogo merender CustomPaint tanpa error', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(child: BrandLogo(size: 64))),
    ));
    expect(find.byType(BrandLogo), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
