// Generator aset brand (logo PNG untuk launcher icon, splash, PDF).
// BUKAN bagian dari `flutter test` biasa (folder tool/ tidak di-scan default).
// Jalankan manual setiap kali BrandLogoPainter berubah:
//   flutter test tool/brand_assets_test.dart
@TestOn('vm')
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sandiapp/widgets/brand_logo.dart';

Future<void> _render(String path, double canvasSize, double logoScale,
    {bool withBackground = false}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final size = Size.square(canvasSize);
  if (withBackground) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF111318));
  }
  BrandLogoPainter(scale: logoScale).paint(canvas, size);
  final img = await recorder.endRecording().toImage(canvasSize.round(), canvasSize.round());
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  test('generate brand PNG assets', () async {
    final fontBytes = File('assets/fonts/Inter-ExtraBold.ttf').readAsBytesSync();
    final loader = FontLoader('InterBrand')
      ..addFont(Future.value(ByteData.view(fontBytes.buffer)));
    await loader.load();

    Directory('assets/brand').createSync(recursive: true);
    await _render('assets/brand/logo_512.png', 512, 1.0);
    await _render('assets/brand/logo_adaptive.png', 1024, 0.62);
    await _render('assets/brand/logo_splash.png', 1024, 0.5, withBackground: true);
    await _render('assets/brand/logo_pdf.png', 256, 1.0);

    for (final f in ['logo_512.png', 'logo_adaptive.png', 'logo_splash.png', 'logo_pdf.png']) {
      expect(File('assets/brand/$f').lengthSync(), greaterThan(1000), reason: f);
    }
  });
}
