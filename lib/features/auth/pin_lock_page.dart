import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/pin_lock.dart';
import '../../widgets/brand_logo.dart';

class PinLockPage extends ConsumerStatefulWidget {
  const PinLockPage({super.key});
  @override
  ConsumerState<PinLockPage> createState() => _PinLockPageState();
}

class _PinLockPageState extends ConsumerState<PinLockPage> {
  String _input = '';

  void _tap(String d) {
    if (_input.length >= 4) return;
    setState(() => _input += d);
    if (_input.length == 4) _verify();
  }

  void _backspace() {
    if (_input.isEmpty) return;
    setState(() => _input = _input.substring(0, _input.length - 1));
  }

  Future<void> _verify() async {
    final ok = await ref.read(pinLockProvider.notifier).unlock(_input);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('PIN salah. Coba lagi.')));
      setState(() => _input = '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const BrandLogo(size: 64),
            const SizedBox(height: 16),
            Text('Masukkan PIN', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < 4; i++)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < _input.length
                          ? cs.primary
                          : cs.surfaceContainerHighest,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 240,
              child: GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (final d in ['1', '2', '3', '4', '5', '6', '7', '8', '9'])
                    TextButton(
                      onPressed: () => _tap(d),
                      child: Text(d, style: const TextStyle(fontSize: 22)),
                    ),
                  const SizedBox.shrink(),
                  TextButton(
                    onPressed: () => _tap('0'),
                    child: const Text('0', style: TextStyle(fontSize: 22)),
                  ),
                  IconButton(
                    onPressed: _backspace,
                    icon: const Icon(Icons.backspace_outlined),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
