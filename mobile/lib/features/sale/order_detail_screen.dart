import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'cart_provider.dart';
import 'checkout_note.dart';
import 'currency_display.dart';
import 'currency_provider.dart';
import 'currency_selection.dart';
import 'models/order_request.dart';
import 'order_request_provider.dart';
import 'pending_order_checkout_provider.dart';
import 'sale_totals.dart';
import 'widgets/checkout_form_section.dart';
import 'widgets/order_request_contact_section.dart';
import 'widgets/order_request_detail_summary.dart';
import 'widgets/order_request_line_tile.dart';
import 'widgets/order_request_total_bar.dart';
import 'widgets/sale_discount_summary_section.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({super.key, required this.orderRequestId});

  final int orderRequestId;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  bool _rejecting = false;

  Future<void> _reject(OrderRequestDetail detail) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Talebi reddet'),
        content: const Text('Bu talep reddedilecek. Emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reddet'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _rejecting = true);
    final repo = ref.read(orderRequestRepositoryProvider);
    final result = await repo.update(
      orderRequestId: detail.orderRequestId,
      status: 'Rejected',
    );
    setState(() => _rejecting = false);
    if (!mounted) return;

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reddedilemedi')),
      );
      return;
    }

    ref.invalidate(orderDetailProvider(widget.orderRequestId));
  }

  void _startCheckout(OrderRequestDetail detail) {
    if (detail.lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az bir kalem olmalı')),
      );
      return;
    }

    final parsed = parseCheckoutNote(detail.note);
    final customer = detail.customer?.trim();
    ref.read(selectedCurrencyIdProvider.notifier).state =
        detail.currencyId ?? kDefaultCurrencyId;
    ref.read(cartProvider.notifier).loadFromOrderRequest(detail);
    ref.read(pendingOrderCheckoutProvider.notifier).state = PendingOrderCheckout(
      orderRequestId: detail.orderRequestId,
      customer: customer?.isNotEmpty == true ? customer : null,
      phone: parsed.phone,
      email: parsed.email,
      note: parsed.note,
    );
    context.push('/checkout');
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.'
        '${dt.month.toString().padLeft(2, '0')}.'
        '${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(orderDetailProvider(widget.orderRequestId));

    return Scaffold(
      appBar: AppBar(title: Text('Talep #${widget.orderRequestId}')),
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
                    ref.invalidate(orderDetailProvider(widget.orderRequestId)),
                child: const Text('Tekrar dene'),
              ),
            ],
          ),
        ),
        data: (detail) => _OrderDetailBody(
          detail: detail,
          rejecting: _rejecting,
          formatDateTime: _formatDateTime,
          onReject: () => _reject(detail),
          onConvert: () => _startCheckout(detail),
        ),
      ),
    );
  }
}

class _OrderDetailBody extends ConsumerWidget {
  const _OrderDetailBody({
    required this.detail,
    required this.rejecting,
    required this.formatDateTime,
    required this.onReject,
    required this.onConvert,
  });

  final OrderRequestDetail detail;
  final bool rejecting;
  final String Function(DateTime) formatDateTime;
  final VoidCallback onReject;
  final VoidCallback onConvert;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final symbol = currencySymbolFrom(ref.watch(selectedCurrencyProvider));
    final total = detail.lines.fold(0.0, (sum, line) => sum + line.computedTotal);
    final parsedNote = parseCheckoutNote(detail.note);
    final displayTitle = detail.displayName;
    final customerName = detail.customer?.trim();
    final showCustomerInContact =
        customerName != null &&
        customerName.isNotEmpty &&
        customerName != displayTitle;
    final canAct = detail.canConvertOrReject;

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
              if (detail.convertedSaleId != null) ...[
                const SizedBox(height: 12),
                CheckoutFormSection(
                  title: 'Oluşan satış',
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () =>
                            context.push('/sales/${detail.convertedSaleId}'),
                        child: Text('Satış #${detail.convertedSaleId}'),
                      ),
                    ),
                  ],
                ),
                if (detail.convertedSaleDiscountInput != null &&
                    detail.convertedSaleSubtotal != null) ...[
                  const SizedBox(height: 12),
                  SaleDiscountSummarySection(
                    subtotal: detail.convertedSaleSubtotal!,
                    discount: detail.convertedSaleDiscountInput!,
                    symbol: symbol,
                  ),
                ],
              ],
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
                  child: OrderRequestLineTile(line: line, showStock: true),
                ),
              ),
            ],
          ),
        ),
        if (canAct)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton(
                  onPressed: rejecting ? null : onConvert,
                  child: const Text('Satışa Dönüştür'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: rejecting ? null : onReject,
                  child: rejecting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Reddet'),
                ),
              ],
            ),
          )
        else
          OrderRequestTotalBar(
            lineCount: detail.lines.length,
            total: detail.convertedSaleNetTotal ?? total,
            subtotal: detail.convertedSaleDiscountInput != null
                ? detail.convertedSaleSubtotal
                : null,
            discountAmount: detail.convertedSaleDiscountInput != null &&
                    detail.convertedSaleSubtotal != null
                ? detail.convertedSaleDiscountInput!
                    .totalDiscountAmount(detail.convertedSaleSubtotal!)
                : null,
            currencySymbol: symbol,
          ),
      ],
    );
  }
}
