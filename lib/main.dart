import 'package:flutter/material.dart';
import 'core/theme.dart';

void main() => runApp(const SandiApp());

class SandiApp extends StatelessWidget {
  const SandiApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'SandiApp',
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        home: const Scaffold(body: Center(child: Text('SandiApp'))),
      );
}
