class TaxValidator {
  bool validate({
    required double subtotal,
    required double extractedTax,
    double expectedPercent = 18.0,
    double tolerance = 5.0, // PKR tolerance
  }) {
    final expected = subtotal * expectedPercent / 100.0;
    return (extractedTax - expected).abs() <= tolerance;
  }
}
