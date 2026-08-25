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
import 'fund_summary_section.dart';

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
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: const _BudgetEntryForm(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final data = ref.watch(budgetMonthProvider((_bulan.year, _bulan.month)));
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'budget-fab',
        onPressed: _tambah,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // ── Navigator bulan ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: cs.surfaceContainer,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _geser(-1),
                ),
                Text(
                  bulanTahun(_bulan.year, _bulan.month),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _geser(1),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: cs.surfaceContainerHighest),
          const FundSummarySection(),
          Divider(height: 1, color: cs.surfaceContainerHighest),
          Expanded(
            child: data.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => EmptyState(message: 'Gagal memuat: $e'),
              data: (lines) => lines.isEmpty
                  ? const EmptyState(message: 'Belum ada transaksi bulan ini.')
                  : ListView(
                      children: [
                        // ── Saldo besar ──────────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SALDO',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formatRupiah(lines.last.saldo),
                                style: Theme.of(context).textTheme.displayMedium
                                    ?.copyWith(
                                      color: lines.last.saldo >= 0
                                          ? cs.primary
                                          : cs.error,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              for (int i = 0; i < lines.length; i++) ...[
                                if (i > 0)
                                  Divider(
                                    height: 1,
                                    indent: 16,
                                    color: cs.surfaceContainerHighest,
                                  ),
                                ListTile(
                                  dense: true,
                                  leading: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color:
                                          (lines[i].entry.tipe == 'pemasukan'
                                                  ? cs.tertiary
                                                  : cs.error)
                                              .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      lines[i].entry.tipe == 'pemasukan'
                                          ? Icons.arrow_downward
                                          : Icons.arrow_upward,
                                      size: 18,
                                      color: lines[i].entry.tipe == 'pemasukan'
                                          ? cs.tertiary
                                          : cs.error,
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          lines[i].entry.namaTransaksi,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      if (lines[i].entry.isAuto)
                                        Icon(
                                          Icons.link,
                                          size: 14,
                                          color: cs.onSurfaceVariant,
                                        ),
                                    ],
                                  ),
                                  subtitle: Text(
                                    tampilTanggal(lines[i].entry.tanggal),
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${lines[i].entry.tipe == 'pemasukan' ? '+' : '-'}${formatRupiah(lines[i].entry.jumlah)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color:
                                              lines[i].entry.tipe == 'pemasukan'
                                              ? cs.tertiary
                                              : cs.error,
                                        ),
                                      ),
                                      Text(
                                        'Saldo: ${formatRupiah(lines[i].saldo)}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.labelSmall,
                                      ),
                                    ],
                                  ),
                                  onLongPress: () async {
                                    if (lines[i].entry.isAuto) {
                                      // Entry otomatis dari transaksi nasabah
                                      final source =
                                          lines[i].entry.sourceType ==
                                              'purchase'
                                          ? 'transaksi pembelian'
                                          : 'pembayaran';
                                      await showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text(
                                            'Tidak bisa dihapus',
                                          ),
                                          content: Text(
                                            'Data ini terkait dengan $source nasabah. '
                                            'Untuk menghapus, silakan hapus dari halaman detail nasabah terkait.',
                                          ),
                                          actions: [
                                            FilledButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx),
                                              child: const Text('Mengerti'),
                                            ),
                                          ],
                                        ),
                                      );
                                    } else {
                                      // Entry manual bisa dihapus
                                      if (await confirmDialog(
                                        context,
                                        title: 'Hapus transaksi?',
                                        message: lines[i].entry.namaTransaksi,
                                      )) {
                                        await mutate(
                                          ref,
                                          () => ref
                                              .read(repoProvider)
                                              .deleteBudgetEntry(
                                                lines[i].entry.id,
                                              ),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
            ),
          ),
        ],
      ),
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
      () => ref
          .read(repoProvider)
          .saveBudgetEntry(
            BudgetEntry(
              id: const Uuid().v4(),
              tanggal: _tanggal,
              namaTransaksi: _nama.text.trim(),
              tipe: _tipe,
              jumlah: parseRupiah(_jumlah.text),
              createdAt: now,
              updatedAt: now,
            ),
          ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(16),
        children: [
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
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
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
        ],
      ),
    );
  }
}
