import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../app_providers.dart';
import '../../core/logic/funds.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/money.dart';
import '../../data/models/fund_ledger_entry.dart';
import '../../widgets/money_input_field.dart';

class FundTransferSheet extends ConsumerStatefulWidget {
  final FundSummary summary;
  final bool adjustment;

  const FundTransferSheet({
    super.key,
    required this.summary,
    required this.adjustment,
  });

  @override
  ConsumerState<FundTransferSheet> createState() => _FundTransferSheetState();
}

class _FundTransferSheetState extends ConsumerState<FundTransferSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  late String _fromId = widget.summary.balances.first.source.id;
  late String _toId = widget.summary.balances
      .firstWhere((row) => row.source.id != _fromId)
      .source
      .id;
  DateTime _date = today();
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _changeFrom(String sourceId) {
    setState(() {
      _fromId = sourceId;
      _toId = widget.summary.balances
          .firstWhere((row) => row.source.id != sourceId)
          .source
          .id;
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final amount = parseRupiah(_amount.text);
    final now = DateTime.now().toUtc();
    final groupId = const Uuid().v4();
    final note = _note.text.trim().isEmpty ? null : _note.text.trim();
    final referenceType = widget.adjustment ? 'adjustment' : 'transfer';
    final transfer = FundTransfer(
      keluar: FundLedgerEntry(
        id: const Uuid().v4(),
        fundSourceId: _fromId,
        tanggal: _date,
        tipe: widget.adjustment ? 'penyesuaian' : 'alih_keluar',
        jumlahDelta: -amount,
        referenceType: referenceType,
        referenceId: groupId,
        transferGroupId: groupId,
        catatan: note,
        createdAt: now,
        updatedAt: now,
      ),
      masuk: FundLedgerEntry(
        id: const Uuid().v4(),
        fundSourceId: _toId,
        tanggal: _date,
        tipe: widget.adjustment ? 'penyesuaian' : 'alih_masuk',
        jumlahDelta: amount,
        referenceType: referenceType,
        referenceId: groupId,
        transferGroupId: groupId,
        catatan: note,
        createdAt: now,
        updatedAt: now,
      ),
    );
    try {
      await mutate(
        ref,
        () => widget.adjustment
            ? ref.read(repoProvider).adjustFund(transfer)
            : ref.read(repoProvider).transferFund(transfer),
      );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final fromBalance = widget.summary.bySourceId(_fromId);
    final toSource = widget.summary.bySourceId(_toId).source;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              widget.adjustment ? 'Penyesuaian sumber dana' : 'Alih modal',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              key: const Key('fund-transfer-from'),
              initialValue: _fromId,
              decoration: const InputDecoration(labelText: 'Dari'),
              items: [
                for (final row in widget.summary.balances)
                  DropdownMenuItem(
                    value: row.source.id,
                    child: Text(
                      '${row.source.nama} - ${formatRupiah(row.saldo)}',
                    ),
                  ),
              ],
              onChanged: (value) {
                if (value != null) _changeFrom(value);
              },
            ),
            const SizedBox(height: 12),
            InputDecorator(
              decoration: const InputDecoration(labelText: 'Ke'),
              child: Text(toSource.nama),
            ),
            const SizedBox(height: 12),
            MoneyInputField(
              key: const Key('fund-transfer-amount'),
              controller: _amount,
              label: 'Nominal *',
              validator: (value) {
                final amount = parseRupiah(value ?? '');
                if (amount <= 0) return 'Nominal harus lebih dari 0';
                if (amount > fromBalance.saldo) {
                  return 'Saldo sumber dana tidak mencukupi';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _note,
              decoration: InputDecoration(
                labelText: widget.adjustment
                    ? 'Alasan penyesuaian *'
                    : 'Catatan (opsional)',
              ),
              validator: widget.adjustment
                  ? (value) => value == null || value.trim().isEmpty
                        ? 'Alasan wajib diisi'
                        : null
                  : null,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  locale: const Locale('id', 'ID'),
                );
                if (picked != null) setState(() => _date = picked);
              },
              icon: const Icon(Icons.date_range),
              label: Text('Tanggal: ${tampilTanggal(_date)}'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Menyimpan...' : 'Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}
