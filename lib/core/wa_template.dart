import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'utils/whatsapp.dart';

class WaTemplateNotifier extends Notifier<String> {
  static const _key = 'wa_template';

  @override
  String build() {
    SharedPreferences.getInstance().then((p) {
      final v = p.getString(_key);
      if (v != null && v.trim().isNotEmpty) state = v;
    });
    return kDefaultWaTemplate;
  }

  Future<void> setTemplate(String v) async {
    state = v;
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, v);
  }

  Future<void> reset() => setTemplate(kDefaultWaTemplate);
}

final waTemplateProvider = NotifierProvider<WaTemplateNotifier, String>(WaTemplateNotifier.new);
