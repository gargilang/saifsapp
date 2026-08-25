import 'package:flutter/material.dart';

import '../data/models/fund_source.dart';

class FundSourceSelector extends StatelessWidget {
  final String label;
  final List<FundSource> sources;
  final String? value;
  final String? errorText;
  final bool enabled;
  final ValueChanged<String> onChanged;

  const FundSourceSelector({
    super.key,
    required this.label,
    required this.sources,
    required this.value,
    required this.onChanged,
    this.errorText,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: label,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          contentPadding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        ),
        child: SegmentedButton<String>(
          emptySelectionAllowed: true,
          expandedInsets: EdgeInsets.zero,
          segments: [
            for (final source in sources)
              ButtonSegment<String>(
                value: source.id,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: source.colorKey == 'green'
                            ? colors.tertiary
                            : colors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(child: Text(source.nama)),
                  ],
                ),
              ),
          ],
          selected: value == null ? const {} : {value!},
          onSelectionChanged: enabled
              ? (selected) {
                  if (selected.isNotEmpty) onChanged(selected.first);
                }
              : null,
        ),
      ),
    );
  }
}
