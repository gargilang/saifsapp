import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../app_providers.dart';
import '../../data/models/customer.dart';

class CustomerFormPage extends ConsumerStatefulWidget {
  final Customer? existing;
  const CustomerFormPage({super.key, this.existing});
  @override
  ConsumerState<CustomerFormPage> createState() => _CustomerFormPageState();
}

class _CustomerFormPageState extends ConsumerState<CustomerFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final _nama = TextEditingController(text: widget.existing?.nama);
  late final _noHp = TextEditingController(text: widget.existing?.noHp);
  late final _alamat = TextEditingController(text: widget.existing?.alamat);
  late final _catatan = TextEditingController(text: widget.existing?.catatan);
  bool _saving = false;

  @override
  void dispose() {
    _nama.dispose();
    _noHp.dispose();
    _alamat.dispose();
    _catatan.dispose();
    super.dispose();
  }

  String? _emptyToNull(String s) => s.trim().isEmpty ? null : s.trim();

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final now = DateTime.now().toUtc();
    final e = widget.existing;
    final customer = Customer(
      id: e?.id ?? const Uuid().v4(),
      nama: _nama.text.trim(),
      noHp: _emptyToNull(_noHp.text),
      alamat: _emptyToNull(_alamat.text),
      catatan: _emptyToNull(_catatan.text),
      isArchived: e?.isArchived ?? false,
      authUserId: e?.authUserId,
      createdBy: e?.createdBy,
      createdAt: e?.createdAt ?? now,
      updatedAt: now,
    );
    await mutate(ref, () => ref.read(repoProvider).saveCustomer(customer));
    if (mounted) {
      if (e == null) {
        // customer baru: langsung ke detail agar tombol hapus/edit tersedia
        context.pushReplacement('/customers/${customer.id}');
      } else {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.existing == null ? 'Tambah Customer' : 'Edit Customer')),
      body: Form(
        key: _formKey,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          TextFormField(
            controller: _nama,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(labelText: 'Nama *'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
              controller: _noHp,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'No. HP')),
          const SizedBox(height: 12),
          TextFormField(
              controller: _alamat,
              decoration: const InputDecoration(labelText: 'Alamat')),
          const SizedBox(height: 12),
          TextFormField(
              controller: _catatan,
              decoration: const InputDecoration(labelText: 'Catatan')),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Menyimpan...' : 'Simpan'),
          ),
        ]),
      ),
    );
  }
}
