import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/format/price_format.dart';
import '../../core/network/sp_client.dart';
import '../auth/auth_provider.dart';
import 'checkout_discount.dart';
import 'checkout_draft.dart';
import 'currency_selection.dart';
import 'models/cart_line.dart';
import 'models/order_request.dart';
import 'models/product.dart';
import 'models/sale.dart';

final cartProvider = StateNotifierProvider<CartNotifier, List<CartLine>>((ref) {
  final notifier = CartNotifier(
    ref.watch(spClientProvider),
    onBecameEmpty: () {
      // An open edit lives only in memory. An empty cart means that edit is
      // over; the saved sale is left untouched.
      if (ref.read(editingSaleIdProvider) == null) return;
      ref.read(editingSaleIdProvider.notifier).state = null;
      ref.read(checkoutDraftProvider.notifier).clear();
    },
  );
  ref.listen(authStateProvider, (previous, next) {
    if (next.valueOrNull != true) {
      notifier.clear();
      ref.read(editingSaleIdProvider.notifier).state = null;
    }
  });
  return notifier;
});

class CartNotifier extends StateNotifier<List<CartLine>> {
  CartNotifier(this._spClient, {this.onBecameEmpty}) : super([]);

  final SpClient _spClient;
  final void Function()? onBecameEmpty;

  void _setLines(List<CartLine> next) {
    final becameEmpty = state.isNotEmpty && next.isEmpty;
    state = next;
    if (becameEmpty) onBecameEmpty?.call();
  }

  double totalFor(int currencyId) => roundSaleMoney(
        state.fold(0, (sum, line) => sum + line.lineTotalFor(currencyId)),
      );

  void addProduct(Product product, {int quantity = 1, double? unitPrice}) {
    final existing = state.indexWhere(
      (l) => l.product.sizeId == product.sizeId,
    );
    if (existing >= 0) {
      final updated = [...state];
      updated[existing].quantity += quantity;
      state = updated;
      return;
    }
    state = [
      ...state,
      CartLine(
        product: product,
        quantity: quantity,
        unitPriceOverride: unitPrice,
      ),
    ];
  }

  void updateQuantity(int sizeId, int quantity) {
    if (quantity <= 0) {
      removeLine(sizeId);
      return;
    }
    state = [
      for (final line in state)
        if (line.product.sizeId == sizeId)
          CartLine(
            product: line.product,
            quantity: quantity,
            unitPriceOverride: line.unitPriceOverride,
            listPriceOverride: line.listPriceOverride,
            isGift: line.isGift,
          )
        else
          line,
    ];
  }

  void updateUnitPrice(int sizeId, double unitPrice) {
    state = [
      for (final line in state)
        if (line.product.sizeId == sizeId)
          CartLine(
            product: line.product,
            quantity: line.quantity,
            unitPriceOverride: unitPrice < 0 ? 0 : unitPrice,
            listPriceOverride: line.listPriceOverride,
            isGift: line.isGift && unitPrice <= 0,
          )
        else
          line,
    ];
  }

  void removeLine(int sizeId) {
    _setLines(state.where((l) => l.product.sizeId != sizeId).toList());
  }

  void clear() => _setLines([]);

  void setGift(int sizeId, bool isGift) {
    state = [
      for (final line in state)
        if (line.product.sizeId == sizeId)
          CartLine(
            product: line.product,
            quantity: line.quantity,
            unitPriceOverride: isGift ? 0 : null,
            listPriceOverride: line.listPriceOverride,
            isGift: isGift,
          )
        else
          line,
    ];
  }

  void loadFromSaleDetail(SaleDetail detail) {
    final currencyId = detail.currencyId ?? kDefaultCurrencyId;
    _setLines([
      for (final line in detail.lines)
        CartLine(
          product: _productFromSaleLine(line, currencyId),
          quantity: line.quantity,
          unitPriceOverride: line.unitPrice,
          listPriceOverride:
              line.listPrice > 0 ? line.listPrice : line.unitPrice,
          isGift: line.unitPrice == 0 && line.listPrice > 0,
        ),
    ]);
  }

  void loadFromOrderRequest(OrderRequestDetail detail) {
    final currencyId = detail.currencyId ?? kDefaultCurrencyId;
    _setLines([
      for (final line in detail.lines)
        CartLine(
          product: _productFromOrderLine(line, currencyId),
          quantity: line.quantity,
          unitPriceOverride: line.unitPrice,
          listPriceOverride:
              line.listPrice > 0 ? line.listPrice : line.unitPrice,
        ),
    ]);
  }

  Product _productFromSaleLine(SaleLine line, int currencyId) {
    final price = line.listPrice > 0 ? line.listPrice : line.unitPrice;
    return Product(
      sizeId: line.sizeId,
      productName: line.product,
      priceTL: currencyId == kDefaultCurrencyId ? price : 0,
      priceEUR: currencyId == kEurCurrencyId ? price : 0,
      priceUSD: currencyId == kUsdCurrencyId ? price : 0,
      stockQty: (line.stockQty ?? 0).toDouble(),
    );
  }

  Product _productFromOrderLine(OrderRequestLine line, int currencyId) {
    final price = line.unitPrice;
    return Product(
      sizeId: line.sizeId,
      productName: line.product,
      priceTL: currencyId == kDefaultCurrencyId ? price : 0,
      priceEUR: currencyId == kEurCurrencyId ? price : 0,
      priceUSD: currencyId == kUsdCurrencyId ? price : 0,
      stockQty: (line.stockQty ?? 0).toDouble(),
      styleName: line.styleName,
      color: line.color,
      sizeLabel: line.sizeLabel,
      productCode: line.productCode,
      imageUrl: line.imageUrl,
    );
  }

  Future<Product?> lookupBarcode(String barcode) async {
    final response = await _spClient.exec('Product.GetByBarcode', {
      'Barcode': barcode,
    });
    if (!response.success) return null;
    final rows = response.data as List<dynamic>;
    if (rows.isEmpty) return null;
    return Product.fromJson(Map<String, dynamic>.from(rows.first as Map));
  }

  Future<Map<String, dynamic>?> completeSale({
    required int currencyId,
    String? customer,
    int? paymentTypeId,
    String? note,
    int? orderRequestId,
    double discountPercent = 0,
    double discountFixedAmount = 0,
  }) async {
    final lines = _linesPayload(currencyId);

    final response = await _spClient.exec('Sale.Create', {
      'CurrencyId': currencyId,
      'Customer': customer,
      'PaymentTypeId': paymentTypeId,
      'Lines': lines,
      'Note': note ?? '',
      'OrderRequestId': ?orderRequestId,
      'DiscountPercent': discountPercent,
      'DiscountFixedAmount': roundSaleMoney(discountFixedAmount),
    });

    if (!response.success) return null;
    final rows = response.data as List<dynamic>;
    if (rows.isEmpty) return null;
    return Map<String, dynamic>.from(rows.first as Map);
  }

  Future<Map<String, dynamic>?> updateSale({
    required int saleId,
    required int currencyId,
    String? customer,
    int? paymentTypeId,
    String? note,
    double discountPercent = 0,
    double discountFixedAmount = 0,
  }) async {
    final lines = _linesPayload(currencyId);
    final response = await _spClient.exec('Sale.Update', {
      'SaleId': saleId,
      'Customer': customer,
      'PaymentTypeId': paymentTypeId,
      'Lines': lines,
      'Note': note ?? '',
      'DiscountPercent': discountPercent,
      'DiscountFixedAmount': roundSaleMoney(discountFixedAmount),
    });

    if (!response.success) return null;
    final rows = response.data as List<dynamic>;
    if (rows.isEmpty) return null;
    return Map<String, dynamic>.from(rows.first as Map);
  }

  Future<Map<String, dynamic>?> submitOrderRequest({
    required int currencyId,
    String? customer,
    String? note,
  }) async {
    final lines = _linesPayload(currencyId);

    final response = await _spClient.exec('OrderRequest.Create', {
      'CurrencyId': currencyId,
      'Customer': customer,
      'Lines': lines,
      'Note': note ?? '',
    });

    if (!response.success) return null;
    final rows = response.data as List<dynamic>;
    if (rows.isEmpty) return null;
    return Map<String, dynamic>.from(rows.first as Map);
  }

  List<Map<String, dynamic>> _linesPayload(int currencyId) {
    return buildSaleLinesPayload(lines: state, currencyId: currencyId);
  }
}
