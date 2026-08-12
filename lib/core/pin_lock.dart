import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

String hashPin(String pin) => sha256.convert(utf8.encode('sni:$pin')).toString();

class PinLockState {
  final bool enabled, locked;
  const PinLockState({required this.enabled, required this.locked});
}

class PinLockNotifier extends Notifier<PinLockState> {
  static const _key = 'pin_hash';

  @override
  PinLockState build() {
    SharedPreferences.getInstance().then((p) {
      final h = p.getString(_key);
      state = PinLockState(enabled: h != null, locked: h != null);
    });
    return const PinLockState(enabled: false, locked: false);
  }

  Future<void> enable(String pin) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, hashPin(pin));
    state = const PinLockState(enabled: true, locked: false);
  }

  Future<bool> unlock(String pin) async {
    final p = await SharedPreferences.getInstance();
    final ok = p.getString(_key) == hashPin(pin);
    if (ok) state = const PinLockState(enabled: true, locked: false);
    return ok;
  }

  Future<void> disable() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key);
    state = const PinLockState(enabled: false, locked: false);
  }
}

final pinLockProvider = NotifierProvider<PinLockNotifier, PinLockState>(PinLockNotifier.new);
