import 'package:flutter/material.dart';

import '../core/logic/collectibility.dart';

/// Dot warna status kolektibilitas. `status == null` (lunas/tanpa hutang) -> tidak tampil.
class CollectibilityDot extends StatelessWidget {
  final Collectibility? status;
  final double size;
  const CollectibilityDot({super.key, required this.status, this.size = 8});

  @override
  Widget build(BuildContext context) {
    final s = status;
    if (s == null) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    final color = switch (s) {
      Collectibility.lancar => cs.tertiary,
      Collectibility.perhatian => const Color(0xFFF59E0B),
      Collectibility.kurangLancar => const Color(0xFFF97316),
      Collectibility.macet => cs.error,
    };
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
