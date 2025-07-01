import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer';

class SalesTaxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, double> _cachedTaxRates = {};
  DateTime? _lastCacheUpdate;

  /// Loads tax rates from both global and user-specific categories
  Future<Map<String, double>> _loadTaxRatesFromDatabase() async {
    try {
      // Get user email for user-specific categories
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email');

      Map<String, double> taxRates = {};

      // Load global categories first
      final globalSnapshot =
          await _firestore.collection('global_categories').get();
      for (final doc in globalSnapshot.docs) {
        final data = doc.data();
        final categoryName = data['name'] as String?;
        final salesTaxApplicable = data['salesTaxApplicable'] as bool? ?? true;
        final salesTaxPercentage = data['salesTaxPercentage'] as double? ?? 0.0;

        if (categoryName != null) {
          taxRates[categoryName] =
              salesTaxApplicable ? (salesTaxPercentage / 100) : 0.0;
        }
      }

      // Load user-specific categories (if user is logged in)
      if (email != null) {
        final userSnapshot = await _firestore
            .collection('categories')
            .where('email', isEqualTo: email)
            .get();

        for (final doc in userSnapshot.docs) {
          final data = doc.data();
          final categoryName = data['name'] as String?;
          final salesTaxApplicable =
              data['salesTaxApplicable'] as bool? ?? true;

          // Handle both old and new field names for backward compatibility
          double salesTaxPercentage = 0.0;
          if (data.containsKey('salesTaxPercentage')) {
            salesTaxPercentage = data['salesTaxPercentage'] as double? ?? 0.0;
          } else if (data.containsKey('salesTaxRate')) {
            // Convert from rate to percentage if needed
            final rate = data['salesTaxRate'] as double? ?? 0.0;
            salesTaxPercentage = rate > 1 ? rate : rate * 100;
          }

          if (categoryName != null) {
            // User categories override global categories with same name
            taxRates[categoryName] =
                salesTaxApplicable ? (salesTaxPercentage / 100) : 0.0;
          }
        }
      }

      _cachedTaxRates = taxRates;
      _lastCacheUpdate = DateTime.now();
      log("Loaded ${taxRates.length} tax rates from database");
      return taxRates;
    } catch (e) {
      log("Error loading tax rates from database: $e");
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

  /// Default tax rates as fallback (converted to decimal rates)
  Map<String, double> _getDefaultTaxRates() {
    return {
      'Food & Dining': 0.18,
      'Transportation': 0.18,
      'Groceries': 0.18,
      'Entertainment': 0.18,
      'Housing': 0.0,
      'Healthcare': 0.0,
      'Fitness': 0.18,
      'Shopping': 0.18,
      'Utilities': 0.18,
      'Gifts & Treats': 0.18,
      // Legacy category names for backward compatibility
      'Restaurant': 0.18,
      'Dining': 0.18,
      'Fastfood': 0.18,
      'Cafe': 0.18,
      'Cake': 0.18,
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

  /// Calculates sales tax for a transaction
  Future<double> calculateSalesTaxForTransaction(
      String categoryName, double amount) async {
    try {
      final taxRates = await _getTaxRates();
      final taxRate = taxRates[categoryName] ?? 0.0;

      if (taxRate == 0.0) return 0.0;

      final tax = amount * taxRate;
      log("Calculated tax for $categoryName: ${(taxRate * 100).toStringAsFixed(1)}% of $amount = $tax");
      return tax;
    } catch (e) {
      log("Error calculating sales tax: $e");
      return 0.0;
    }
  }

  /// Gets expense transactions for a user within date range
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
              : (data['amount'] ?? 0.0).toDouble(),
          'timestamp': data['timestamp'],
          'description': data['description'],
        };
      }).toList();
    } catch (e) {
      log("Error fetching expense transactions: $e");
      return [];
    }
  }

  /// Calculates total sales tax for transactions within date range
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

      log("Calculated total sales tax: $totalSalesTax from $totalExpenseAmount total expenses");

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
      log("Error calculating total sales tax: $e");
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

  /// Calculates yearly sales tax
  Future<Map<String, dynamic>> calculateYearlySalesTax([int? year]) async {
    final targetYear = year ?? DateTime.now().year;
    final startDate = DateTime(targetYear, 1, 1);
    final endDate = DateTime(targetYear, 12, 31, 23, 59, 59);

    return await calculateTotalSalesTax(
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Calculates monthly sales tax
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

  /// Gets the sales tax rate for a specific category
  Future<double> getSalesTaxRate(String categoryName) async {
    try {
      final taxRates = await _getTaxRates();
      final rate = taxRates[categoryName] ?? 0.0;
      log("Tax rate for $categoryName: ${(rate * 100).toStringAsFixed(1)}%");
      return rate;
    } catch (e) {
      log("Error getting tax rate for $categoryName: $e");
      return 0.0;
    }
  }

  /// Gets the sales tax percentage for a specific category (for display purposes)
  Future<double> getSalesTaxPercentage(String categoryName) async {
    final rate = await getSalesTaxRate(categoryName);
    return rate * 100;
  }

  /// Gets all tax rates as a map
  Future<Map<String, double>> getAllTaxRates() async {
    return await _getTaxRates();
  }

  /// Gets all tax rates as percentages (for display purposes)
  Future<Map<String, double>> getAllTaxPercentages() async {
    final rates = await _getTaxRates();
    return rates.map((key, value) => MapEntry(key, value * 100));
  }

  /// Checks if a category is tax-exempt
  Future<bool> isCategoryTaxExempt(String categoryName) async {
    final taxRates = await _getTaxRates();
    return (taxRates[categoryName] ?? 0.0) == 0.0;
  }

  /// Gets list of tax-exempt categories
  Future<List<String>> getTaxExemptCategories() async {
    final taxRates = await _getTaxRates();
    return taxRates.entries
        .where((entry) => entry.value == 0.0)
        .map((entry) => entry.key)
        .toList();
  }

  /// Gets list of taxable categories
  Future<List<String>> getTaxableCategories() async {
    final taxRates = await _getTaxRates();
    return taxRates.entries
        .where((entry) => entry.value > 0.0)
        .map((entry) => entry.key)
        .toList();
  }

  /// Gets detailed tax information for all categories
  Future<Map<String, Map<String, dynamic>>> getDetailedTaxInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email');

      Map<String, Map<String, dynamic>> taxInfo = {};

      // Load global categories
      final globalSnapshot =
          await _firestore.collection('global_categories').get();
      for (final doc in globalSnapshot.docs) {
        final data = doc.data();
        final categoryName = data['name'] as String?;

        if (categoryName != null) {
          taxInfo[categoryName] = {
            'isGlobal': true,
            'salesTaxApplicable': data['salesTaxApplicable'] ?? true,
            'salesTaxPercentage': data['salesTaxPercentage'] ?? 0.0,
            'taxRate': (data['salesTaxApplicable'] ?? true)
                ? (data['salesTaxPercentage'] ?? 0.0) / 100
                : 0.0,
          };
        }
      }

      // Load user-specific categories (override global ones)
      if (email != null) {
        final userSnapshot = await _firestore
            .collection('categories')
            .where('email', isEqualTo: email)
            .get();

        for (final doc in userSnapshot.docs) {
          final data = doc.data();
          final categoryName = data['name'] as String?;

          if (categoryName != null) {
            final salesTaxApplicable = data['salesTaxApplicable'] ?? true;
            double salesTaxPercentage = 0.0;

            if (data.containsKey('salesTaxPercentage')) {
              salesTaxPercentage = data['salesTaxPercentage'] ?? 0.0;
            } else if (data.containsKey('salesTaxRate')) {
              final rate = data['salesTaxRate'] ?? 0.0;
              salesTaxPercentage = rate > 1 ? rate : rate * 100;
            }

            taxInfo[categoryName] = {
              'isGlobal': false,
              'salesTaxApplicable': salesTaxApplicable,
              'salesTaxPercentage': salesTaxPercentage,
              'taxRate': salesTaxApplicable ? salesTaxPercentage / 100 : 0.0,
            };
          }
        }
      }

      return taxInfo;
    } catch (e) {
      log("Error getting detailed tax info: $e");
      return {};
    }
  }

  /// Forces a refresh of the tax rates cache
  Future<void> refreshTaxRates() async {
    clearCache();
    await _loadTaxRatesFromDatabase();
    log("Tax rates cache refreshed");
  }

  /// Clears the tax rates cache
  void clearCache() {
    _cachedTaxRates.clear();
    _lastCacheUpdate = null;
    log("Tax rates cache cleared");
  }

  /// Gets cache status information
  Map<String, dynamic> getCacheStatus() {
    return {
      'isCached': _cachedTaxRates.isNotEmpty,
      'cacheSize': _cachedTaxRates.length,
      'lastUpdate': _lastCacheUpdate?.toIso8601String(),
      'cacheAge': _lastCacheUpdate != null
          ? DateTime.now().difference(_lastCacheUpdate!).inMinutes
          : null,
    };
  }
}
