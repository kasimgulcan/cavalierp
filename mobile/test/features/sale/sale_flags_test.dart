import 'package:cavalierp/features/sale/models/sale.dart';
import 'package:cavalierp/features/sale/models/sale_flags.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a sale keeps a single flag color', () {
    const flags = SaleFlags(kind: SaleFlagKind.payment);

    expect(flags.select(SaleFlagKind.production).kind, SaleFlagKind.production);
    expect(flags.select(SaleFlagKind.payment).kind, isNull);
    expect(flags.toParams(), {'Flag': 1});
  });

  test('SaleFlags reads the Flag column', () {
    expect(SaleFlags.fromJson({'Flag': 2}).kind, SaleFlagKind.production);
    expect(SaleFlags.fromJson({'Flag': 0}).kind, isNull);
    expect(SaleFlags.fromJson({}).kind, isNull);
  });

  test('SaleSummary and SaleDetail carry one flag', () {
    final summary = SaleSummary.fromJson({
      'SaleId': 4,
      'StaffEmail': 'staff@example.com',
      'Flag': 1,
    });
    final detail = SaleDetail.fromJson({
      'SaleId': 4,
      'StaffEmail': 'staff@example.com',
      'Flag': 3,
      'Lines': [],
    });

    expect(summary.flags.kind, SaleFlagKind.payment);
    expect(detail.flags.kind, SaleFlagKind.followUp);
  });

  test('sale list sends a flag filter only when one is selected', () {
    expect(saleListFlagParams(), isEmpty);
    expect(saleListFlagParams(flag: SaleFlagKind.payment), {'Flag': 1});
    expect(saleListFlagParams(flag: SaleFlagKind.production), {'Flag': 2});
    expect(saleListFlagParams(flag: SaleFlagKind.followUp), {'Flag': 3});
    expect(saleListFlagParams(onlyFlagged: true), {'FlagAny': 1});
  });
}
