import 'package:flutter/material.dart';

import '../../../core/models/json_field.dart';

/// Bir satışta tek bayrak vardır. Rengi anlamı taşır.
enum SaleFlagKind { payment, production, followUp }

class SaleFlagStyle {
  const SaleFlagStyle({required this.kind, required this.color, required this.code});

  final SaleFlagKind kind;
  final Color color;

  /// `Sales.Flag` değeri. 0 bayrak yok demektir.
  final int code;

  static const payment = SaleFlagStyle(
    kind: SaleFlagKind.payment,
    color: Color(0xFFD32F2F),
    code: 1,
  );

  static const production = SaleFlagStyle(
    kind: SaleFlagKind.production,
    color: Color(0xFF1565C0),
    code: 2,
  );

  static const followUp = SaleFlagStyle(
    kind: SaleFlagKind.followUp,
    color: Color(0xFFEF6C00),
    code: 3,
  );

  static const values = [payment, production, followUp];

  static SaleFlagStyle of(SaleFlagKind kind) => switch (kind) {
        SaleFlagKind.payment => payment,
        SaleFlagKind.production => production,
        SaleFlagKind.followUp => followUp,
      };

  static SaleFlagKind? kindForCode(int? code) => switch (code) {
        1 => SaleFlagKind.payment,
        2 => SaleFlagKind.production,
        3 => SaleFlagKind.followUp,
        _ => null,
      };
}

class SaleFlags {
  const SaleFlags({this.kind});

  final SaleFlagKind? kind;

  bool get any => kind != null;

  /// Aynı renge tekrar basınca bayrak kalkar.
  SaleFlags select(SaleFlagKind next) =>
      kind == next ? const SaleFlags() : SaleFlags(kind: next);

  Map<String, dynamic> toParams() => {
        'Flag': kind == null ? 0 : SaleFlagStyle.of(kind!).code,
      };

  factory SaleFlags.fromJson(Map<String, dynamic> json) {
    final value = json.field('Flag');
    int? code;
    if (value is num) code = value.toInt();
    if (value is String) code = int.tryParse(value.trim());
    return SaleFlags(kind: SaleFlagStyle.kindForCode(code));
  }

  @override
  bool operator ==(Object other) => other is SaleFlags && other.kind == kind;

  @override
  int get hashCode => kind.hashCode;
}

/// Seçili bayrak filtresinin `Sale.List` parametreleri.
/// Filtre yoksa boş döner; mevcut prosedür ek parametre almadan çalışmaya devam eder.
Map<String, dynamic> saleListFlagParams({
  SaleFlagKind? flag,
  bool onlyFlagged = false,
}) {
  if (flag != null) return {'Flag': SaleFlagStyle.of(flag).code};
  if (onlyFlagged) return const {'FlagAny': 1};
  return const {};
}
