import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'checkout_note.dart';
import 'models/order_request.dart';
import 'order_request_provider.dart';
import 'widgets/checkout_form_section.dart';
import 'widgets/order_request_contact_section.dart';
import 'widgets/order_request_detail_summary.dart';
import 'widgets/order_request_line_tile.dart';
import 'widgets/order_request_total_bar.dart';

class MyOrderDetailScreen extends ConsumerWidget {
  const MyOrderDetailScreen({super.key, required this.orderRequestId});

  final int orderRequestId;

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.'
        '${dt.month.toString().padLeft(2, '0')}.'
        '${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(myOrderDetailProvider(orderRequestId));

    return Scaffold(
      appBar: AppBar(title: Text('Talep #$orderRequestId')),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error.toString()),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () =>
                    ref.invalidate(myOrderDetailProvider(orderRequestId)),
                child: const Text('Tekrar dene'),
              ),
            ],
          ),
        ),
        data: (detail) => _OrderDetailBody(
          detail: detail,
          formatDateTime: _formatDateTime,
        ),
      ),
    );
  }
}

class _OrderDetailBody extends StatelessWidget {
  const _OrderDetailBody({
    required this.detail,
    required this.formatDateTime,
  });

  final OrderRequestDetail detail;
  final String Function(DateTime) formatDateTime;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = detail.lines.fold(0.0, (sum, line) => sum + line.computedTotal);
    final parsedNote = parseCheckoutNote(detail.note);
    final displayTitle = detail.displayName;
    final customerName = detail.customer?.trim();
    final showCustomerInContact =
        customerName != null &&
        customerName.isNotEmpty &&
        customerName != displayTitle;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              OrderRequestDetailSummaryCard(
                title: displayTitle,
                status: detail.status,
                subtitle: showCustomerInContact ? null : detail.memberEmail,
                createdAtLabel: detail.createdAt != null
                    ? formatDateTime(detail.createdAt!.toLocal())
                    : null,
                lineCount: detail.lines.length,
              ),
              const SizedBox(height: 12),
              OrderRequestContactSection(
                customer: showCustomerInContact ? customerName : null,
                phone: parsedNote.phone,
                email: parsedNote.email,
                memberEmail: detail.memberEmail,
              ),
              if (parsedNote.note?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 12),
                CheckoutFormSection(
                  title: 'Not',
                  children: [
                    Text(
                      parsedNote.note!.trim(),
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'Kalemler',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              ...detail.lines.map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: OrderRequestLineTile(line: line),
                ),
              ),
            ],
          ),
        ),
        OrderRequestTotalBar(
          lineCount: detail.lines.length,
          total: total,
        ),
      ],
    );
  }
}
