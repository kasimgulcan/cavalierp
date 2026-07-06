import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/price_format.dart';
import '../cart_provider.dart';
import '../currency_display.dart';
import '../currency_provider.dart';
import '../currency_selection.dart';
import '../models/cart_line.dart';
import 'product_thumbnail.dart';
import 'quantity_stepper.dart';

class CheckoutLineTile extends ConsumerStatefulWidget {
  const CheckoutLineTile({super.key, required this.line});

  final CartLine line;

  @override
  ConsumerState<CheckoutLineTile> createState() => _CheckoutLineTileState();
}

class _CheckoutLineTileState extends ConsumerState<CheckoutLineTile> {
  late final TextEditingController _unitPrice;
  bool _editingUnitPrice = false;

  @override
  void initState() {
    super.initState();
    _unitPrice = TextEditingController();
    _syncUnitPrice(widget.line);
  }

  @override
  void didUpdateWidget(covariant CheckoutLineTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editingUnitPrice) {
      _syncUnitPrice(widget.line);
    }
  }

  @override
  void dispose() {
    _unitPrice.dispose();
    super.dispose();
  }

  void _syncUnitPrice(CartLine line) {
    final currencyId =
        effectiveCurrencyId(ref.read(selectedCurrencyIdProvider));
    _unitPrice.text = formatDecimalInput(line.unitPriceFor(currencyId));
  }

  void _onUnitPriceSubmitted(CartLine line) {
    final parsed = parseDecimalInput(_unitPrice.text);
    _editingUnitPrice = false;
    if (parsed == null) {
      _syncUnitPrice(line);
      return;
    }
    ref.read(cartProvider.notifier).updateUnitPrice(
          line.product.sizeId,
          parsed,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currency = ref.watch(selectedCurrencyProvider);
    final currencyId = effectiveCurrencyId(ref.watch(selectedCurrencyIdProvider));
    final symbol = currencySymbolFrom(currency);
    final line = widget.line;
    final product = line.product;
    final sizeLabel = product.sizeLabel?.trim();

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProductThumbnail(imageUrl: product.imageUrl, size: 64),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (product.styleName?.trim().isNotEmpty == true)
                        Text(
                          product.styleName!.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      Text(
                        product.productName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                      if (sizeLabel != null && sizeLabel.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Beden: $sizeLabel',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (product.color?.trim().isNotEmpty == true) ...[
                        const SizedBox(height: 2),
                        Text(
                          product.color!.trim(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      tooltip: 'Sepetten çıkar',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      onPressed: () => ref
                          .read(cartProvider.notifier)
                          .removeLine(product.sizeId),
                      icon: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      formatPriceWithSymbol(
                        line.lineTotalFor(currencyId),
                        symbol,
                      ),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Adet',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                QuantityStepper(
                  compact: true,
                  value: line.quantity,
                  min: 1,
                  onChanged: (value) => ref
                      .read(cartProvider.notifier)
                      .updateQuantity(product.sizeId, value),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _unitPrice,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: InputDecoration(
                labelText: 'Birim fiyat',
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onTap: () => _editingUnitPrice = true,
              onSubmitted: (_) => _onUnitPriceSubmitted(line),
              onEditingComplete: () => _onUnitPriceSubmitted(line),
            ),
          ],
        ),
      ),
    );
  }
}
