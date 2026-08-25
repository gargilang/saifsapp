import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../app_providers.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/money.dart';
import '../../data/models/payment.dart';
import '../../widgets/money_input_field.dart';
import '../../widgets/fund_source_selector.dart';

class PaymentFormPage extends ConsumerStatefulWidget {
  final String customerId;
  final Payment? existing;
  const PaymentFormPage({super.key, required this.customerId, this.existing});
  @override
  ConsumerState<PaymentFormPage> createState() => _PaymentFormPageState();
}

class _PaymentFormPageState extends ConsumerState<PaymentFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final _jumlah = TextEditingController(
    text: widget.existing == null
        ? ''
        : formatRupiah(widget.existing!.jumlah).replaceFirst('Rp ', ''),
  );
  late final _catatan = TextEditingController(text: widget.existing?.catatan);
  late DateTime _tanggal = widget.existing?.tanggalBayar ?? today();
  late String _metode = widget.existing?.metode ?? 'transfer';
  late String? _fundSourceId = widget.existing?.fundSourceId;
  String? _sourceError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing == null) {
      Future<void>.microtask(_loadSuggestedFundSource);
    }
  }

  Future<void> _loadSuggestedFundSource() async {
    final suggestion = await ref
        .read(repoProvider)
        .suggestedPaymentFundSource(widget.customerId);
    if (!mounted || _fundSourceId != null || suggestion == null) return;
    setState(() => _fundSourceId = suggestion);
  }

  @override
  void dispose() {
    _jumlah.dispose();
    _catatan.dispose();
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
    final payment = Payment(
      id: e?.id ?? const Uuid().v4(),
      customerId: widget.customerId,
      jumlah: parseRupiah(_jumlah.text),
      tanggalBayar: _tanggal,
      metode: _metode,
      catatan: _catatan.text.trim().isEmpty ? null : _catatan.text.trim(),
      sumber: e?.sumber ?? 'admin',
      statusVerifikasi: e?.statusVerifikasi ?? 'verified',
      buktiFotoUrl: e?.buktiFotoUrl,
      fundSourceId: _fundSourceId,
      createdBy: e?.createdBy,
      createdAt: e?.createdAt ?? now,
      updatedAt: now,
    );
    try {
      await mutate(ref, () => ref.read(repoProvider).savePayment(payment));
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
        title: Text(
          widget.existing == null ? 'Tambah Pembayaran' : 'Edit Pembayaran',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            MoneyInputField(
              controller: _jumlah,
              label: 'Jumlah bayar *',
              validator: (v) => parseRupiah(v ?? '') <= 0
                  ? 'Jumlah harus lebih dari 0'
                  : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _metode,
              decoration: const InputDecoration(labelText: 'Metode'),
              items: const [
                DropdownMenuItem(value: 'tunai', child: Text('Tunai')),
                DropdownMenuItem(value: 'transfer', child: Text('Transfer')),
                DropdownMenuItem(value: 'lainnya', child: Text('Lainnya')),
              ],
              onChanged: (v) => setState(() => _metode = v ?? 'transfer'),
            ),
            const SizedBox(height: 12),
            if (widget.existing != null &&
                widget.existing!.fundSourceId == null)
              const InputDecorator(
                decoration: InputDecoration(labelText: 'Mengurangi dana'),
                child: Text('Saldo awal'),
              )
            else
              sourcesState.when(
                data: (sources) => sources.isEmpty
                    ? const SizedBox.shrink()
                    : FundSourceSelector(
                        label: 'Mengurangi dana',
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
                  Text('Tanggal bayar: ${tampilTanggal(_tanggal)}'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _catatan,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
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
