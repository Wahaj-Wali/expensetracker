import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SalesTaxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Pakistani Sales Tax rates - 18% for applicable categories, 0% for exempt
  final Map<String, double> _salesTaxRates = {
    // Food & Beverages - 18% GST
    'Restaurant': 0.18,
    'Dining': 0.18,
    'Fastfood': 0.18,
    'Cafe': 0.18,
    'Cake': 0.18,
    'Groceries': 0.18,

    // Transportation - 18% GST
    'Car': 0.18,
    'Bus': 0.18,
    'Bike': 0.18,
    'Taxi': 0.18,

    // Utilities - 18% GST
    'Plumbing': 0.18,

    // Entertainment - 18% GST
    'Movie': 0.18,
    'M': 0.18, // Music
    'Games': 0.18,
    'Ticket': 0.18,

    // Shopping - 18% GST
    'Clothing': 0.18,

    // Health - 0% (Medical services are exempt)
    'Hospital': 0.0,
    'Pharmacy': 0.0,
    'FirstAid': 0.0,

    // Fitness - 18% GST
    'Gym': 0.18,

    // Home & Rent - 0% (Rent is exempt)
    'Rent': 0.0,
    'Apartment': 0.0,
    'Kitchen': 0.18, // Kitchen items/appliances
    'Furniture': 0.18,
  };

  // Calculate sales tax for a single transaction
  double calculateSalesTaxForTransaction(String categoryName, double amount) {
    double taxRate = _salesTaxRates[categoryName] ?? 0.18; // Default 18% GST

    // If tax rate is 0 (exempt category), return 0
    if (taxRate == 0.0) {
      return 0.0;
    }

    // Calculate 18% of the expense amount
    return amount * taxRate;
  }

  // Get all expense transactions for the current user within a date range
  Future<List<Map<String, dynamic>>> getExpenseTransactions({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email');
      if (email == null) {
        throw Exception("User email not found in preferences.");
      }

      Query query = _firestore
          .collection('transactions')
          .where('email', isEqualTo: email)
          .where('transaction_type', isEqualTo: 'Expense');

      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
      }
      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: endDate);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'transaction_id': data['transaction_id'],
          'category_name': data['category_name'],
          'amount': data['amount'] is String
              ? double.tryParse(data['amount']) ?? 0.0
              : data['amount'].toDouble(),
          'timestamp': data['timestamp'],
          'description': data['description'],
        };
      }).toList();
    } catch (e) {
      print("Error fetching expense transactions: $e");
      return [];
    }
  }

  // Calculate total sales tax for a specific period
  Future<Map<String, dynamic>> calculateTotalSalesTax({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final transactions = await getExpenseTransactions(
        startDate: startDate,
        endDate: endDate,
      );

      double totalSalesTax = 0.0;
      double totalExpenseAmount = 0.0;
      double totalTaxableAmount = 0.0;
      Map<String, double> categoryWiseTax = {};
      Map<String, double> categoryWiseAmount = {};

      for (final transaction in transactions) {
        final categoryName = transaction['category_name'] as String;
        final amount = transaction['amount'] as double;

        final salesTax = calculateSalesTaxForTransaction(categoryName, amount);

        totalSalesTax += salesTax;
        totalExpenseAmount += amount;

        // Only add to taxable amount if tax is applied
        if (salesTax > 0) {
          totalTaxableAmount += amount;
        }

        // Category-wise breakdown
        categoryWiseTax[categoryName] =
            (categoryWiseTax[categoryName] ?? 0.0) + salesTax;
        categoryWiseAmount[categoryName] =
            (categoryWiseAmount[categoryName] ?? 0.0) + amount;
      }

      return {
        'success': true,
        'totalSalesTax': totalSalesTax,
        'totalExpenseAmount': totalExpenseAmount,
        'totalTaxableAmount': totalTaxableAmount,
        'transactionCount': transactions.length,
        'categoryWiseTax': categoryWiseTax,
        'categoryWiseAmount': categoryWiseAmount,
        'averageTaxRate': totalTaxableAmount > 0
            ? (totalSalesTax / totalTaxableAmount) * 100
            : 0.0,
      };
    } catch (e) {
      return {
        'success': false,
        'message': "Error calculating sales tax: ${e.toString()}",
        'totalSalesTax': 0.0,
        'totalExpenseAmount': 0.0,
        'totalTaxableAmount': 0.0,
        'transactionCount': 0,
        'categoryWiseTax': <String, double>{},
        'categoryWiseAmount': <String, double>{},
        'averageTaxRate': 0.0,
      };
    }
  }

  // Calculate yearly sales tax
  Future<Map<String, dynamic>> calculateYearlySalesTax([int? year]) async {
    final targetYear = year ?? DateTime.now().year;
    final startDate = DateTime(targetYear, 1, 1);
    final endDate = DateTime(targetYear, 12, 31, 23, 59, 59);

    return await calculateTotalSalesTax(
      startDate: startDate,
      endDate: endDate,
    );
  }

  // Calculate monthly sales tax
  Future<Map<String, dynamic>> calculateMonthlySalesTax(
      [int? year, int? month]) async {
    final targetYear = year ?? DateTime.now().year;
    final targetMonth = month ?? DateTime.now().month;
    final startDate = DateTime(targetYear, targetMonth, 1);
    final endDate = DateTime(targetYear, targetMonth + 1, 0, 23, 59, 59);

    return await calculateTotalSalesTax(
      startDate: startDate,
      endDate: endDate,
    );
  }

  // Get sales tax rate for a category
  double getSalesTaxRate(String categoryName) {
    return _salesTaxRates[categoryName] ?? 0.18; // Default 18% GST
  }

  // Get all available tax rates
  Map<String, double> getAllTaxRates() {
    return Map.from(_salesTaxRates);
  }

  // Check if a category is tax exempt
  bool isCategoryTaxExempt(String categoryName) {
    return (_salesTaxRates[categoryName] ?? 0.18) == 0.0;
  }

  // Get list of tax exempt categories
  List<String> getTaxExemptCategories() {
    return _salesTaxRates.entries
        .where((entry) => entry.value == 0.0)
        .map((entry) => entry.key)
        .toList();
  }

  // Get list of taxable categories
  List<String> getTaxableCategories() {
    return _salesTaxRates.entries
        .where((entry) => entry.value > 0.0)
        .map((entry) => entry.key)
        .toList();
  }
}
