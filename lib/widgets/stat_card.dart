import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  const StatCard(
      {super.key, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: valueColor)),
          ]),
        ),
      );
}
