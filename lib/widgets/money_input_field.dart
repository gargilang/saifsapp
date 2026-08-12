import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/utils/money.dart';

/// Input rupiah: mengetik angka -> tampil terformat ribuan (1.500.000).
/// Baca nilai dengan parseRupiah(controller.text).
class MoneyInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  const MoneyInputField(
      {super.key, required this.controller, required this.label, this.validator});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(labelText: label, prefixText: 'Rp '),
      validator: validator,
      onChanged: (v) {
        final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
        final formatted = digits.isEmpty
            ? ''
            : formatRupiah(int.parse(digits)).replaceFirst('Rp ', '');
        if (formatted != v) {
          controller.value = TextEditingValue(
            text: formatted,
            selection: TextSelection.collapsed(offset: formatted.length),
          );
        }
      },
    );
  }
}
