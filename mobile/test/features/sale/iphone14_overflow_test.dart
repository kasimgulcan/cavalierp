import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cavalierp/features/sale/models/order_request.dart';
import 'package:cavalierp/features/sale/models/sale.dart';
import 'package:cavalierp/features/sale/widgets/cart_summary_bar.dart';
import 'package:cavalierp/features/sale/widgets/order_list_filter_bar.dart';
import 'package:cavalierp/features/sale/widgets/order_request_list_card.dart';
import 'package:cavalierp/features/sale/widgets/order_status_chip.dart';
import 'package:cavalierp/features/sale/widgets/sale_detail_action_bar.dart';
import 'package:cavalierp/features/sale/widgets/sale_list_card.dart';
import 'package:cavalierp/features/sale/widgets/sale_list_filter_bar.dart';

/// iPhone 14 Pro logical size (portrait).
const _iphone14Pro = Size(393, 852);

Future<void> _pumpAtPhoneSize(
  WidgetTester tester,
  Widget child, {
  Size size = _iphone14Pro,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('iPhone 14 Pro overflow', () {
    testWidgets('order list filter bar', (tester) async {
      await _pumpAtPhoneSize(
        tester,
        OrderListFilterBar(
          dateFromLabel: '01.01.2026',
          dateToLabel: '06.07.2026',
          status: 'Pending',
          onPickDateFrom: () {},
          onPickDateTo: () {},
          onStatusChanged: (_) {},
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('sale list filter bar', (tester) async {
      await _pumpAtPhoneSize(
        tester,
        SaleListFilterBar(
          dateFromLabel: '01.01.2026',
          dateToLabel: '06.07.2026',
          onPickDateFrom: () {},
          onPickDateTo: () {},
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('order request list card — worst case', (tester) async {
      await _pumpAtPhoneSize(
        tester,
        OrderRequestListCard(
          order: const OrderRequestSummary(
            orderRequestId: 99999,
            memberEmail: 'very.long.customer.name@example.com',
            customer: 'Çok Uzun Müşteri Adı ve Firma Unvanı Limited Şirketi',
            status: 'Pending',
            createdAt: null,
            totalAmount: 9999999.99,
            lineCount: 99,
          ),
          createdAtLabel: '06.07.2026 11:55',
          lineCount: 99,
          showStatusChip: true,
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('sale list card — worst case', (tester) async {
      await _pumpAtPhoneSize(
        tester,
        SaleListCard(
          sale: SaleSummary(
            saleId: 99999,
            staffEmail: 'staff@example.com',
            customer: 'Çok Uzun Müşteri Adı ve Firma Unvanı',
            createdAt: DateTime(2026, 7, 6),
            totalAmount: 9999999,
            lineCount: 99,
            orderRequestId: 12345,
          ),
          createdAtLabel: '06.07.2026 11:55',
          amountLabel: '9.999.999 ₺',
          symbol: '₺',
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('sale detail action bar — equal size row', (tester) async {
      await _pumpAtPhoneSize(
        tester,
        SaleDetailActionBar(
          cancelling: false,
          onEdit: () {},
          onCancel: () {},
        ),
      );
      expect(tester.takeException(), isNull);

      final editSize = tester.getSize(find.widgetWithText(FilledButton, 'Düzenle'));
      final cancelSize = tester.getSize(
        find.widgetWithText(OutlinedButton, 'İptal Et'),
      );
      expect(editSize.height, cancelSize.height);
      expect((editSize.width - cancelSize.width).abs(), lessThan(1));
    });

    testWidgets('cart summary bar — large total', (tester) async {
      await _pumpAtPhoneSize(
        tester,
        CartSummaryBar(
          itemCount: 99,
          totalLabel: '9.999.999 ₺',
          actionLabel: 'Satışı Tamamla',
          onAction: () {},
          subtotalLabel: '10.500.000 ₺',
          discountAmount: 500001,
          discountSymbol: '₺',
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('order status chips', (tester) async {
      await _pumpAtPhoneSize(
        tester,
        Wrap(
          spacing: 4,
          children: const [
            OrderStatusChip(status: 'Pending'),
            OrderStatusChip(status: 'Rejected'),
            OrderStatusChip(status: 'Converted'),
          ],
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('staff bottom navigation — all tabs labeled', (tester) async {
      const destinations = [
        NavigationDestination(
          icon: Icon(Icons.storefront),
          label: 'Ürün',
          tooltip: 'Ürünler',
        ),
        NavigationDestination(
          icon: Icon(Icons.assignment_outlined),
          label: 'Talep',
          tooltip: 'Talepler',
        ),
        NavigationDestination(
          icon: Icon(Icons.shopping_cart),
          label: 'Sepet',
          tooltip: 'Sepet',
        ),
        NavigationDestination(
          icon: Icon(Icons.point_of_sale),
          label: 'Satış',
          tooltip: 'Satışlar',
        ),
        NavigationDestination(
          icon: Icon(Icons.bar_chart_rounded),
          label: 'Rapor',
          tooltip: 'Raporlar',
        ),
        NavigationDestination(
          icon: Icon(Icons.person),
          label: 'Profil',
          tooltip: 'Profil',
        ),
      ];

      tester.view.physicalSize = _iphone14Pro;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      for (var selected = 0; selected < destinations.length; selected++) {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(useMaterial3: true),
            home: Scaffold(
              bottomNavigationBar: Theme(
                data: ThemeData(useMaterial3: true).copyWith(
                  navigationBarTheme: NavigationBarThemeData(
                    height: 64,
                    labelTextStyle: WidgetStateProperty.resolveWith((states) {
                      return const TextStyle(
                        fontSize: 9,
                        height: 1.0,
                        letterSpacing: -0.1,
                      );
                    }),
                    iconTheme: WidgetStateProperty.resolveWith((_) {
                      return const IconThemeData(size: 21);
                    }),
                  ),
                ),
                child: NavigationBar(
                  selectedIndex: selected,
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  destinations: destinations,
                  onDestinationSelected: (_) {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'selected tab $selected');
      }
    });
  });
}
