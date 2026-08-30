import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_provider.dart';
import 'cart_provider.dart';
import 'checkout_discount.dart';
import 'checkout_draft.dart';
import 'checkout_note.dart';
import 'currency_display.dart';
import 'currency_provider.dart';
import 'currency_selection.dart';
import 'models/sale.dart';
import 'order_request_provider.dart';
import 'sale_provider.dart';
import 'sale_totals.dart';
import 'widgets/checkout_form_section.dart';
import 'widgets/order_request_contact_section.dart';
import 'widgets/order_request_total_bar.dart';
import 'widgets/sale_detail_action_bar.dart';
import 'widgets/sale_discount_summary_section.dart';
import 'widgets/sale_line_tile.dart';

final _paymentTypesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(spClientProvider);
  final response = await client.exec('Lookup.PaymentTypes', {});
  if (!response.success) return [];
  return (response.data as List)
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();
});

class SaleDetailScreen extends ConsumerStatefulWidget {
  const SaleDetailScreen({super.key, required this.saleId});

  final int saleId;

  @override
  ConsumerState<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends ConsumerState<SaleDetailScreen> {
  bool _cancelling = false;

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.'
        '${dt.month.toString().padLeft(2, '0')}.'
        '${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _cancel(SaleDetail detail) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Satışı iptal et'),
        content: const Text(
          'Bu satış kalıcı olarak silinecek. Emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('İptal et'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _cancelling = true);
    final ok = await ref.read(saleRepositoryProvider).cancel(
          saleId: detail.saleId,
        );
    setState(() => _cancelling = false);
    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Satış iptal edilemedi')),
      );
      return;
    }

    if (detail.orderRequestId != null) {
      ref.invalidate(orderDetailProvider(detail.orderRequestId!));
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Satış iptal edildi')),
    );
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  void _edit(SaleDetail detail) {
    final parsed = parseCheckoutNote(detail.note);
    ref.read(cartProvider.notifier).loadFromSaleDetail(detail);
    ref.read(checkoutDraftProvider.notifier).replace(
          CheckoutDraft(
            customer: detail.customer ?? '',
            phone: parsed.phone ?? '',
            email: parsed.email ?? '',
            note: parsed.note ?? '',
            paymentTypeId: detail.paymentTypeId,
            discount: CheckoutDiscountInput(
              percent: detail.discountPercent ?? 0,
              fixedAmount: detail.discountFixedAmount ?? 0,
            ),
          ),
        );
    ref.read(editingSaleIdProvider.notifier).state = detail.saleId;
    if (detail.currencyId != null) {
      ref.read(selectedCurrencyIdProvider.notifier).state = detail.currencyId!;
    }
    context.push('/checkout');
  }

  String? _paymentTypeName(
    List<Map<String, dynamic>> types,
    int? paymentTypeId,
  ) {
    if (paymentTypeId == null) return null;
    for (final item in types) {
      if ((item['PaymentTypeId'] as num).toInt() == paymentTypeId) {
        return item['Name'] as String?;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(saleDetailProvider(widget.saleId));
    final paymentTypes = ref.watch(_paymentTypesProvider);
    final currency = ref.watch(selectedCurrencyProvider);
    final symbol = currencySymbolFrom(currency);

    return Scaffold(
      appBar: AppBar(title: Text('Satış #${widget.saleId}')),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(error.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () =>
                      ref.invalidate(saleDetailProvider(widget.saleId)),
                  child: const Text('Tekrar dene'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Ana Sayfa'),
                ),
              ],
            ),
          ),
        ),
        data: (detail) => _SaleDetailBody(
          detail: detail,
          symbol: symbol,
          paymentTypeName: paymentTypes.maybeWhen(
            data: (types) => _paymentTypeName(types, detail.paymentTypeId),
            orElse: () => null,
          ),
          cancelling: _cancelling,
          formatDateTime: _formatDateTime,
          onCancel: () => _cancel(detail),
          onEdit: () => _edit(detail),
        ),
      ),
    );
  }
}

class _SaleDetailBody extends StatelessWidget {
  const _SaleDetailBody({
    required this.detail,
    required this.symbol,
    required this.paymentTypeName,
    required this.cancelling,
    required this.formatDateTime,
    required this.onCancel,
    required this.onEdit,
  });

  final SaleDetail detail;
  final String symbol;
  final String? paymentTypeName;
  final bool cancelling;
  final String Function(DateTime) formatDateTime;
  final VoidCallback onCancel;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = detail.netTotal;
    final parsedNote = parseCheckoutNote(detail.note);
    final customerName = detail.customer?.trim();
    final displayTitle = (customerName != null && customerName.isNotEmpty)
        ? customerName
        : detail.staffEmail;
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
              _SaleSummaryHeader(
                saleId: detail.saleId,
                title: displayTitle,
                subtitle: detail.staffEmail,
                createdAtLabel: detail.createdAt != null
                    ? formatDateTime(detail.createdAt!.toLocal())
                    : null,
                lineCount: detail.lines.length,
              ),
              if (detail.orderRequestId != null) ...[
                const SizedBox(height: 12),
                CheckoutFormSection(
                  title: 'Kaynak talep',
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () =>
                            context.push('/orders/${detail.orderRequestId}'),
                        child: Text('Talep #${detail.orderRequestId}'),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              OrderRequestContactSection(
                customer: showCustomerInContact ? customerName : null,
                phone: parsedNote.phone,
                email: parsedNote.email,
                memberEmail: detail.staffEmail,
              ),
              if (paymentTypeName != null) ...[
                const SizedBox(height: 12),
                CheckoutFormSection(
                  title: 'Ödeme',
                  children: [
                    Text(
                      paymentTypeName!,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              ],
              if (detail.hasDiscount) ...[
                const SizedBox(height: 12),
                SaleDiscountSummarySection(
                  subtotal: detail.listSubtotal,
                  discount: detail.discountInput,
                  symbol: symbol,
                ),
              ],
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
                  child: SaleLineTile(line: line, currencySymbol: symbol),
                ),
              ),
            ],
          ),
        ),
        SaleDetailActionBar(
          cancelling: cancelling,
          onEdit: onEdit,
          onCancel: onCancel,
        ),
        OrderRequestTotalBar(
          lineCount: detail.lines.length,
          total: total,
          subtotal: detail.hasDiscount ? detail.listSubtotal : null,
          discountAmount: detail.hasDiscount ? detail.discountAmount : null,
          currencySymbol: symbol,
        ),
      ],
    );
  }
}

class _SaleSummaryHeader extends StatelessWidget {
  const _SaleSummaryHeader({
    required this.saleId,
    required this.title,
    required this.subtitle,
    this.createdAtLabel,
    this.lineCount,
  });

  final int saleId;
  final String title;
  final String subtitle;
  final String? createdAtLabel;
  final int? lineCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.45),
            ),
            child: const SizedBox(height: 4),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Satış #$saleId',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                if (createdAtLabel != null || lineCount != null) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (createdAtLabel != null)
                        _MetaChip(
                          icon: Icons.schedule_outlined,
                          label: createdAtLabel!,
                        ),
                      if (lineCount != null)
                        _MetaChip(
                          icon: Icons.inventory_2_outlined,
                          label: '$lineCount kalem',
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
