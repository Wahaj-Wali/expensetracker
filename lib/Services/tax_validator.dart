import '../models/receipts_data.dart';
import '../models/tax_validation_result.dart';
import '../utils/constants.dart';

class TaxValidator {
  static TaxValidationResult validateTax(ReceiptData receiptData) {
    double expectedRate = _getExpectedTaxRate(receiptData.merchantName);
    double foundRate = receiptData.taxRate;

    // If tax rate not found in text, calculate from amounts
    if (foundRate == 0.0 &&
        receiptData.subtotal > 0 &&
        receiptData.taxAmount > 0) {
      foundRate = (receiptData.taxAmount / receiptData.subtotal) * 100;
    }

    bool isValid =
        (foundRate - expectedRate).abs() <= TaxConstants.TAX_TOLERANCE;

    String message =
        _generateValidationMessage(expectedRate, foundRate, isValid);

    // Additional validation for tax calculation accuracy
    if (receiptData.subtotal > 0 && foundRate > 0) {
      double calculatedTax = receiptData.subtotal * (foundRate / 100);
      double taxDifference = (calculatedTax - receiptData.taxAmount).abs();

      if (taxDifference > TaxConstants.AMOUNT_TOLERANCE) {
        isValid = false;
        message += ' Tax calculation may be incorrect.';
      }
    }

    return TaxValidationResult(
      isValid: isValid,
      expectedTaxRate: expectedRate,
      foundTaxRate: foundRate,
      message: message,
      taxType: _getTaxType(receiptData.merchantName),
    );
  }

  static double _getExpectedTaxRate(String merchantName) {
    String upperMerchant = merchantName.toUpperCase();

    for (String merchant in TaxConstants.MERCHANT_PATTERNS.keys) {
      if (upperMerchant.contains(merchant)) {
        String taxType = TaxConstants.MERCHANT_PATTERNS[merchant]!;
        return TaxConstants.TAX_RATES[taxType] ?? 18.0;
      }
    }

    return TaxConstants.TAX_RATES['GST']!;
  }

  static String _getTaxType(String merchantName) {
    String upperMerchant = merchantName.toUpperCase();

    for (String merchant in TaxConstants.MERCHANT_PATTERNS.keys) {
      if (upperMerchant.contains(merchant)) {
        return TaxConstants.MERCHANT_PATTERNS[merchant]!;
      }
    }

    return 'GST';
  }

  static String _generateValidationMessage(
      double expectedRate, double foundRate, bool isValid) {
    if (!isValid) {
      if (foundRate > expectedRate + TaxConstants.TAX_TOLERANCE) {
        return 'Tax rate appears higher than expected Pakistani rate of ${expectedRate}%';
      } else if (foundRate < expectedRate - TaxConstants.TAX_TOLERANCE) {
        return 'Tax rate appears lower than expected Pakistani rate of ${expectedRate}%';
      }
    }

    return 'Tax rate matches expected Pakistani GST/Sales Tax rate';
  }
}
