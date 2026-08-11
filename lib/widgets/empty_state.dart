import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  const EmptyState(
      {super.key, required this.message, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.inbox_outlined, size: 48, color: cs.primary),
          const SizedBox(height: 12),
          Text(message,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center),
          if (actionLabel != null) ...[
            const SizedBox(height: 16),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ]),
      ),
    );
  }
}
