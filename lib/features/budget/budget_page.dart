import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../app_providers.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/money.dart';
import '../../data/models/budget_entry.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/money_input_field.dart';

class BudgetPage extends ConsumerStatefulWidget {
  const BudgetPage({super.key});
  @override
  ConsumerState<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends ConsumerState<BudgetPage> {
  late DateTime _bulan = DateTime(DateTime.now().year, DateTime.now().month);

  void _geser(int delta) =>
      setState(() => _bulan = DateTime(_bulan.year, _bulan.month + delta));

  Future<void> _tambah() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: const _BudgetEntryForm(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(budgetMonthProvider((_bulan.year, _bulan.month)));
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'budget-fab',
        onPressed: _tambah,
        child: const Icon(Icons.add),
      ),
      body: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(
              icon: const Icon(Icons.chevron_left), onPressed: () => _geser(-1)),
          Text(bulanTahun(_bulan.year, _bulan.month),
              style: Theme.of(context).textTheme.titleMedium),
          IconButton(
              icon: const Icon(Icons.chevron_right), onPressed: () => _geser(1)),
        ]),
        Expanded(
          child: data.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => EmptyState(message: 'Gagal memuat: $e'),
            data: (lines) => lines.isEmpty
                ? const EmptyState(message: 'Belum ada transaksi bulan ini.')
                : ListView(children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text('Saldo: ${formatRupiah(lines.last.saldo)}',
                          style: Theme.of(context).textTheme.headlineSmall),
                    ),
                    for (final l in lines)
                      ListTile(
                        dense: true,
                        title: Text(l.entry.namaTransaksi),
                        subtitle: Text(tampilTanggal(l.entry.tanggal)),
                        leading: Icon(
                          l.entry.tipe == 'pemasukan'
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          color: l.entry.tipe == 'pemasukan'
                              ? Colors.green
                              : Colors.red,
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                                '${l.entry.tipe == 'pemasukan' ? '+' : '-'}${formatRupiah(l.entry.jumlah)}'),
                            Text('Saldo: ${formatRupiah(l.saldo)}',
                                style: Theme.of(context).textTheme.labelSmall),
                          ],
                        ),
                        onLongPress: () async {
                          if (await confirmDialog(context,
                              title: 'Hapus transaksi?',
                              message: l.entry.namaTransaksi)) {
                            await mutate(
                                ref,
                                () => ref
                                    .read(repoProvider)
                                    .deleteBudgetEntry(l.entry.id));
                          }
                        },
                      ),
                  ]),
          ),
        ),
      ]),
    );
  }
}

class _BudgetEntryForm extends ConsumerStatefulWidget {
  const _BudgetEntryForm();
  @override
  ConsumerState<_BudgetEntryForm> createState() => _BudgetEntryFormState();
}

class _BudgetEntryFormState extends ConsumerState<_BudgetEntryForm> {
  final _formKey = GlobalKey<FormState>();
  final _nama = TextEditingController();
  final _jumlah = TextEditingController();
  String _tipe = 'pengeluaran';
  DateTime _tanggal = today();

  @override
  void dispose() {
    _nama.dispose();
    _jumlah.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final now = DateTime.now().toUtc();
    await mutate(
        ref,
        () => ref.read(repoProvider).saveBudgetEntry(BudgetEntry(
              id: const Uuid().v4(),
              tanggal: _tanggal,
              namaTransaksi: _nama.text.trim(),
              tipe: _tipe,
              jumlah: parseRupiah(_jumlah.text),
              createdAt: now,
              updatedAt: now,
            )));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(shrinkWrap: true, padding: const EdgeInsets.all(16), children: [
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'pengeluaran', label: Text('Pengeluaran')),
            ButtonSegment(value: 'pemasukan', label: Text('Pemasukan')),
          ],
          selected: {_tipe},
          onSelectionChanged: (s) => setState(() => _tipe = s.first),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _nama,
          decoration: const InputDecoration(labelText: 'Nama transaksi *'),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
        ),
        const SizedBox(height: 12),
        MoneyInputField(
          controller: _jumlah,
          label: 'Jumlah *',
          validator: (v) =>
              parseRupiah(v ?? '') <= 0 ? 'Jumlah harus lebih dari 0' : null,
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          icon: const Icon(Icons.date_range),
          label: Text('Tanggal: ${tampilTanggal(_tanggal)}'),
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _tanggal,
              firstDate: DateTime(2015),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              locale: const Locale('id', 'ID'),
            );
            if (picked != null) setState(() => _tanggal = picked);
          },
        ),
        const SizedBox(height: 16),
        FilledButton(onPressed: _save, child: const Text('Simpan')),
      ]),
    );
  }
}
