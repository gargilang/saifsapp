import 'package:flutter/material.dart';

class CustomerDetailPage extends StatelessWidget {
  final String customerId;
  const CustomerDetailPage({super.key, required this.customerId});
  @override
  Widget build(BuildContext context) => Center(child: Text('Customer $customerId'));
}
