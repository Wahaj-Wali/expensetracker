import 'dart:math';
import '../models/receipts_data.dart';
import 'constants.dart';

class ReceiptParser {
  static ReceiptData parseReceiptText(String text) {
    final lines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    // Extract all data
    String merchantName = _extractMerchantName(lines);
    String date = _extractDate(lines);
    double subtotal = _extractSubtotal(lines);
    double taxAmount = _extractTaxAmount(lines);
    double taxRate = _calculateTaxRate(lines, subtotal, taxAmount);
    double total = _extractTotal(lines);
    double discount = _extractDiscount(lines);
    List<String> items = _extractItems(lines);

    // Determine tax type based on merchant or rate
    String taxType = _determineTaxType(merchantName, taxRate);

    return ReceiptData(
      merchantName: merchantName,
      date: date,
      subtotal: subtotal,
      taxAmount: taxAmount,
      taxRate: taxRate,
      total: total,
      items: items,
    );
  }

  static String _extractMerchantName(List<String> lines) {
    // First try using merchant patterns from constants
    for (int i = 0; i < min(5, lines.length); i++) {
      String line = lines[i];

      // Check against merchant patterns from RegexPatterns
      for (RegExp pattern in RegexPatterns.merchantPatterns) {
        Match? match = pattern.firstMatch(line);
        if (match != null) {
          String merchantName = match.group(1)?.trim().toUpperCase() ?? '';
          // Verify it's a known merchant
          if (TaxConstants.MERCHANT_PATTERNS.containsKey(merchantName)) {
            return merchantName;
          }
          return merchantName;
        }
      }
    }

    // Fallback: check for known merchants directly
    for (int i = 0; i < min(5, lines.length); i++) {
      String line = lines[i].toUpperCase();

      for (String merchant in TaxConstants.MERCHANT_PATTERNS.keys) {
        if (line.contains(merchant)) {
          return merchant;
        }
      }
    }

    return lines.isNotEmpty ? lines[0] : 'Unknown Merchant';
  }

  static String _extractDate(List<String> lines) {
    for (String line in lines) {
      Match? match = RegexPatterns.datePattern.firstMatch(line);
      if (match != null) {
        return match.group(1) ?? '';
      }
    }
    return 'Date not found';
  }

  static double _extractSubtotal(List<String> lines) {
    for (String line in lines) {
      // Try all subtotal patterns from constants
      for (RegExp pattern in RegexPatterns.subtotalPatterns) {
        Match? match = pattern.firstMatch(line);
        if (match != null) {
          return _parseAmount(match.group(1) ?? '0');
        }
      }
    }
    return 0.0;
  }

  static double _extractTaxAmount(List<String> lines) {
    for (String line in lines) {
      // Try all tax patterns from constants
      for (RegExp pattern in RegexPatterns.taxPatterns) {
        Match? match = pattern.firstMatch(line);
        if (match != null) {
          return _parseAmount(match.group(1) ?? '0');
        }
      }
    }
    return 0.0;
  }

  static double _extractTotal(List<String> lines) {
    // Search from bottom up for total using patterns from constants
    for (int i = lines.length - 1; i >= 0; i--) {
      for (RegExp pattern in RegexPatterns.totalPatterns) {
        Match? match = pattern.firstMatch(lines[i]);
        if (match != null) {
          return _parseAmount(match.group(1) ?? '0');
        }
      }
    }
    return 0.0;
  }

  static double _extractDiscount(List<String> lines) {
    for (String line in lines) {
      // Use discount patterns from constants
      for (RegExp pattern in RegexPatterns.discountPatterns) {
        Match? match = pattern.firstMatch(line);
        if (match != null) {
          return _parseAmount(match.group(1) ?? '0');
        }
      }
    }
    return 0.0;
  }

  static double _calculateTaxRate(
      List<String> lines, double subtotal, double taxAmount) {
    // First try to extract explicit tax rate using patterns from constants
    for (String line in lines) {
      for (RegExp pattern in RegexPatterns.ratePatterns) {
        Match? match = pattern.firstMatch(line);
        if (match != null) {
          return double.tryParse(match.group(1) ?? '0') ?? 0.0;
        }
      }
    }

    // If no explicit rate found, calculate from amounts
    if (subtotal > 0 && taxAmount > 0) {
      return (taxAmount / subtotal) * 100;
    }

    return 0.0;
  }

  static List<String> _extractItems(List<String> lines) {
    List<String> items = [];

    for (String line in lines) {
      // Skip lines that contain summary keywords
      String upperLine = line.toUpperCase();
      if (_isSummaryLine(upperLine)) {
        continue;
      }

      // Check if line matches item pattern from constants or looks like an item
      if (RegexPatterns.itemPattern.hasMatch(line) ||
          _looksLikeItemLine(line)) {
        items.add(line);
      }
    }

    return items;
  }

  static bool _isSummaryLine(String upperLine) {
    // Check against common summary line keywords
    List<String> summaryKeywords = [
      'TOTAL',
      'SUBTOTAL',
      'TAX',
      'GST',
      'VAT',
      'DISCOUNT',
      'AMOUNT',
      'PAYABLE',
      'DATE',
      'TIME',
      'CASHIER',
      'THANK',
      'VISIT',
      'CHANGE',
      'CASH',
      'CARD',
      'RECEIPT'
    ];

    for (String keyword in summaryKeywords) {
      if (upperLine.contains(keyword)) {
        return true;
      }
    }

    return false;
  }

  static bool _looksLikeItemLine(String line) {
    // Use number pattern from constants to identify potential item lines
    if (!RegexPatterns.numberPattern.hasMatch(line)) {
      return false;
    }

    // Check for price-like patterns
    List<RegExp> pricePatterns = [
      RegExp(r'\d+\.\d{2}$'), // Ends with price format
      RegExp(r'\d+\s*@\s*\d+'), // Contains @ symbol (quantity @ price)
      RegExp(r'\d+\s*x\s*\d+'), // Contains x symbol (quantity x price)
      RegExp(r'=\s*\d+\.\d{2}'), // Contains = symbol (= total price)
      RegExp(r'\d+\s+\d+\.\d{2}'), // Number followed by price
    ];

    for (RegExp pattern in pricePatterns) {
      if (pattern.hasMatch(line)) {
        return true;
      }
    }

    return false;
  }

  static double _parseAmount(String text) {
    // Use currency pattern from constants if available
    Match? currencyMatch = RegexPatterns.currencyPattern.firstMatch(text);
    if (currencyMatch != null) {
      return _cleanAndParseAmount(currencyMatch.group(1) ?? '0');
    }

    // Fallback to number pattern from constants
    Match? numberMatch = RegexPatterns.numberPattern.firstMatch(text);
    if (numberMatch != null) {
      return _cleanAndParseAmount(numberMatch.group(1) ?? '0');
    }

    return _cleanAndParseAmount(text);
  }

  static double _cleanAndParseAmount(String text) {
    // Remove currency symbols and clean up the string
    String cleaned =
        text.replaceAll(RegExp(r'[^\d.,]'), '').replaceAll(',', '');

    try {
      return double.parse(cleaned);
    } catch (e) {
      return 0.0;
    }
  }

  static String _determineTaxType(String merchantName, double taxRate) {
    // Check merchant-specific tax type from constants
    String upperMerchant = merchantName.toUpperCase();
    if (TaxConstants.MERCHANT_PATTERNS.containsKey(upperMerchant)) {
      return TaxConstants.MERCHANT_PATTERNS[upperMerchant]!;
    }

    // Determine based on tax rate using constants
    if (taxRate > 0) {
      double minDiff = double.infinity;
      String closestTaxType = 'GST';

      TaxConstants.TAX_RATES.forEach((type, rate) {
        double diff = (taxRate - rate).abs();
        if (diff < minDiff) {
          minDiff = diff;
          closestTaxType = type;
        }
      });

      // Only return if the difference is within tolerance from constants
      if (minDiff <= TaxConstants.TAX_TOLERANCE) {
        return closestTaxType;
      }
    }

    return 'GST'; // Default to GST for Pakistani receipts
  }

  static bool _validateReceipt(
      double subtotal, double taxAmount, double total, double discount) {
    // Use amount tolerance from constants for validation
    if (subtotal > 0 && total > 0) {
      double expectedTotal = subtotal + taxAmount - discount;
      return (total - expectedTotal).abs() <= TaxConstants.AMOUNT_TOLERANCE;
    }

    // If we only have total, consider it valid
    return total > 0;
  }

  // Method to validate tax rate against Pakistani standards
  static bool _isValidTaxRate(double taxRate) {
    return TaxConstants.TAX_RATES.values
        .any((rate) => (taxRate - rate).abs() <= TaxConstants.TAX_TOLERANCE);
  }

  // Enhanced method to extract currency amounts specifically
  static double _extractCurrencyAmount(String line) {
    Match? match = RegexPatterns.currencyPattern.firstMatch(line);
    if (match != null) {
      return _parseAmount(match.group(1) ?? '0');
    }
    return 0.0;
  }

  // Utility method to check if merchant is known
  static bool _isKnownMerchant(String merchantName) {
    return TaxConstants.MERCHANT_PATTERNS
        .containsKey(merchantName.toUpperCase());
  }

  // Method to get expected tax type for a merchant
  static String? _getExpectedTaxType(String merchantName) {
    return TaxConstants.MERCHANT_PATTERNS[merchantName.toUpperCase()];
  }

  // Method to validate tax calculation
  static bool _validateTaxCalculation(
      double subtotal, double taxAmount, double taxRate) {
    if (subtotal <= 0 || taxAmount <= 0 || taxRate <= 0) {
      return false;
    }

    double expectedTax = subtotal * (taxRate / 100);
    return (taxAmount - expectedTax).abs() <= TaxConstants.TAX_TOLERANCE;
  }
}
