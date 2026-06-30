import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SaleSummaryScreen extends StatelessWidget {
  const SaleSummaryScreen({super.key, required this.sale});

  final Map<String, dynamic> sale;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Satış Özeti')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Satış No: ${sale['SaleId']}'),
            Text('Toplam: ${sale['TotalAmount']}'),
            const Spacer(),
            FilledButton(
              onPressed: () => context.go('/home'),
              child: const Text('Ana Sayfa'),
            ),
          ],
        ),
      ),
    );
  }
}
