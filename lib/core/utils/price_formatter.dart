// lib/core/utils/price_formatter.dart

import 'package:intl/intl.dart';

class PriceFormatter {
  static final _currencyFormatter = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );
  
  static final _compactCurrencyFormatter = NumberFormat.compactCurrency(
    symbol: '\$',
    decimalDigits: 2,
  );
  
  static final _percentFormatter = NumberFormat.decimalPercentPattern(
    decimalDigits: 2,
  );

  static final _numberFormatter = NumberFormat('#,##0.00', 'en_US');
  static final _cryptoNumberFormatter = NumberFormat('#,##0.00000000', 'en_US');

  static String formatPrice(double price) {
    if (price >= 1000) {
      return _currencyFormatter.format(price);
    } else if (price >= 1) {
      return '\$${price.toStringAsFixed(2)}';
    } else if (price >= 0.01) {
      return '\$${price.toStringAsFixed(4)}';
    } else {
      return '\$${price.toStringAsFixed(8)}';
    }
  }

  static String formatCompactPrice(double price) {
    return _compactCurrencyFormatter.format(price);
  }

  static String formatPercentage(double percentage) {
    final formatted = percentage.toStringAsFixed(2);
    return '${percentage >= 0 ? '+' : ''}$formatted%';
  }

  static String formatHoldings(double holdings) {
    if (holdings >= 1000000000000) {
      // Trillions
      return '${(holdings / 1000000000000).toStringAsFixed(2)}T';
    } else if (holdings >= 1000000000) {
      // Billions
      return '${(holdings / 1000000000).toStringAsFixed(2)}B';
    } else if (holdings >= 1000000) {
      // Millions
      return '${(holdings / 1000000).toStringAsFixed(2)}M';
    } else if (holdings >= 1) {
      return _numberFormatter.format(holdings);
    } else {
      // For fractional holdings, show up to 8 decimal places but remove trailing zeros
      String formatted = _cryptoNumberFormatter.format(holdings);
      formatted = formatted.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
      return formatted;
    }
  }
}