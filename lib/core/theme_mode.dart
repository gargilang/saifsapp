import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    SharedPreferences.getInstance().then((p) {
      final v = p.getString('theme_mode');
      if (v == 'light') state = ThemeMode.light;
      if (v == 'dark') state = ThemeMode.dark;
    });
    return ThemeMode.system;
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    final p = await SharedPreferences.getInstance();
    await p.setString('theme_mode', mode.name);
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
