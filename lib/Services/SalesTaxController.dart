import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SalesTaxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, double> _cachedTaxRates = {};
  DateTime? _lastCacheUpdate;

  Future<Map<String, double>> _loadTaxRatesFromDatabase() async {
    try {
      final snapshot = await _firestore.collection('categories').get();
      Map<String, double> taxRates = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final categoryName = data['name'] as String?;
        final salesTaxApplicable = data['salesTaxApplicable'] as bool? ?? true;
        final salesTaxRate = data['salesTaxRate'] as double? ?? 0.0;

        if (categoryName != null) {
          taxRates[categoryName] = salesTaxApplicable ? salesTaxRate : 0.0;
        }
      }

      _cachedTaxRates = taxRates;
      _lastCacheUpdate = DateTime.now();
      return taxRates;
    } catch (e) {
      print("Error loading tax rates from database: $e");
      return _getDefaultTaxRates();
    }
  }

  Future<Map<String, double>> _getTaxRates() async {
    final now = DateTime.now();

    if (_lastCacheUpdate != null &&
        now.difference(_lastCacheUpdate!).inMinutes < 5 &&
        _cachedTaxRates.isNotEmpty) {
      return _cachedTaxRates;
    }

    return await _loadTaxRatesFromDatabase();
  }

  Map<String, double> _getDefaultTaxRates() {
    return {
      'Restaurant': 0.18,
      'Dining': 0.18,
      'Fastfood': 0.18,
      'Cafe': 0.18,
      'Cake': 0.18,
      'Groceries': 0.18,
      'Car': 0.18,
      'Bus': 0.18,
      'Bike': 0.18,
      'Taxi': 0.18,
      'Plumbing': 0.18,
      'Movie': 0.18,
      'M': 0.18,
      'Games': 0.18,
      'Ticket': 0.18,
      'Clothing': 0.18,
      'Hospital': 0.0,
      'Pharmacy': 0.0,
      'FirstAid': 0.0,
      'Gym': 0.18,
      'Rent': 0.0,
      'Apartment': 0.0,
      'Kitchen': 0.18,
      'Furniture': 0.18,
    };
  }

  Future<double> calculateSalesTaxForTransaction(
      String categoryName, double amount) async {
    final taxRates = await _getTaxRates();
    final taxRate = taxRates[categoryName] ?? 0.0;

    if (taxRate == 0.0) return 0.0;

    return amount * taxRate;
  }

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

  Future<Map<String, dynamic>> calculateTotalSalesTax({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final transactions = await getExpenseTransactions(
        startDate: startDate,
        endDate: endDate,
      );

      final taxRates = await _getTaxRates();

      double totalSalesTax = 0.0;
      double totalExpenseAmount = 0.0;
      double totalTaxableAmount = 0.0;
      Map<String, double> categoryWiseTax = {};
      Map<String, double> categoryWiseAmount = {};

      for (final transaction in transactions) {
        final categoryName = transaction['category_name'] as String;
        final amount = transaction['amount'] as double;

        final taxRate = taxRates[categoryName] ?? 0.0;
        final salesTax = taxRate > 0 ? amount * taxRate : 0.0;

        totalSalesTax += salesTax;
        totalExpenseAmount += amount;
        if (salesTax > 0) totalTaxableAmount += amount;

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

  Future<Map<String, dynamic>> calculateYearlySalesTax([int? year]) async {
    final targetYear = year ?? DateTime.now().year;
    final startDate = DateTime(targetYear, 1, 1);
    final endDate = DateTime(targetYear, 12, 31, 23, 59, 59);

    return await calculateTotalSalesTax(
      startDate: startDate,
      endDate: endDate,
    );
  }

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

  Future<double> getSalesTaxRate(String categoryName) async {
    final taxRates = await _getTaxRates();
    return taxRates[categoryName] ?? 0.0;
  }

  Future<Map<String, double>> getAllTaxRates() async {
    return await _getTaxRates();
  }

  Future<bool> isCategoryTaxExempt(String categoryName) async {
    final taxRates = await _getTaxRates();
    return (taxRates[categoryName] ?? 0.0) == 0.0;
  }

  Future<List<String>> getTaxExemptCategories() async {
    final taxRates = await _getTaxRates();
    return taxRates.entries
        .where((entry) => entry.value == 0.0)
        .map((entry) => entry.key)
        .toList();
  }

  Future<List<String>> getTaxableCategories() async {
    final taxRates = await _getTaxRates();
    return taxRates.entries
        .where((entry) => entry.value > 0.0)
        .map((entry) => entry.key)
        .toList();
  }

  void clearCache() {
    _cachedTaxRates.clear();
    _lastCacheUpdate = null;
  }
}
