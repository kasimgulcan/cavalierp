# Satış bayrakları — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Satışta ve liste filtresinde birden fazla bayrak seçilsin; her bayrağın adı görünsün; kayıt `FlagMask` ile gitsin ve eski `1` / `2` / `3` kodları bozulmasın.

**Architecture:** Kodlama `SaleFlags` içinde kalır. Tek bayrak ve tanınmayan biti olmayan kayıt `0`–`3` yazılır. Birden fazla bayrak veya tanınmayan bit `128 + bit` yazılır. Uygulama yalnız `FlagMask` gönderir. Seçici, liste kartı, özet ve filtre bu modeli okur. `sql/Migrate_SaleFlagMask.sql` canlıda uygulanmıştır; bu planda SQL yoktur.

**Tech Stack:** Flutter, Dart, flutter_test. Çalışma dizini `mobile/`.

## Global Constraints

- Etiketler birebir: `Ödeme takip`, `Üretim`, `Genel takip`. Sıra: ödeme, üretim, genel takip.
- Renkler durur: ödeme `0xFFD32F2F`, üretim `0xFF1565C0`, genel takip `0xFFEF6C00`.
- Yazma parametresi yalnız `FlagMask`. `Flag` gönderilmez.
- Tanınmayan bit yok ve bayrak yok: `0`. Tanınmayan bit yok ve tek bayrak: ödeme `1`, üretim `2`, genel takip `3`.
- Birden fazla bayrak, ya da bit `8` / `16` / `32` / `64` duruyorsa: `128 + bitler`. Ödeme biti `1`, üretim biti `2`, genel takip biti `4`. Ödeme + üretim = `131`. Üçü birden = `135`.
- `4`–`127` okununca bayraksız sayılır.
- Liste: filtre yoksa parametre yok. İşaretli: `FlagAny = 1`. Seçilen bayraklar `FlagMask` (genel takip biti `4`, `128` eklenmez). `FlagMask = 3` ödeme veya üretimdir.
- Bir renk seçilince İşaretli kapanır. İşaretli seçilince renkler kapanır. Tümü ikisini de kapatır.
- Satış detayındaki kayıt hatası aynı kalır: seçici kilitlenir, reddedilirse “İşaret kaydedilemedi”. `_setFlags` değişmez.
- Ödeme ve satış detayı seçiciyi kullanmaya devam eder; bu iki dosyaya davranış eklenmez.
- Ayrı ekran testi yok. Test dosyası yalnız `mobile/test/features/sale/sale_flags_test.dart`.
- Personelin kendi bayrağını eklemesi yok. SQL scripti tekrar çalıştırılmaz.

## File map

| File | Responsibility |
|---|---|
| `mobile/lib/features/sale/models/sale_flags.dart` | Bit kodu, etiket, `FlagMask` yazma, liste parametresi |
| `mobile/test/features/sale/sale_flags_test.dart` | Kodlama, okuma, filtre, toggle |
| `mobile/lib/features/sale/widgets/sale_flag_picker.dart` | Etiketli çoklu seçim ve kart/özet işaretleri |
| `mobile/lib/features/sale/widgets/sale_list_card.dart` | İşaretleri adın altında satır kaydırarak gösterir |
| `mobile/lib/features/sale/widgets/sale_list_filter_bar.dart` | Çoklu etiketli filtre çipleri |
| `mobile/lib/features/sale/sale_provider.dart` | `SaleListFilter.flags` ve `Sale.List` parametresi |
| `mobile/lib/features/sale/sales_list_screen.dart` | Tümü / İşaretli / çoklu çip durumu |
| `mobile/lib/features/sale/sale_summary_screen.dart` | Özet işaretleri |

Dokunulmaz: `checkout_screen.dart`, `sale_detail_screen.dart`, `cart_provider.dart`, `sql/Migrate_SaleFlagMask.sql`.

---

### Task 1: Flag mask model

**Files:**
- Modify: `mobile/lib/features/sale/models/sale_flags.dart`
- Test: `mobile/test/features/sale/sale_flags_test.dart`

**Interfaces:**
- Consumes: `json.field('Flag')` (`mobile/lib/core/models/json_field.dart`)
- Produces:
  - `enum SaleFlagKind { payment, production, followUp }`
  - `SaleFlagStyle.payment`, `.production`, `.followUp`, `.values`, `.of(SaleFlagKind)`, `.label`, `.color`, `.bit`, `.legacyCode`
  - `SaleFlagStyle.modeBit = 128`, `SaleFlagStyle.unknownBitMask = 120` (`8|16|32|64`)
  - `SaleFlags({Set<SaleFlagKind> kinds = const {}, int unknownBits = 0})`
  - `bool get any`, `bool contains(SaleFlagKind kind)`, `SaleFlags toggle(SaleFlagKind kind)`
  - `Map<String, dynamic> toParams()` → `{'FlagMask': int}`
  - `factory SaleFlags.fromJson(Map<String, dynamic> json)`
  - `saleListFlagParams({Set<SaleFlagKind> flags = const {}, bool onlyFlagged = false})`

Eski `kind`, `select` ve `code` kalkar. Bu görevden sonra seçici, filtre ve özet derlenmez. Yalnız bu test dosyası çalıştırılır.

- [ ] **Step 1: Write the failing test**

`mobile/test/features/sale/sale_flags_test.dart` dosyasının tamamını şununla değiştir:

```dart
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
```

- [ ] **Step 2: Run test to verify it fails**

Run from `mobile/`:

```powershell
flutter test test/features/sale/sale_flags_test.dart
```

Expected: FAIL. `SaleFlags` henüz `kinds` / `toggle` / `FlagMask` sunmaz.

- [ ] **Step 3: Write minimal implementation**

`mobile/lib/features/sale/models/sale_flags.dart` dosyasının tamamını şununla değiştir:

```dart
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
```

`4`–`127` bayraksızdır. `128` ve üzeri bitlere ayrılır. Koşul parantezli kalsın: `(code < SaleFlagStyle.modeBit && code > 3)`.

- [ ] **Step 4: Run test to verify it passes**

Run from `mobile/`:

```powershell
flutter test test/features/sale/sale_flags_test.dart
```

Expected: PASS. All tests in `sale_flags_test.dart` pass.

- [ ] **Step 5: Commit**

```powershell
git add mobile/lib/features/sale/models/sale_flags.dart mobile/test/features/sale/sale_flags_test.dart
git commit -m "feat: encode sale flags as a compatible mask"
```

---

### Task 2: Labeled multi-select marks

**Files:**
- Modify: `mobile/lib/features/sale/widgets/sale_flag_picker.dart`
- Modify: `mobile/lib/features/sale/widgets/sale_list_card.dart:65-87`

**Interfaces:**
- Consumes: `SaleFlags.contains`, `SaleFlags.toggle`, `SaleFlags.any`, `SaleFlagStyle.values`, `.label`, `.color`, `.kind`
- Produces: `SaleFlagPicker` ve `SaleFlagMarks` aynı constructor imzalarıyla kalır: `flags` + `onChanged` / `flags`

`checkout_screen.dart` ve `sale_detail_screen.dart` değiştirilmez. Seçici yeni `toggle` kullandığı için onlar derlenir.

- [ ] **Step 1: Replace the picker and marks**

`mobile/lib/features/sale/widgets/sale_flag_picker.dart` dosyasının tamamını şununla değiştir:

```dart
import 'package:flutter/material.dart';

import '../models/sale_flags.dart';

class SaleFlagPicker extends StatelessWidget {
  const SaleFlagPicker({
    super.key,
    required this.flags,
    required this.onChanged,
    this.enabled = true,
  });

  final SaleFlags flags;
  final ValueChanged<SaleFlags> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final style in SaleFlagStyle.values)
          _FlagButton(
            style: style,
            selected: flags.contains(style.kind),
            enabled: enabled,
            onTap: () => onChanged(flags.toggle(style.kind)),
          ),
      ],
    );
  }
}

class SaleFlagMarks extends StatelessWidget {
  const SaleFlagMarks({super.key, required this.flags});

  final SaleFlags flags;

  @override
  Widget build(BuildContext context) {
    final selected = [
      for (final style in SaleFlagStyle.values)
        if (flags.contains(style.kind)) style,
    ];
    if (selected.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final style in selected)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.flag_rounded, size: 16, color: style.color),
              const SizedBox(width: 4),
              Text(
                style.label,
                style: TextStyle(
                  color: style.color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _FlagButton extends StatelessWidget {
  const _FlagButton({
    required this.style,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final SaleFlagStyle style;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: selected ? style.color.withValues(alpha: 0.16) : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: selected ? style.color : theme.colorScheme.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.flag_rounded, color: style.color, size: 20),
              const SizedBox(width: 6),
              Text(
                style.label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: style.color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Let list-card marks wrap under the name**

`sale_list_card.dart` içinde `if (_subtitle.isNotEmpty || sale.flags.any)` bloğunun tamamını şununla değiştir. `Wrap` bir `Row` içinde sınırsız genişlik alır; işaretler adın altında kendi satırında durur.

```dart
                    if (sale.flags.any) ...[
                      const SizedBox(height: 4),
                      SaleFlagMarks(flags: sale.flags),
                    ],
                    if (_subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        _subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.2,
                        ),
                      ),
                    ],
```

- [ ] **Step 3: Run the model test**

Run from `mobile/`:

```powershell
flutter test test/features/sale/sale_flags_test.dart
```

Expected: PASS. Bu görev yeni test eklemez. Seçici modeli bozmadıysa test geçer.

- [ ] **Step 4: Commit**

```powershell
git add mobile/lib/features/sale/widgets/sale_flag_picker.dart mobile/lib/features/sale/widgets/sale_list_card.dart
git commit -m "feat: show sale flag labels and allow several at once"
```

---

### Task 3: Multi-select list filter

**Files:**
- Modify: `mobile/lib/features/sale/sale_provider.dart:11-33` and the `saleListFlagParams` call near line 116
- Modify: `mobile/lib/features/sale/widgets/sale_list_filter_bar.dart`
- Modify: `mobile/lib/features/sale/sales_list_screen.dart`

**Interfaces:**
- Consumes: `saleListFlagParams({Set<SaleFlagKind> flags, bool onlyFlagged})`
- Produces:
  - `SaleListFilter.flags` (`Set<SaleFlagKind>`). `flag` kalkar.
  - `SaleListFilterBar` alanları: `selectedFlags`, `onlyFlagged`, `onSelectAll`, `onSelectFlagged`, `onToggleFlag`

- [ ] **Step 1: Carry a flag set on the list filter**

`SaleListFilter` içindeki `SaleFlagKind? flag` alanını `Set<SaleFlagKind> flags` yap. Constructor:

```dart
  const SaleListFilter({
    this.dateFrom,
    this.dateTo,
    this.flags = const {},
    this.onlyFlagged = false,
  });

  final DateTime? dateFrom;
  final DateTime? dateTo;
  final Set<SaleFlagKind> flags;
  final bool onlyFlagged;

  @override
  bool operator ==(Object other) =>
      other is SaleListFilter &&
      other.dateFrom == dateFrom &&
      other.dateTo == dateTo &&
      other.onlyFlagged == onlyFlagged &&
      other.flags.length == flags.length &&
      other.flags.containsAll(flags);

  @override
  int get hashCode => Object.hash(
        dateFrom,
        dateTo,
        onlyFlagged,
        Object.hashAllUnordered(flags),
      );
```

`_loadPage` içindeki çağrıyı şununla değiştir:

```dart
        ...saleListFlagParams(
          flags: _filter.flags,
          onlyFlagged: _filter.onlyFlagged,
        ),
```

- [ ] **Step 2: Replace the filter bar flag chips**

`SaleListFilterBar` alanlarını şöyle değiştir. Tarih satırı aynı kalır.

```dart
    this.selectedFlags = const {},
    this.onlyFlagged = false,
    this.onSelectAll,
    this.onSelectFlagged,
    this.onToggleFlag,
  });

  final String dateFromLabel;
  final String dateToLabel;
  final VoidCallback onPickDateFrom;
  final VoidCallback onPickDateTo;
  final Set<SaleFlagKind> selectedFlags;
  final bool onlyFlagged;
  final VoidCallback? onSelectAll;
  final VoidCallback? onSelectFlagged;
  final ValueChanged<SaleFlagKind>? onToggleFlag;
```

Bayrak `Wrap` çocukları:

```dart
                _FlagFilterChip(
                  label: 'Tümü',
                  selected: selectedFlags.isEmpty && !onlyFlagged,
                  onSelected: () => onSelectAll?.call(),
                ),
                _FlagFilterChip(
                  label: 'İşaretli',
                  selected: onlyFlagged && selectedFlags.isEmpty,
                  onSelected: () => onSelectFlagged?.call(),
                ),
                for (final style in SaleFlagStyle.values)
                  _FlagFilterChip(
                    label: style.label,
                    color: style.color,
                    selected: selectedFlags.contains(style.kind) && !onlyFlagged,
                    onSelected: () => onToggleFlag?.call(style.kind),
                  ),
```

`_FlagFilterChip` hem metin hem renk alır. Renk varsa ikon, metin her zaman durur. `label` artık zorunlu `String` olur. `color` null ise Tümü / İşaretli metin çipi kalır.

```dart
class _FlagFilterChip extends StatelessWidget {
  const _FlagFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = color ?? theme.colorScheme.primary;

    return FilterChip(
      avatar: color == null
          ? null
          : Icon(Icons.flag_rounded, size: 18, color: accent),
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
      selectedColor: accent.withValues(alpha: 0.16),
      side: BorderSide(color: selected ? accent : theme.colorScheme.outlineVariant),
      labelStyle: theme.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: selected ? accent : null,
      ),
      onSelected: (_) => onSelected(),
    );
  }
}
```

Eski `selectedFlag` ve `onSelectFlag` kalmaz.

- [ ] **Step 3: Toggle flags on the sales list**

`sales_list_screen.dart` durumu:

```dart
  Set<SaleFlagKind> _flags = {};
  bool _onlyFlagged = false;
```

`_buildFilter`:

```dart
        flags: _flags,
        onlyFlagged: _onlyFlagged,
```

`_selectAll` içinde `_flag = null` yerine `_flags = {}`.

`_selectFlag` metodunu şununla değiştir. Tarih aralığını temizleme bugünkü gibi kalır:

```dart
  void _toggleFlag(SaleFlagKind flag) {
    setState(() {
      final next = Set<SaleFlagKind>.of(_flags);
      if (!next.add(flag)) next.remove(flag);
      _flags = next;
      _onlyFlagged = false;
      _dateFrom = null;
      _dateTo = null;
    });
    _applyFilter();
  }
```

`_selectFlagged` içinde `_flag = null` yerine `_flags = {}`.

Filtre çubuğu çağrısı:

```dart
              selectedFlags: _flags,
              onlyFlagged: _onlyFlagged,
              onSelectAll: _selectAll,
              onSelectFlagged: _selectFlagged,
              onToggleFlag: _toggleFlag,
```

Boş liste metnindeki `_filter.flag != null` iki yerde de `_filter.flags.isNotEmpty` olur.

- [ ] **Step 4: Run the model test**

Run from `mobile/`:

```powershell
flutter test test/features/sale/sale_flags_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit**

```powershell
git add mobile/lib/features/sale/sale_provider.dart mobile/lib/features/sale/widgets/sale_list_filter_bar.dart mobile/lib/features/sale/sales_list_screen.dart
git commit -m "feat: filter sales by any of the selected flags"
```

---

### Task 4: Summary marks

**Files:**
- Modify: `mobile/lib/features/sale/sale_summary_screen.dart:122-129`

**Interfaces:**
- Consumes: `SaleFlags.any`, `SaleFlagMarks`
- Produces: satış özetinde seçili her bayrağın ikonu ve adı

- [ ] **Step 1: Replace the single summary icon**

`sale_summary_screen.dart` içindeki tek ikon bloğunu şununla değiştir. Dosya zaten `sale_flag_picker.dart` import etmiyorsa ekle:

```dart
import 'widgets/sale_flag_picker.dart';
```

```dart
                                if (flags.any) ...[
                                  const SizedBox(height: 18),
                                  SaleFlagMarks(flags: flags),
                                ],
```

`SaleFlagStyle.of(flags.kind!)` kalkar. `models/sale_flags.dart` importu kalır; özet `SaleFlags.fromJson(sale)` kullanır. `widgets/sale_flag_picker.dart` importu eklenir.

- [ ] **Step 2: Analyze the sale feature and rerun the flag tests**

Run from `mobile/`:

```powershell
flutter test test/features/sale/sale_flags_test.dart
flutter analyze lib/features/sale/models/sale_flags.dart lib/features/sale/widgets/sale_flag_picker.dart lib/features/sale/widgets/sale_list_card.dart lib/features/sale/widgets/sale_list_filter_bar.dart lib/features/sale/sale_provider.dart lib/features/sale/sales_list_screen.dart lib/features/sale/sale_summary_screen.dart lib/features/sale/checkout_screen.dart lib/features/sale/sale_detail_screen.dart
```

Expected: tests PASS. Analyze reports no errors in these files. `checkout_screen.dart` ve `sale_detail_screen.dart` seçiciyi yeni imzayla kullanır; `_setFlags` aynıdır.

- [ ] **Step 3: Commit**

```powershell
git add mobile/lib/features/sale/sale_summary_screen.dart
git commit -m "feat: show every sale flag label on the summary"
```
