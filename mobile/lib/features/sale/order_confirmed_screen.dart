import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OrderConfirmedScreen extends StatelessWidget {
  const OrderConfirmedScreen({super.key, required this.order});

  final Map<String, dynamic> order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Talep Alındı')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 72, color: theme.colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              'Talebiniz alındı',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Ekibimiz talebinizi inceleyecek ve sizinle iletişime geçecektir.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (order['OrderRequestId'] != null) ...[
              const SizedBox(height: 24),
              Text('Talep No: ${order['OrderRequestId']}'),
            ],
            const Spacer(),
            FilledButton(
              onPressed: () => context.go('/home'),
              child: const Text('Ürünlere Dön'),
            ),
          ],
        ),
      ),
    );
  }
}
