class PakistanTaxCalculator {
  // Tax brackets for Pakistan (2023-2024)
  static const List<TaxBracket> TAX_BRACKETS = [
    TaxBracket(0, 600000, 0, 0), // 0% up to 600,000
    TaxBracket(600001, 1200000, 0, 2.5), // 2.5% from 600,001 to 1,200,000
    TaxBracket(
        1200001, 2400000, 15000, 12.5), // 12.5% from 1,200,001 to 2,400,000
    TaxBracket(2400001, 3600000, 165000, 20), // 20% from 2,400,001 to 3,600,000
    TaxBracket(3600001, 6000000, 405000, 25), // 25% from 3,600,001 to 6,000,000
    TaxBracket(
        6000001, double.infinity, 1005000, 32.5), // 32.5% above 6,000,000
  ];

  double calculateAnnualTax(double annualIncome) {
    for (var bracket in TAX_BRACKETS) {
      if (annualIncome <= bracket.upperLimit) {
        double taxableAmount = annualIncome - bracket.lowerLimit;
        return bracket.baseTax + (taxableAmount * bracket.taxRate / 100);
      }
    }
    return 0;
  }

  double calculateMonthlyTax(double monthlyIncome) {
    return calculateAnnualTax(monthlyIncome * 12) / 12;
  }

  // Calculate tax deductions (e.g., Zakat, charitable donations)
  double calculateDeductions(List<TaxDeduction> deductions) {
    return deductions.fold(0, (sum, deduction) => sum + deduction.amount);
  }

  // Calculate final tax after deductions
  double calculateFinalTax(double annualIncome, List<TaxDeduction> deductions) {
    double grossTax = calculateAnnualTax(annualIncome);
    double totalDeductions = calculateDeductions(deductions);
    return grossTax - totalDeductions;
  }
}

class TaxBracket {
  final double lowerLimit;
  final double upperLimit;
  final double baseTax;
  final double taxRate;

  const TaxBracket(
      this.lowerLimit, this.upperLimit, this.baseTax, this.taxRate);
}

class TaxDeduction {
  final String type; // e.g., 'Zakat', 'Charitable Donation'
  final double amount;
  final String description;

  TaxDeduction({
    required this.type,
    required this.amount,
    this.description = '',
  });
}
