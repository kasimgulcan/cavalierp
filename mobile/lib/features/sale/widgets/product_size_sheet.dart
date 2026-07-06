import 'package:flutter/material.dart';

import '../../../core/format/price_format.dart';
import '../models/product.dart';
import '../models/product_group.dart';
import 'product_image_viewer.dart';
import 'product_thumbnail.dart';
import 'quantity_stepper.dart';
import 'stock_warning_banner.dart';

typedef ProductSizeCartAction = void Function(Product product, int quantity);
typedef ProductSizeAction = void Function(Product product);

class _SessionAdd {
  const _SessionAdd({required this.sizeLabel, required this.quantity});

  final String sizeLabel;
  final int quantity;
}

Future<void> showProductSizeSheet({
  required BuildContext context,
  required ProductGroup group,
  required String currencySymbol,
  required int currencyId,
  required bool isStaff,
  required bool loggedIn,
  required ProductSizeCartAction onAddToCart,
  ProductSizeAction? onAddStock,
  VoidCallback? onGoToCart,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _ProductSizeSheetBody(
      group: group,
      currencySymbol: currencySymbol,
      currencyId: currencyId,
      isStaff: isStaff,
      loggedIn: loggedIn,
      onAddToCart: onAddToCart,
      onAddStock: onAddStock,
      onGoToCart: onGoToCart,
    ),
  );
}

class _ProductSizeSheetBody extends StatefulWidget {
  const _ProductSizeSheetBody({
    required this.group,
    required this.currencySymbol,
    required this.currencyId,
    required this.isStaff,
    required this.loggedIn,
    required this.onAddToCart,
    this.onAddStock,
    this.onGoToCart,
  });

  final ProductGroup group;
  final String currencySymbol;
  final int currencyId;
  final bool isStaff;
  final bool loggedIn;
  final ProductSizeCartAction onAddToCart;
  final ProductSizeAction? onAddStock;
  final VoidCallback? onGoToCart;

  @override
  State<_ProductSizeSheetBody> createState() => _ProductSizeSheetBodyState();
}

class _ProductSizeSheetBodyState extends State<_ProductSizeSheetBody> {
  final Map<int, _SessionAdd> _sessionAdds = {};
  final Map<int, int> _rowVersions = {};

  void _handleAddToCart(Product product, int quantity) {
    if (!widget.loggedIn) {
      Navigator.pop(context);
      widget.onAddToCart(product, quantity);
      return;
    }

    widget.onAddToCart(product, quantity);

    final sizeLabel = product.sizeLabel?.trim().isNotEmpty == true
        ? product.sizeLabel!
        : '—';
    final previous = _sessionAdds[product.sizeId];
    setState(() {
      _sessionAdds[product.sizeId] = _SessionAdd(
        sizeLabel: sizeLabel,
        quantity: (previous?.quantity ?? 0) + quantity,
      );
      _rowVersions[product.sizeId] = (_rowVersions[product.sizeId] ?? 0) + 1;
    });
  }

  void _goToCart() {
    Navigator.pop(context);
    widget.onGoToCart?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final allSizesOutOfStock = widget.group.allSizesOutOfStock;
    final sessionEntries = _sessionAdds.values.toList(growable: false);
    final showCartActions = widget.loggedIn && widget.onGoToCart != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.group.imageUrl?.trim().isNotEmpty == true
                      ? () => showProductImageViewer(
                            context,
                            widget.group.imageUrl,
                          )
                      : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    children: [
                      ProductThumbnail(
                        imageUrl: widget.group.imageUrl,
                        size: 56,
                      ),
                      if (widget.group.imageUrl?.trim().isNotEmpty == true)
                        Positioned(
                          right: 2,
                          bottom: 2,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(2),
                              child: Icon(
                                Icons.zoom_out_map_rounded,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.group.styleName != null &&
                        widget.group.styleName!.isNotEmpty)
                      Text(
                        widget.group.styleName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    Text(
                      widget.group.productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                    if (widget.group.color != null &&
                        widget.group.color!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.group.color!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      widget.group.priceLabel(
                        widget.currencySymbol,
                        widget.currencyId,
                      ),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Beden seçin',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (allSizesOutOfStock) ...[
            const SizedBox(height: 6),
            StockWarningBanner(
              message: StockWarningBanner.messageFor(
                stockQty: 0,
                quantity: 1,
                isStaff: widget.isStaff,
              ),
            ),
          ],
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.4,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: widget.group.sizes.length,
              separatorBuilder: (_, _) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final product = widget.group.sizes[index];
                return _ProductSizeRow(
                  key: ValueKey(
                    '${product.sizeId}_${_rowVersions[product.sizeId] ?? 0}',
                  ),
                  product: product,
                  isStaff: widget.isStaff,
                  suppressZeroStockWarning: allSizesOutOfStock,
                  onAddToCart: (quantity) =>
                      _handleAddToCart(product, quantity),
                  onAddStock: widget.isStaff && widget.onAddStock != null
                      ? () {
                          Navigator.pop(context);
                          widget.onAddStock!(product);
                        }
                      : null,
                );
              },
            ),
          ),
          if (sessionEntries.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Bu oturumda eklenenler',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final entry in sessionEntries)
                  Chip(
                    label: Text('${entry.sizeLabel} ×${entry.quantity}'),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Kapat'),
                ),
              ),
              if (showCartActions) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _goToCart,
                    icon: const Icon(Icons.shopping_cart_outlined, size: 18),
                    label: const Text('Sepete git'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductSizeRow extends StatefulWidget {
  const _ProductSizeRow({
    super.key,
    required this.product,
    required this.isStaff,
    required this.suppressZeroStockWarning,
    required this.onAddToCart,
    this.onAddStock,
  });

  final Product product;
  final bool isStaff;
  final bool suppressZeroStockWarning;
  final ValueChanged<int> onAddToCart;
  final VoidCallback? onAddStock;

  @override
  State<_ProductSizeRow> createState() => _ProductSizeRowState();
}

class _ProductSizeRowState extends State<_ProductSizeRow> {
  var _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final lowStock = widget.product.stockQty <= 0;
    final sizeLabel = widget.product.sizeLabel?.trim().isNotEmpty == true
        ? widget.product.sizeLabel!
        : '—';
    final stockWarning = StockWarningBanner.messageFor(
      stockQty: widget.product.stockQty,
      quantity: _quantity,
      isStaff: widget.isStaff,
    );
    final hideZeroStockWarning =
        widget.suppressZeroStockWarning && widget.product.stockQty <= 0;
    final showRowWarning = stockWarning.isNotEmpty && !hideZeroStockWarning;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: showRowWarning
              ? colorScheme.error.withValues(alpha: 0.4)
              : colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 72,
                  child: Text(
                    sizeLabel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                if (!lowStock || widget.isStaff)
                  Expanded(
                    child: Text(
                      'Stok: ${formatStock(widget.product.stockQty)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: lowStock
                            ? colorScheme.error
                            : colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  const Spacer(),
                if (widget.isStaff && widget.onAddStock != null) ...[
                  OutlinedButton(
                    onPressed: widget.onAddStock,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      '+ Stok',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                QuantityStepper(
                  compact: true,
                  value: _quantity,
                  onChanged: (value) => setState(() => _quantity = value),
                ),
                const SizedBox(width: 6),
                FilledButton.icon(
                  onPressed: () => widget.onAddToCart(_quantity),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.add_shopping_cart_outlined, size: 16),
                  label: const Text('Ekle'),
                ),
              ],
            ),
            if (showRowWarning) ...[
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: colorScheme.error,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      stockWarning,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.error,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
