import 'currency_selection.dart';

/// Görüntülenebilir para birimi sembolü.
String currencySymbol(String? code, {int? currencyId}) {
  final normalized = code?.trim();
  if (normalized != null && normalized.isNotEmpty) {
    switch (normalized.toUpperCase()) {
      case 'TRY':
      case 'TL':
      case 'TRL':
      case 'YTL':
        return '₺';
      case 'EUR':
      case 'EURO':
        return '€';
      case 'USD':
        return '\$';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      case 'CHF':
        return 'CHF';
      default:
        return normalized.toUpperCase();
    }
  }

  if (currencyId == kDefaultCurrencyId) return '₺';
  return '₺';
}

String currencySymbolFrom(Map<String, dynamic>? currency) {
  if (currency == null) return '₺';
  return currencySymbol(
    currency['Code']?.toString() ?? currency['code']?.toString(),
    currencyId: currency['CurrencyId'] is num
        ? (currency['CurrencyId'] as num).toInt()
        : int.tryParse(currency['CurrencyId']?.toString() ?? ''),
  );
}
