import 'package:cavalierp/features/auth/auth_provider.dart';
import 'package:cavalierp/features/sale/cart_provider.dart';
import 'package:cavalierp/features/sale/checkout_discount.dart';
import 'package:cavalierp/features/sale/checkout_draft.dart';
import 'package:cavalierp/features/sale/models/product.dart';
import 'package:cavalierp/features/sale/sale_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

Product _product({int sizeId = 10}) {
  return Product(
    sizeId: sizeId,
    productName: 'Gömlek',
    priceTL: 100,
    priceEUR: 10,
    priceUSD: 12,
    stockQty: 4,
  );
}

Future<ProviderContainer> _loggedOutContainer(WidgetTester tester) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  container.read(authStateProvider);
  container.read(cartProvider);
  container.read(checkoutDraftProvider);
  for (var i = 0; i < 20; i++) {
    if (!container.read(authStateProvider).isLoading) break;
    await tester.pump(const Duration(milliseconds: 10));
  }
  expect(container.read(authStateProvider).valueOrNull, isFalse);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  testWidgets('emptying the cart ends an in-progress sale edit', (
    tester,
  ) async {
    final container = await _loggedOutContainer(tester);

    container.read(editingSaleIdProvider.notifier).state = 119;
    container
        .read(checkoutDraftProvider.notifier)
        .replace(
          const CheckoutDraft(
            customer: 'Eski müşteri',
            phone: '0555',
            discount: CheckoutDiscountInput(percent: 10),
          ),
        );
    container.read(cartProvider.notifier).addProduct(_product());
    container.read(cartProvider.notifier).addProduct(_product(sizeId: 11));

    container.read(cartProvider.notifier).removeLine(10);
    expect(container.read(editingSaleIdProvider), 119);
    expect(container.read(checkoutDraftProvider).customer, 'Eski müşteri');

    container.read(cartProvider.notifier).removeLine(11);

    expect(container.read(cartProvider), isEmpty);
    expect(container.read(editingSaleIdProvider), isNull);
    expect(container.read(checkoutDraftProvider).hasUserInput, isFalse);
  });

  testWidgets('emptying a new sale keeps the checkout draft', (tester) async {
    final container = await _loggedOutContainer(tester);

    container
        .read(checkoutDraftProvider.notifier)
        .replace(const CheckoutDraft(customer: 'Ayşe'));
    container.read(cartProvider.notifier).addProduct(_product());
    container.read(cartProvider.notifier).clear();

    expect(container.read(editingSaleIdProvider), isNull);
    expect(container.read(checkoutDraftProvider).customer, 'Ayşe');
  });

  testWidgets('Yeni satış drops the edit without saving it', (tester) async {
    final container = await _loggedOutContainer(tester);

    container.read(editingSaleIdProvider.notifier).state = 119;
    container
        .read(checkoutDraftProvider.notifier)
        .replace(const CheckoutDraft(customer: 'Eski müşteri'));
    container.read(cartProvider.notifier).addProduct(_product());

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              return TextButton(
                onPressed: () => startNewSale(ref),
                child: const Text('Yeni satış'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Yeni satış'));
    await tester.pump();

    expect(container.read(editingSaleIdProvider), isNull);
    expect(container.read(cartProvider), isEmpty);
    expect(container.read(checkoutDraftProvider).hasUserInput, isFalse);
    expect(container.read(checkoutDraftProvider).customer, isEmpty);
  });
}
