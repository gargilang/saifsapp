import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_providers.dart';
import '../../core/logic/funds.dart';
import '../../core/utils/money.dart';
import 'fund_history_sheet.dart';
import 'fund_transfer_sheet.dart';

class FundSummarySection extends ConsumerWidget {
  const FundSummarySection({super.key});

  Future<void> _openTransfer(
    BuildContext context,
    FundSummary summary, {
    required bool adjustment,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => FundTransferSheet(summary: summary, adjustment: adjustment),
  );

  Future<void> _openHistory(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const FundHistorySheet(),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(fundSummaryProvider);
    return state.when(
      loading: () =>
          const LinearProgressIndicator(semanticsLabel: 'Memuat sumber dana'),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Sumber dana gagal dimuat: $error',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
      data: (summary) {
        if (summary.balances.isEmpty) return const SizedBox.shrink();
        final colors = Theme.of(context).colorScheme;
        return Container(
          width: double.infinity,
          color: colors.surfaceContainer,
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sumber dana',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Piutang aktif ${formatRupiah(summary.totalPiutang)}',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Alih modal',
                    onPressed: () =>
                        _openTransfer(context, summary, adjustment: false),
                    icon: const Icon(Icons.swap_horiz),
                  ),
                  IconButton(
                    tooltip: 'Penyesuaian sumber dana',
                    onPressed: () =>
                        _openTransfer(context, summary, adjustment: true),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Riwayat sumber dana',
                    onPressed: () => _openHistory(context),
                    icon: const Icon(Icons.history),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, constraints) {
                  final children = [
                    for (final balance in summary.balances)
                      _FundBalanceView(balance: balance),
                  ];
                  if (constraints.maxWidth < 360) {
                    return Column(
                      children: [
                        for (
                          var index = 0;
                          index < children.length;
                          index++
                        ) ...[
                          if (index > 0) const SizedBox(height: 8),
                          children[index],
                        ],
                      ],
                    );
                  }
                  return Row(
                    children: [
                      for (var index = 0; index < children.length; index++) ...[
                        if (index > 0) const SizedBox(width: 12),
                        Expanded(child: children[index]),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    summary.isConsistent
                        ? Icons.check_circle_outline
                        : Icons.warning_amber,
                    size: 17,
                    color: summary.isConsistent
                        ? colors.tertiary
                        : colors.error,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      summary.isConsistent
                          ? 'Saldo sesuai piutang'
                          : 'Total sumber dana tidak sama dengan piutang',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: summary.isConsistent
                            ? colors.tertiary
                            : colors.error,
                      ),
                    ),
                  ),
                  Text(
                    formatRupiah(summary.total),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FundBalanceView extends StatelessWidget {
  final FundBalance balance;

  const _FundBalanceView({required this.balance});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = balance.source.colorKey == 'green'
        ? colors.tertiary
        : colors.primary;
    return Semantics(
      label:
          'Sumber dana ${balance.source.nama}, saldo ${formatRupiah(balance.saldo)}',
      child: Row(
        children: [
          Container(
            width: 4,
            height: 38,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  balance.source.nama,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                Text(
                  formatRupiah(balance.saldo),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
