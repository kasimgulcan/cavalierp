import 'package:flutter_riverpod/flutter_riverpod.dart';

/// TL — ERP Currencies tablosunda genelde CurrencyId = 1
const kDefaultCurrencyId = 1;

final selectedCurrencyIdProvider = StateProvider<int>((ref) => kDefaultCurrencyId);

int effectiveCurrencyId(int? id) => id ?? kDefaultCurrencyId;
