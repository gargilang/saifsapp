import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sandiapp/core/pin_lock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('hashPin deterministik & beda pin -> beda hash', () {
    expect(hashPin('1234'), hashPin('1234'));
    expect(hashPin('1234'), isNot(hashPin('4321')));
  });

  test('enable -> enabled true, locked false; sesi baru -> locked true', () async {
    SharedPreferences.setMockInitialValues({});
    final c1 = ProviderContainer();
    addTearDown(c1.dispose);
    expect(c1.read(pinLockProvider).enabled, isFalse);

    await c1.read(pinLockProvider.notifier).enable('1234');
    expect(c1.read(pinLockProvider).enabled, isTrue);
    expect(c1.read(pinLockProvider).locked, isFalse);

    final c2 = ProviderContainer(); // simulasi restart app
    addTearDown(c2.dispose);
    c2.read(pinLockProvider); // trigger build() agar async load dimulai
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(c2.read(pinLockProvider).enabled, isTrue);
    expect(c2.read(pinLockProvider).locked, isTrue);
  });

  test('unlock: benar -> true & locked false; salah -> false, tetap locked', () async {
    SharedPreferences.setMockInitialValues({});
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await c.read(pinLockProvider.notifier).enable('1234');

    expect(await c.read(pinLockProvider.notifier).unlock('0000'), isFalse);
    expect(await c.read(pinLockProvider.notifier).unlock('1234'), isTrue);
    expect(c.read(pinLockProvider).locked, isFalse);
  });

  test('disable -> kembali ke nonaktif', () async {
    SharedPreferences.setMockInitialValues({});
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await c.read(pinLockProvider.notifier).enable('1234');
    await c.read(pinLockProvider.notifier).disable();
    expect(c.read(pinLockProvider).enabled, isFalse);
  });
}
