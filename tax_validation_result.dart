class TaxValidationResult {
  final bool isValid;
  final double expectedTaxRate;
  final double foundTaxRate;
  final String message;
  final String taxType;

  TaxValidationResult({
    required this.isValid,
    required this.expectedTaxRate,
    required this.foundTaxRate,
    required this.message,
    this.taxType = 'GST',
  });

  Map<String, dynamic> toJson() {
    return {
      'isValid': isValid,
      'expectedTaxRate': expectedTaxRate,
      'foundTaxRate': foundTaxRate,
      'message': message,
      'taxType': taxType,
    };
  }

  factory TaxValidationResult.fromJson(Map<String, dynamic> json) {
    return TaxValidationResult(
      isValid: json['isValid'] ?? false,
      expectedTaxRate: (json['expectedTaxRate'] ?? 0.0).toDouble(),
      foundTaxRate: (json['foundTaxRate'] ?? 0.0).toDouble(),
      message: json['message'] ?? '',
      taxType: json['taxType'] ?? 'GST',
    );
  }
}
