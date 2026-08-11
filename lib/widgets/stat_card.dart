import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final String label, value;
  final Color? valueColor;

  /// Jika true, nilai ditampilkan dengan warna primary (emas).
  final bool accent;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final effectiveColor = valueColor ?? (accent ? cs.primary : cs.onSurface);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 6),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: effectiveColor, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}
