import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cavalierp/features/auth/user_profile_provider.dart';
import 'package:cavalierp/features/sale/cart_provider.dart';
import 'package:cavalierp/features/sale/models/product.dart';
import 'package:cavalierp/features/sale/pending_cart_add_provider.dart';

void main() {
  test('apply adds queued product after login', () {
    final container = ProviderContainer(
      overrides: [
        isStaffProvider.overrideWith((ref) => false),
      ],
    );
    addTearDown(container.dispose);

    final product = Product(
      sizeId: 10,
      productName: 'Gömlek',
      priceTL: 100,
      priceEUR: 90,
      priceUSD: 90,
      stockQty: 0,
      sizeLabel: 'M',
      productCode: 'CODE-1',
    );

    container.read(pendingCartAddProvider.notifier).queue(product, 2);

    final message = container.read(pendingCartAddProvider.notifier).apply();
    expect(message, 'Stokta yok; talep sepetinize eklendi.');
    expect(container.read(pendingCartAddProvider), isNull);
    expect(container.read(cartProvider), hasLength(1));
    expect(container.read(cartProvider).first.quantity, 2);
  });
}
