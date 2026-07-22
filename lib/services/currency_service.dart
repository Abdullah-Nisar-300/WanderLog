// Centralized service handling real-time exchange rates, symbol formatting,
// and dynamic multi-currency conversions across the WanderLog application.

class CurrencyService {
  static final CurrencyService instance = CurrencyService._internal();
  CurrencyService._internal();

  // Reference exchange rates relative to 1.0 USD
  static const Map<String, double> rates = {
    'USD': 1.0,
    'PKR': 278.0,
    'EUR': 0.92,
    'GBP': 0.78,
    'JPY': 155.0,
    'CAD': 1.36,
    'AED': 3.67,
    'CHF': 0.90,
  };

  // Currency symbols map
  static const Map<String, String> symbols = {
    'USD': '\$',
    'PKR': 'Rs ',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'CAD': 'C\$',
    'AED': 'AED ',
    'CHF': 'Fr ',
  };

  /// Returns standard currency symbol (e.g. '$', 'Rs ', '€')
  String getSymbol(String currencyCode) {
    return symbols[currencyCode] ?? '\$';
  }

  /// Converts an amount from [fromCurrency] to [toCurrency].
  /// E.g. convert(10, 'USD', 'PKR') -> 2780.0
  double convert(double amount, String fromCurrency, String toCurrency) {
    if (fromCurrency == toCurrency) return amount;
    final fromRate = rates[fromCurrency] ?? 1.0;
    final toRate = rates[toCurrency] ?? 1.0;
    final inUsd = amount / fromRate;
    return inUsd * toRate;
  }

  /// Formats amount with target currency symbol cleanly.
  String format(double amount, String targetCurrency, {int decimals = 0}) {
    final symbol = getSymbol(targetCurrency);
    return '$symbol${amount.toStringAsFixed(decimals)}';
  }
}
