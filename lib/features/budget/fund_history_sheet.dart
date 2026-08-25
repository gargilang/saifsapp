import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_providers.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/money.dart';
import '../../data/models/fund_ledger_entry.dart';

class FundHistorySheet extends ConsumerWidget {
  const FundHistorySheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sources = ref.watch(fundSourcesProvider);
    final history = ref.watch(fundHistoryProvider);
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.72,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Riwayat sumber dana',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Tutup',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: switch ((sources, history)) {
              (
                AsyncData(value: final sourceRows),
                AsyncData(value: final historyRows),
              ) =>
                _HistoryList(
                  rows: historyRows,
                  names: {
                    for (final source in sourceRows) source.id: source.nama,
                  },
                ),
              (AsyncError(error: final error), _) ||
              (
                _,
                AsyncError(error: final error),
              ) => Center(child: Text('Riwayat gagal dimuat: $error')),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  final List<FundLedgerEntry> rows;
  final Map<String, String> names;

  const _HistoryList({required this.rows, required this.names});

  @override
  Widget build(BuildContext context) {
    final items = _groupHistory(rows, names);
    if (items.isEmpty) return const Center(child: Text('Belum ada riwayat.'));
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          leading: Icon(
            item.transfer ? Icons.swap_horiz : Icons.account_balance,
          ),
          title: Text(item.title),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Text(item.kind), Text(tampilTanggal(item.date))],
          ),
          trailing: Text(
            item.transfer
                ? formatRupiah(item.amount)
                : '${item.amount >= 0 ? '+' : '-'}${formatRupiah(item.amount.abs())}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        );
      },
    );
  }
}

class _HistoryItem {
  final String title;
  final String kind;
  final DateTime date;
  final int amount;
  final bool transfer;

  const _HistoryItem({
    required this.title,
    required this.kind,
    required this.date,
    required this.amount,
    required this.transfer,
  });
}

List<_HistoryItem> _groupHistory(
  List<FundLedgerEntry> rows,
  Map<String, String> names,
) {
  final byGroup = <String, List<FundLedgerEntry>>{};
  for (final row in rows) {
    final group = row.transferGroupId;
    if (group != null) byGroup.putIfAbsent(group, () => []).add(row);
  }
  final consumed = <String>{};
  final result = <_HistoryItem>[];
  for (final row in rows) {
    final group = row.transferGroupId;
    if (group != null && !consumed.add(group)) continue;
    final pair = group == null ? const <FundLedgerEntry>[] : byGroup[group]!;
    final outgoing = pair.where((entry) => entry.jumlahDelta < 0).firstOrNull;
    final incoming = pair.where((entry) => entry.jumlahDelta > 0).firstOrNull;
    if (outgoing != null && incoming != null) {
      result.add(
        _HistoryItem(
          title:
              '${names[outgoing.fundSourceId] ?? 'Sumber'} -> ${names[incoming.fundSourceId] ?? 'Sumber'}',
          kind: row.referenceType == 'adjustment'
              ? 'Penyesuaian'
              : 'Alih modal',
          date: row.tanggal,
          amount: incoming.jumlahDelta,
          transfer: true,
        ),
      );
      continue;
    }
    result.add(
      _HistoryItem(
        title: names[row.fundSourceId] ?? 'Sumber dana',
        kind: row.tipe == 'saldo_awal' ? 'Saldo awal' : 'Penyesuaian',
        date: row.tanggal,
        amount: row.jumlahDelta,
        transfer: false,
      ),
    );
  }
  return result;
}
