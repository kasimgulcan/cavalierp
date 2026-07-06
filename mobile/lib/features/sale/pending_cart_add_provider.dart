import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/user_profile_provider.dart';
import 'cart_provider.dart';
import 'models/product.dart';
import 'widgets/stock_warning_banner.dart';

class PendingCartAdd {
  const PendingCartAdd({required this.product, required this.quantity});

  final Product product;
  final int quantity;
}

class PendingCartAddNotifier extends StateNotifier<PendingCartAdd?> {
  PendingCartAddNotifier(this._ref) : super(null);

  final Ref _ref;

  void queue(Product product, int quantity) {
    state = PendingCartAdd(product: product, quantity: quantity);
  }

  void clear() => state = null;

  /// Giriş/kayıt sonrası bekleyen sepete ekleme varsa uygular. Snackbar metni döner.
  String? apply() {
    final pending = state;
    if (pending == null) return null;

    _ref.read(cartProvider.notifier).addProduct(
          pending.product,
          quantity: pending.quantity,
        );
    state = null;

    final isStaff = _ref.read(isStaffProvider);
    return StockWarningBanner.cartSnackBarMessage(
      stockQty: pending.product.stockQty,
      quantity: pending.quantity,
      isStaff: isStaff,
    );
  }
}

final pendingCartAddProvider =
    StateNotifierProvider<PendingCartAddNotifier, PendingCartAdd?>((ref) {
  return PendingCartAddNotifier(ref);
});
