class TaxConstants {
  // Pakistani tax rates
  static const Map<String, double> TAX_RATES = {
    'GST': 18.0, // General Sales Tax
    'ST': 16.0, // Sales Tax (older rate)
    'VAT': 17.0, // Value Added Tax (some provinces)
    'WHT': 1.0, // Withholding Tax (for some items)
  };

  // Common Pakistani retail chains and their typical tax handling
  static const Map<String, String> MERCHANT_PATTERNS = {
    'METRO': 'GST',
    'CARREFOUR': 'GST',
    'IMTIAZ': 'GST',
    'CHASE': 'GST',
    'HYPERSTAR': 'GST',
    'AL-FATAH': 'GST',
    'MAKRO': 'GST',
    'NAHEED': 'GST',
    'GREEN VALLEY': 'GST',
    'AGHA': 'GST',
  };

  // Tax tolerance for validation
  static const double TAX_TOLERANCE = 0.5;
  static const double AMOUNT_TOLERANCE = 1.0; // Rs. 1 tolerance for rounding
}

class RegexPatterns {
  static final RegExp datePattern =
      RegExp(r'\b(\d{1,2}[/-]\d{1,2}[/-]\d{2,4}|\d{1,2}\s+\w+\s+\d{4})\b');

  // More flexible number extraction patterns
  static final RegExp numberPattern = RegExp(r'(\d+[,.]?\d*\.?\d*)');

  // Enhanced patterns for Pakistani receipts
  static final List<RegExp> subtotalPatterns = [
    RegExp(
        r'(?:SUBTOTAL|SUB[\s-]*TOTAL|NET[\s-]*AMOUNT|SUB[\s-]*AMT)[\s:]*(?:RS\.?|PKR)?\s*(\d+[,.]?\d*\.?\d*)',
        caseSensitive: false),
    RegExp(r'(?:SUBTOTAL|SUB[\s-]*TOTAL)[\s:]*(\d+[,.]?\d*\.?\d*)',
        caseSensitive: false),
    RegExp(r'(\d+[,.]?\d*\.?\d*)[\s]*(?:SUBTOTAL|SUB[\s-]*TOTAL)',
        caseSensitive: false),
  ];

  static final List<RegExp> taxPatterns = [
    RegExp(
        r'(?:GST|SALES[\s-]*TAX|S\.?TAX|TAX|VAT)[\s:]*(?:RS\.?|PKR)?\s*(\d+[,.]?\d*\.?\d*)',
        caseSensitive: false),
    RegExp(r'(?:GST|TAX)[\s@]*\d+%[\s:]*(?:RS\.?|PKR)?\s*(\d+[,.]?\d*\.?\d*)',
        caseSensitive: false),
    RegExp(r'(\d+[,.]?\d*\.?\d*)[\s]*(?:GST|SALES[\s-]*TAX|TAX|VAT)',
        caseSensitive: false),
    RegExp(r'(?:GST|TAX)[\s]*(\d+[,.]?\d*\.?\d*)', caseSensitive: false),
  ];

  static final List<RegExp> totalPatterns = [
    RegExp(
        r'(?:TOTAL|GRAND[\s-]*TOTAL|FINAL[\s-]*TOTAL|NET[\s-]*TOTAL|AMOUNT[\s-]*PAYABLE)[\s:]*(?:RS\.?|PKR)?\s*(\d+[,.]?\d*\.?\d*)',
        caseSensitive: false),
    RegExp(r'(?:TOTAL|AMOUNT)[\s:]*(\d+[,.]?\d*\.?\d*)', caseSensitive: false),
    RegExp(r'(\d+[,.]?\d*\.?\d*)[\s]*(?:TOTAL|GRAND[\s-]*TOTAL)',
        caseSensitive: false),
  ];

  static final List<RegExp> ratePatterns = [
    RegExp(r'(?:GST|TAX|VAT)[\s@]*(\d+\.?\d*)%', caseSensitive: false),
    RegExp(r'(\d+\.?\d*)%[\s]*(?:GST|TAX|VAT)', caseSensitive: false),
    RegExp(r'@[\s]*(\d+\.?\d*)%', caseSensitive: false),
  ];

  // Complete the item pattern for line items
  static final RegExp itemPattern = RegExp(
      r'^([A-Za-z\s]+)\s+(\d+\.?\d*)\s*@?\s*(\d+\.?\d*)\s*=?\s*(\d+\.?\d*)$');

  // Merchant identification patterns
  static final List<RegExp> merchantPatterns = [
    RegExp(
        r'(METRO|CARREFOUR|IMTIAZ|CHASE|HYPERSTAR|AL-FATAH|MAKRO|NAHEED|GREEN VALLEY|AGHA)',
        caseSensitive: false),
    RegExp(r'([A-Z\s]+)(?:\s+STORE|\s+MART|\s+SUPERMARKET)',
        caseSensitive: false),
  ];

  // Currency patterns for Pakistani receipts
  static final RegExp currencyPattern =
      RegExp(r'(?:RS\.?|PKR)\s*(\d+[,.]?\d*\.?\d*)', caseSensitive: false);

  // Discount patterns
  static final List<RegExp> discountPatterns = [
    RegExp(
        r'(?:DISCOUNT|DISC|SAVING)[\s:]*(?:RS\.?|PKR)?\s*(\d+[,.]?\d*\.?\d*)',
        caseSensitive: false),
    RegExp(r'(\d+[,.]?\d*\.?\d*)[\s]*(?:DISCOUNT|DISC|OFF)',
        caseSensitive: false),
  ];
}
