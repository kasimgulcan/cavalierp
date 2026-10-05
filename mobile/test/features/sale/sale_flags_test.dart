import 'package:cavalierp/features/sale/models/sale.dart';
import 'package:cavalierp/features/sale/models/sale_flags.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('single flags use legacy codes and FlagMask', () {
    const payment = SaleFlags(kinds: {SaleFlagKind.payment});
    const production = SaleFlags(kinds: {SaleFlagKind.production});
    const followUp = SaleFlags(kinds: {SaleFlagKind.followUp});

    expect(payment.toParams(), {'FlagMask': 1});
    expect(production.toParams(), {'FlagMask': 2});
    expect(followUp.toParams(), {'FlagMask': 3});
    expect(const SaleFlags().toParams(), {'FlagMask': 0});
  });

  test('two or more flags use the mode bit', () {
    const paymentAndProduction = SaleFlags(
      kinds: {SaleFlagKind.payment, SaleFlagKind.production},
    );
    const all = SaleFlags(
      kinds: {
        SaleFlagKind.payment,
        SaleFlagKind.production,
        SaleFlagKind.followUp,
      },
    );

    expect(paymentAndProduction.toParams(), {'FlagMask': 131});
    expect(all.toParams(), {'FlagMask': 135});
  });

  test('toggle changes only the tapped flag', () {
    const payment = SaleFlags(kinds: {SaleFlagKind.payment});
    final both = payment.toggle(SaleFlagKind.production);
    final cleared = both.toggle(SaleFlagKind.payment);

    expect(both.contains(SaleFlagKind.payment), isTrue);
    expect(both.contains(SaleFlagKind.production), isTrue);
    expect(cleared.contains(SaleFlagKind.payment), isFalse);
    expect(cleared.contains(SaleFlagKind.production), isTrue);
    expect(cleared.toParams(), {'FlagMask': 2});
  });

  test('SaleFlags reads legacy codes and masks', () {
    expect(
      SaleFlags.fromJson({'Flag': 1}).contains(SaleFlagKind.payment),
      isTrue,
    );
    expect(
      SaleFlags.fromJson({'Flag': 2}).contains(SaleFlagKind.production),
      isTrue,
    );
    expect(
      SaleFlags.fromJson({'Flag': 3}).contains(SaleFlagKind.followUp),
      isTrue,
    );
    expect(SaleFlags.fromJson({'Flag': 0}).any, isFalse);
    expect(SaleFlags.fromJson({}).any, isFalse);
    expect(SaleFlags.fromJson({'Flag': 'x'}).any, isFalse);
    expect(SaleFlags.fromJson({'Flag': 5}).any, isFalse);

    final both = SaleFlags.fromJson({'Flag': 131});
    expect(both.contains(SaleFlagKind.payment), isTrue);
    expect(both.contains(SaleFlagKind.production), isTrue);
    expect(both.contains(SaleFlagKind.followUp), isFalse);
    expect(SaleFlags.fromJson({'Flag': 135}).toParams(), {'FlagMask': 135});
  });

  test('unknown bits survive a rewrite and block legacy codes', () {
    final paymentAndUnknown = SaleFlags.fromJson({'Flag': 137});
    expect(paymentAndUnknown.contains(SaleFlagKind.payment), isTrue);
    expect(paymentAndUnknown.toParams(), {'FlagMask': 137});
    expect(
      paymentAndUnknown.toggle(SaleFlagKind.payment).toParams(),
      {'FlagMask': 136},
    );
    expect(
      paymentAndUnknown.toggle(SaleFlagKind.production).toParams(),
      {'FlagMask': 139},
    );

    final followAndUnknown = SaleFlags.fromJson({'Flag': 140});
    expect(followAndUnknown.contains(SaleFlagKind.followUp), isTrue);
    expect(followAndUnknown.toParams(), {'FlagMask': 140});
  });

  test('SaleSummary and SaleDetail read the same flag column', () {
    final summary = SaleSummary.fromJson({
      'SaleId': 4,
      'StaffEmail': 'staff@example.com',
      'Flag': 131,
    });
    final detail = SaleDetail.fromJson({
      'SaleId': 4,
      'StaffEmail': 'staff@example.com',
      'Flag': 3,
      'Lines': [],
    });

    expect(summary.flags.contains(SaleFlagKind.payment), isTrue);
    expect(summary.flags.contains(SaleFlagKind.production), isTrue);
    expect(detail.flags.contains(SaleFlagKind.followUp), isTrue);
    expect(detail.flags.any, isTrue);
  });

  test('sale list sends FlagMask for any selected flag', () {
    expect(saleListFlagParams(), isEmpty);
    expect(saleListFlagParams(onlyFlagged: true), {'FlagAny': 1});
    expect(
      saleListFlagParams(flags: {SaleFlagKind.payment}),
      {'FlagMask': 1},
    );
    expect(
      saleListFlagParams(flags: {SaleFlagKind.production}),
      {'FlagMask': 2},
    );
    expect(
      saleListFlagParams(flags: {SaleFlagKind.followUp}),
      {'FlagMask': 4},
    );
    expect(
      saleListFlagParams(
        flags: {SaleFlagKind.payment, SaleFlagKind.production},
      ),
      {'FlagMask': 3},
    );
    expect(
      saleListFlagParams(
        flags: {
          SaleFlagKind.payment,
          SaleFlagKind.production,
          SaleFlagKind.followUp,
        },
      ),
      {'FlagMask': 7},
    );
  });
}
