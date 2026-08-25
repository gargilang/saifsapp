import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../app_providers.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/money.dart';
import '../../data/models/purchase.dart';
import '../../widgets/money_input_field.dart';
import '../../widgets/fund_source_selector.dart';

class PurchaseFormPage extends ConsumerStatefulWidget {
  final String customerId;
  final Purchase? existing;
  const PurchaseFormPage({super.key, required this.customerId, this.existing});
  @override
  ConsumerState<PurchaseFormPage> createState() => _PurchaseFormPageState();
}

class _PurchaseFormPageState extends ConsumerState<PurchaseFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final _nama = TextEditingController(text: widget.existing?.namaBarang);
  late final _hargaJual = TextEditingController(
    text: widget.existing == null ? '' : _fmt(widget.existing!.hargaJual),
  );
  late final _hargaBeli = TextEditingController(
    text: widget.existing?.hargaBeli == null
        ? ''
        : _fmt(widget.existing!.hargaBeli!),
  );
  late DateTime _tanggal = widget.existing?.tanggalBeli ?? today();
  late String? _fundSourceId = widget.existing?.fundSourceId;
  String? _sourceError;
  bool _saving = false;

  static String _fmt(int v) => formatRupiah(v).replaceFirst('Rp ', '');

  @override
  void dispose() {
    _nama.dispose();
    _hargaJual.dispose();
    _hargaBeli.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final sourcesState = ref.read(fundSourcesProvider);
    if (sourcesState.isLoading || sourcesState.hasError) return;
    final sources = sourcesState.value ?? const [];
    final historicalOpening =
        widget.existing != null && widget.existing!.fundSourceId == null;
    if (sources.isNotEmpty && !historicalOpening && _fundSourceId == null) {
      setState(() => _sourceError = 'Pilih sumber dana');
      return;
    }
    setState(() => _saving = true);
    final now = DateTime.now().toUtc();
    final e = widget.existing;
    final beliDigits = parseRupiah(_hargaBeli.text);
    final purchase = Purchase(
      id: e?.id ?? const Uuid().v4(),
      customerId: widget.customerId,
      namaBarang: _nama.text.trim(),
      hargaJual: parseRupiah(_hargaJual.text),
      hargaBeli: beliDigits == 0 ? null : beliDigits,
      tanggalBeli: _tanggal,
      catatan: e?.catatan,
      fundSourceId: _fundSourceId,
      createdBy: e?.createdBy,
      createdAt: e?.createdAt ?? now,
      updatedAt: now,
    );
    try {
      await mutate(ref, () => ref.read(repoProvider).savePurchase(purchase));
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
    final sourcesState = ref.watch(fundSourcesProvider);
    final sourceUnavailable = sourcesState.isLoading || sourcesState.hasError;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Tambah Barang' : 'Edit Barang'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nama,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Nama barang *'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            MoneyInputField(
              controller: _hargaJual,
              label: 'Harga jual *',
              validator: (v) => parseRupiah(v ?? '') <= 0
                  ? 'Harga jual harus lebih dari 0'
                  : null,
            ),
            const SizedBox(height: 12),
            MoneyInputField(
              controller: _hargaBeli,
              label: 'Harga beli (opsional, untuk laporan)',
            ),
            const SizedBox(height: 12),
            if (widget.existing != null &&
                widget.existing!.fundSourceId == null)
              const InputDecorator(
                decoration: InputDecoration(labelText: 'Sumber dana'),
                child: Text('Saldo awal'),
              )
            else
              sourcesState.when(
                data: (sources) => sources.isEmpty
                    ? const SizedBox.shrink()
                    : FundSourceSelector(
                        label: 'Sumber dana',
                        sources: sources,
                        value: _fundSourceId,
                        errorText: _sourceError,
                        onChanged: (value) => setState(() {
                          _fundSourceId = value;
                          _sourceError = null;
                        }),
                      ),
                loading: () => const LinearProgressIndicator(
                  semanticsLabel: 'Memuat sumber dana',
                ),
                error: (_, _) => Text(
                  'Sumber dana gagal dimuat',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 12),
            FilledButton.tonal(
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.date_range, size: 18),
                  const SizedBox(width: 8),
                  Text('Tanggal beli: ${tampilTanggal(_tanggal)}'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving || sourceUnavailable ? null : _save,
              child: Text(_saving ? 'Menyimpan...' : 'Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}
