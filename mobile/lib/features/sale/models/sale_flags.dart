import 'package:flutter/material.dart';

import '../../../core/models/json_field.dart';

/// Sabit satış bayrakları. Personel yeni bayrak oluşturmaz.
enum SaleFlagKind { payment, production, followUp }

class SaleFlagStyle {
  const SaleFlagStyle({
    required this.kind,
    required this.color,
    required this.legacyCode,
    required this.bit,
    required this.label,
  });

  final SaleFlagKind kind;
  final Color color;

  /// Eski sürümün tek bayrak kodu: 1, 2 veya 3.
  final int legacyCode;

  /// Çoklu kayıttaki anlam biti. Genel takip 4'tür, 3 değil.
  final int bit;
  final String label;

  /// `128 + bit` çoklu kayıt demektir.
  static const modeBit = 128;

  /// Bu sürümün etiketlemediği, silinmeden taşınan bitler.
  static const unknownBitMask = 8 | 16 | 32 | 64;

  static const payment = SaleFlagStyle(
    kind: SaleFlagKind.payment,
    color: Color(0xFFD32F2F),
    legacyCode: 1,
    bit: 1,
    label: 'Ödeme takip',
  );

  static const production = SaleFlagStyle(
    kind: SaleFlagKind.production,
    color: Color(0xFF1565C0),
    legacyCode: 2,
    bit: 2,
    label: 'Üretim',
  );

  static const followUp = SaleFlagStyle(
    kind: SaleFlagKind.followUp,
    color: Color(0xFFEF6C00),
    legacyCode: 3,
    bit: 4,
    label: 'Genel takip',
  );

  static const values = [payment, production, followUp];

  static SaleFlagStyle of(SaleFlagKind kind) => switch (kind) {
        SaleFlagKind.payment => payment,
        SaleFlagKind.production => production,
        SaleFlagKind.followUp => followUp,
      };
}

class SaleFlags {
  const SaleFlags({this.kinds = const {}, this.unknownBits = 0});

  final Set<SaleFlagKind> kinds;

  /// Yalnız `8`, `16`, `32`, `64`.
  final int unknownBits;

  bool get any => kinds.isNotEmpty;

  bool contains(SaleFlagKind kind) => kinds.contains(kind);

  SaleFlags toggle(SaleFlagKind kind) {
    final next = Set<SaleFlagKind>.of(kinds);
    if (!next.add(kind)) next.remove(kind);
    return SaleFlags(kinds: next, unknownBits: unknownBits);
  }

  int get storedValue {
    final knownBits = kinds.fold<int>(0, (mask, kind) => mask | SaleFlagStyle.of(kind).bit);
    final unknown = unknownBits & SaleFlagStyle.unknownBitMask;
    if (unknown == 0 && kinds.isEmpty) return 0;
    if (unknown == 0 && kinds.length == 1) {
      return SaleFlagStyle.of(kinds.single).legacyCode;
    }
    return SaleFlagStyle.modeBit | knownBits | unknown;
  }

  Map<String, dynamic> toParams() => {'FlagMask': storedValue};

  factory SaleFlags.fromJson(Map<String, dynamic> json) {
    final value = json.field('Flag');
    int? code;
    if (value is num) code = value.toInt();
    if (value is String) code = int.tryParse(value.trim());
    return SaleFlags.decode(code);
  }

  factory SaleFlags.decode(int? code) {
    if (code == null || code <= 0 || (code < SaleFlagStyle.modeBit && code > 3)) {
      return const SaleFlags();
    }
    if (code == 1) return const SaleFlags(kinds: {SaleFlagKind.payment});
    if (code == 2) return const SaleFlags(kinds: {SaleFlagKind.production});
    if (code == 3) return const SaleFlags(kinds: {SaleFlagKind.followUp});

    final kinds = <SaleFlagKind>{};
    if ((code & 1) != 0) kinds.add(SaleFlagKind.payment);
    if ((code & 2) != 0) kinds.add(SaleFlagKind.production);
    if ((code & 4) != 0) kinds.add(SaleFlagKind.followUp);
    return SaleFlags(
      kinds: kinds,
      unknownBits: code & SaleFlagStyle.unknownBitMask,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SaleFlags &&
      other.unknownBits == unknownBits &&
      other.kinds.length == kinds.length &&
      other.kinds.containsAll(kinds);

  @override
  int get hashCode => Object.hash(Object.hashAllUnordered(kinds), unknownBits);
}

/// Seçili bayrak filtresinin `Sale.List` parametreleri.
/// Filtre yoksa boş döner. Yeni sürüm `Flag` göndermez.
Map<String, dynamic> saleListFlagParams({
  Set<SaleFlagKind> flags = const {},
  bool onlyFlagged = false,
}) {
  if (flags.isNotEmpty) {
    final mask = flags.fold<int>(0, (value, kind) => value | SaleFlagStyle.of(kind).bit);
    return {'FlagMask': mask};
  }
  if (onlyFlagged) return const {'FlagAny': 1};
  return const {};
}
