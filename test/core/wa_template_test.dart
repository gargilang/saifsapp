import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sandiapp/core/utils/whatsapp.dart';
import 'package:sandiapp/core/wa_template.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('default template, bisa diubah & dipersist', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(waTemplateProvider), kDefaultWaTemplate);

    await container.read(waTemplateProvider.notifier).setTemplate('Halo {nama}!');
    expect(container.read(waTemplateProvider), 'Halo {nama}!');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('wa_template'), 'Halo {nama}!');
  });

  test('reset mengembalikan ke default', () async {
    SharedPreferences.setMockInitialValues({'wa_template': 'Custom'});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    // Trigger build() (provider lazy) agar load async SharedPreferences jalan,
    // lalu beri event-loop kesempatan menyelesaikannya.
    container.read(waTemplateProvider);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(waTemplateProvider), 'Custom');
    await container.read(waTemplateProvider.notifier).reset();
    expect(container.read(waTemplateProvider), kDefaultWaTemplate);
  });
}
