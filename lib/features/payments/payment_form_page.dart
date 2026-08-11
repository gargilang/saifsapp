import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../app_providers.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/money.dart';
import '../../data/models/payment.dart';
import '../../widgets/money_input_field.dart';

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
          : formatRupiah(widget.existing!.jumlah).replaceFirst('Rp ', ''));
  late final _catatan = TextEditingController(text: widget.existing?.catatan);
  late DateTime _tanggal = widget.existing?.tanggalBayar ?? today();
  late String _metode = widget.existing?.metode ?? 'tunai';
  bool _saving = false;

  @override
  void dispose() {
    _jumlah.dispose();
    _catatan.dispose();
    super.dispose();
  }

  void _setJumlah(int v) {
    _jumlah.text = formatRupiah(v).replaceFirst('Rp ', '');
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
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
      createdBy: e?.createdBy,
      createdAt: e?.createdAt ?? now,
      updatedAt: now,
    );
    await mutate(ref, () => ref.read(repoProvider).savePayment(payment));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(
              widget.existing == null ? 'Tambah Pembayaran' : 'Edit Pembayaran')),
      body: Form(
        key: _formKey,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          MoneyInputField(
            controller: _jumlah,
            label: 'Jumlah bayar *',
            validator: (v) =>
                parseRupiah(v ?? '') <= 0 ? 'Jumlah harus lebih dari 0' : null,
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            for (final (label, nilai) in [
              ('50rb', 50000),
              ('100rb', 100000),
              ('200rb', 200000),
              ('500rb', 500000),
            ])
              ActionChip(
                label: Text(label),
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                onPressed: () => _setJumlah(nilai),
              ),
          ]),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _metode,
            decoration: const InputDecoration(labelText: 'Metode'),
            items: const [
              DropdownMenuItem(value: 'tunai', child: Text('Tunai')),
              DropdownMenuItem(value: 'transfer', child: Text('Transfer')),
              DropdownMenuItem(value: 'lainnya', child: Text('Lainnya')),
            ],
            onChanged: (v) => setState(() => _metode = v ?? 'tunai'),
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
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.date_range, size: 18),
              const SizedBox(width: 8),
              Text('Tanggal bayar: ${tampilTanggal(_tanggal)}'),
            ]),
          ),
          const SizedBox(height: 12),
          TextFormField(
              controller: _catatan,
              decoration: const InputDecoration(labelText: 'Catatan (opsional)')),
          const SizedBox(height: 24),
          FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Menyimpan...' : 'Simpan')),
        ]),
      ),
    );
  }
}
