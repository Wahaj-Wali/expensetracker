import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer';

class AdminStatsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache for tax rates (similar to SalesTaxController pattern)
  Map<String, double> _cachedTaxRates = {};
  DateTime? _lastTaxCacheUpdate;

  // Get total users count
  Future<int> getTotalUsersCount() async {
    try {
      final snapshot = await _firestore.collection('authentication').get();
      return snapshot.docs.length;
    } catch (e) {
      log("Error getting total users count: $e");
      return 0;
    }
  }

  // Get active users (users with at least one transaction in last 30 days)
  Future<int> getActiveUsersCount() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final snapshot = await _firestore
          .collection('transactions')
          .where('timestamp', isGreaterThan: thirtyDaysAgo)
          .get();

      Set<String> activeUserEmails = {};
      for (var doc in snapshot.docs) {
        final email = doc.data()['email'];
        if (email != null) {
          activeUserEmails.add(email);
        }
      }

      return activeUserEmails.length;
    } catch (e) {
      log("Error getting active users count: $e");
      return 0;
    }
  }

  // Get total transactions count
  Future<int> getTotalTransactionsCount() async {
    try {
      final snapshot = await _firestore.collection('transactions').get();
      return snapshot.docs.length;
    } catch (e) {
      log("Error getting total transactions count: $e");
      return 0;
    }
  }

  // Get total expense amount across all users
  Future<double> getTotalExpenseAmount() async {
    try {
      final snapshot = await _firestore
          .collection('transactions')
          .where('transaction_type', isEqualTo: 'Expense')
          .get();

      double totalExpense = 0.0;
      for (var doc in snapshot.docs) {
        final amount = doc.data()['amount'];
        if (amount is String) {
          totalExpense += double.tryParse(amount) ?? 0.0;
        } else if (amount is num) {
          totalExpense += amount.toDouble();
        }
      }

      return totalExpense;
    } catch (e) {
      log("Error getting total expense amount: $e");
      return 0.0;
    }
  }

  // Get total income amount across all users
  Future<double> getTotalIncomeAmount() async {
    try {
      final snapshot = await _firestore
          .collection('transactions')
          .where('transaction_type', isEqualTo: 'Income')
          .get();

      double totalIncome = 0.0;
      for (var doc in snapshot.docs) {
        final amount = doc.data()['amount'];
        if (amount is String) {
          totalIncome += double.tryParse(amount) ?? 0.0;
        } else if (amount is num) {
          totalIncome += amount.toDouble();
        }
      }

      return totalIncome;
    } catch (e) {
      log("Error getting total income amount: $e");
      return 0.0;
    }
  }

  // Get category-wise expense data (updated to include global categories)
  Future<Map<String, double>> getCategoryWiseExpenses() async {
    try {
      final snapshot = await _firestore
          .collection('transactions')
          .where('transaction_type', isEqualTo: 'Expense')
          .get();

      Map<String, double> categoryExpenses = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final categoryName = data['category_name'] ?? 'Unknown';
        final amount = data['amount'];

        double amountValue = 0.0;
        if (amount is String) {
          amountValue = double.tryParse(amount) ?? 0.0;
        } else if (amount is num) {
          amountValue = amount.toDouble();
        }

        categoryExpenses[categoryName] =
            (categoryExpenses[categoryName] ?? 0.0) + amountValue;
      }

      return categoryExpenses;
    } catch (e) {
      log("Error getting category-wise expenses: $e");
      return {};
    }
  }

  // Get monthly transaction trends
  Future<List<Map<String, dynamic>>> getMonthlyTransactionTrends() async {
    try {
      final snapshot = await _firestore.collection('transactions').get();

      Map<String, Map<String, double>> monthlyData = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
        if (timestamp == null) continue;

        final monthKey =
            '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}';
        final type = data['transaction_type'];
        final amount = data['amount'];

        double amountValue = 0.0;
        if (amount is String) {
          amountValue = double.tryParse(amount) ?? 0.0;
        } else if (amount is num) {
          amountValue = amount.toDouble();
        }

        if (!monthlyData.containsKey(monthKey)) {
          monthlyData[monthKey] = {'Income': 0.0, 'Expense': 0.0};
        }

        if (type == 'Income' || type == 'Expense') {
          monthlyData[monthKey]![type] =
              (monthlyData[monthKey]![type] ?? 0.0) + amountValue;
        }
      }

      // Convert to list and sort by date
      List<Map<String, dynamic>> trends = [];
      for (var entry in monthlyData.entries) {
        trends.add({
          'month': entry.key,
          'income': entry.value['Income'] ?? 0.0,
          'expense': entry.value['Expense'] ?? 0.0,
        });
      }

      trends.sort((a, b) => a['month'].compareTo(b['month']));
      return trends;
    } catch (e) {
      log("Error getting monthly transaction trends: $e");
      return [];
    }
  }

  // Get user registration trends
  Future<List<Map<String, dynamic>>> getUserRegistrationTrends() async {
    try {
      final snapshot = await _firestore.collection('authentication').get();

      Map<String, int> monthlyRegistrations = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        DateTime? registrationDate;

        if (data.containsKey('created_at') && data['created_at'] != null) {
          registrationDate = (data['created_at'] as Timestamp).toDate();
        } else {
          // Use current date as fallback (not ideal, but prevents errors)
          registrationDate = DateTime.now();
        }

        final monthKey =
            '${registrationDate.year}-${registrationDate.month.toString().padLeft(2, '0')}';
        monthlyRegistrations[monthKey] =
            (monthlyRegistrations[monthKey] ?? 0) + 1;
      }

      List<Map<String, dynamic>> trends = [];
      for (var entry in monthlyRegistrations.entries) {
        trends.add({
          'month': entry.key,
          'registrations': entry.value,
        });
      }

      trends.sort((a, b) => a['month'].compareTo(b['month']));
      return trends;
    } catch (e) {
      log("Error getting user registration trends: $e");
      return [];
    }
  }

  // Get top spending users
  Future<List<Map<String, dynamic>>> getTopSpendingUsers(
      {int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('transactions')
          .where('transaction_type', isEqualTo: 'Expense')
          .get();

      Map<String, double> userExpenses = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final email = data['email'];
        final amount = data['amount'];

        if (email == null) continue;

        double amountValue = 0.0;
        if (amount is String) {
          amountValue = double.tryParse(amount) ?? 0.0;
        } else if (amount is num) {
          amountValue = amount.toDouble();
        }

        userExpenses[email] = (userExpenses[email] ?? 0.0) + amountValue;
      }

      // Convert to list and sort by expense amount
      List<Map<String, dynamic>> topUsers = [];
      for (var entry in userExpenses.entries) {
        topUsers.add({
          'email': entry.key,
          'totalExpense': entry.value,
        });
      }

      topUsers.sort((a, b) => b['totalExpense'].compareTo(a['totalExpense']));
      return topUsers.take(limit).toList();
    } catch (e) {
      log("Error getting top spending users: $e");
      return [];
    }
  }

  // Load tax rates from database (similar to SalesTaxController)
  Future<Map<String, double>> _loadTaxRatesFromDatabase() async {
    try {
      // Get tax rates from both global and user categories
      final globalCategoriesSnapshot =
          await _firestore.collection('global_categories').get();
      final userCategoriesSnapshot =
          await _firestore.collection('categories').get();

      Map<String, double> taxRates = {};

      // Process global categories
      for (var doc in globalCategoriesSnapshot.docs) {
        final data = doc.data();
        final categoryName = data['name'];
        if (categoryName != null) {
          // Set default tax rates based on category type
          if (categoryName == 'Healthcare' || categoryName == 'Housing') {
            taxRates[categoryName] = 0.0;
          } else {
            taxRates[categoryName] = 0.18; // 18% default
          }
        }
      }

      // Override with user-specific tax rates
      for (var doc in userCategoriesSnapshot.docs) {
        final data = doc.data();
        final categoryName = data['name'];
        final salesTaxApplicable = data['salesTaxApplicable'] ?? true;
        final salesTaxRate = data['salesTaxRate'] ?? 0.18;

        if (categoryName != null) {
          taxRates[categoryName] = salesTaxApplicable ? salesTaxRate : 0.0;
        }
      }

      _cachedTaxRates = taxRates;
      _lastTaxCacheUpdate = DateTime.now();
      return taxRates;
    } catch (e) {
      log("Error loading tax rates from database: $e");
      return _getDefaultTaxRates();
    }
  }

  // Get tax rates with caching
  Future<Map<String, double>> _getTaxRates() async {
    final now = DateTime.now();

    if (_lastTaxCacheUpdate != null &&
        now.difference(_lastTaxCacheUpdate!).inMinutes < 5 &&
        _cachedTaxRates.isNotEmpty) {
      return _cachedTaxRates;
    }

    return await _loadTaxRatesFromDatabase();
  }

  // Default tax rates fallback
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
    };
  }

  // Get sales tax statistics (updated to use proper tax rate loading)
  Future<Map<String, dynamic>> getSalesTaxStatistics() async {
    try {
      final snapshot = await _firestore
          .collection('transactions')
          .where('transaction_type', isEqualTo: 'Expense')
          .get();

      double totalTaxableAmount = 0.0;
      double totalTaxAmount = 0.0;
      Map<String, double> categoryTaxes = {};

      // Get tax rates using the cached method
      final taxRates = await _getTaxRates();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final categoryName = data['category_name'];
        final amount = data['amount'];

        if (categoryName == null) continue;

        double amountValue = 0.0;
        if (amount is String) {
          amountValue = double.tryParse(amount) ?? 0.0;
        } else if (amount is num) {
          amountValue = amount.toDouble();
        }

        final taxRate = taxRates[categoryName] ?? 0.0;
        final taxAmount = amountValue * taxRate;

        totalTaxableAmount += amountValue;
        totalTaxAmount += taxAmount;

        categoryTaxes[categoryName] =
            (categoryTaxes[categoryName] ?? 0.0) + taxAmount;
      }

      return {
        'totalTaxableAmount': totalTaxableAmount,
        'totalTaxAmount': totalTaxAmount,
        'averageTaxRate': totalTaxableAmount > 0
            ? (totalTaxAmount / totalTaxableAmount) * 100
            : 0.0,
        'categoryTaxes': categoryTaxes,
      };
    } catch (e) {
      log("Error getting sales tax statistics: $e");
      return {
        'totalTaxableAmount': 0.0,
        'totalTaxAmount': 0.0,
        'averageTaxRate': 0.0,
        'categoryTaxes': <String, double>{},
      };
    }
  }

  // Get account types distribution (updated to handle better categorization)
  Future<Map<String, int>> getAccountTypesDistribution() async {
    try {
      final snapshot = await _firestore.collection('accounts').get();

      Map<String, int> accountTypes = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final accountImage = data['account_image'] ?? '';
        final accountName = data['account_name'] ?? '';
        String accountType = 'Unknown';

        // Determine account type based on image or name
        if (accountImage.contains('wallet') ||
            accountName.toLowerCase().contains('wallet')) {
          accountType = 'Wallet';
        } else if (accountImage.contains('easypaisa') ||
            accountImage.contains('jazzcash') ||
            accountImage.contains('nayapay') ||
            accountImage.contains('sadapay') ||
            accountImage.contains('zindigi') ||
            accountImage.contains('upaisa') ||
            accountName.toLowerCase().contains('easypaisa') ||
            accountName.toLowerCase().contains('jazzcash') ||
            accountName.toLowerCase().contains('nayapay') ||
            accountName.toLowerCase().contains('sadapay')) {
          accountType = 'Digital Wallet';
        } else if (accountImage.contains('bank') ||
            accountImage.contains('listBank') ||
            accountName.toLowerCase().contains('bank')) {
          accountType = 'Bank Account';
        } else if (accountImage.contains('card') ||
            accountName.toLowerCase().contains('card')) {
          accountType = 'Card';
        }

        accountTypes[accountType] = (accountTypes[accountType] ?? 0) + 1;
      }

      return accountTypes;
    } catch (e) {
      log("Error getting account types distribution: $e");
      return {};
    }
  }

  // Get user types distribution
  Future<Map<String, int>> getUserTypesDistribution() async {
    try {
      final snapshot = await _firestore.collection('authentication').get();

      Map<String, int> userTypes = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final userType = data['user_type'] ?? 'basic user';
        userTypes[userType] = (userTypes[userType] ?? 0) + 1;
      }

      return userTypes;
    } catch (e) {
      log("Error getting user types distribution: $e");
      return {};
    }
  }

  // Get global categories statistics
  Future<Map<String, dynamic>> getGlobalCategoriesStats() async {
    try {
      final globalSnapshot =
          await _firestore.collection('global_categories').get();
      final userSnapshot = await _firestore.collection('categories').get();

      return {
        'globalCategoriesCount': globalSnapshot.docs.length,
        'userCategoriesCount': userSnapshot.docs.length,
        'totalCategoriesCount':
            globalSnapshot.docs.length + userSnapshot.docs.length,
      };
    } catch (e) {
      log("Error getting global categories stats: $e");
      return {
        'globalCategoriesCount': 0,
        'userCategoriesCount': 0,
        'totalCategoriesCount': 0,
      };
    }
  }

  // Get platform usage statistics (based on signup method)
  Future<Map<String, int>> getPlatformUsageStats() async {
    try {
      final snapshot = await _firestore.collection('authentication').get();

      Map<String, int> platformStats = {
        'email': 0,
        'google': 0,
        'unknown': 0,
      };

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final signupMethod = data['signup_method'];

        if (signupMethod == 'google') {
          platformStats['google'] = (platformStats['google'] ?? 0) + 1;
        } else if (signupMethod == null && data['password'] != null) {
          platformStats['email'] = (platformStats['email'] ?? 0) + 1;
        } else {
          platformStats['unknown'] = (platformStats['unknown'] ?? 0) + 1;
        }
      }

      return platformStats;
    } catch (e) {
      log("Error getting platform usage stats: $e");
      return {'email': 0, 'google': 0, 'unknown': 0};
    }
  }

  // Clear tax rates cache
  void clearTaxCache() {
    _cachedTaxRates.clear();
    _lastTaxCacheUpdate = null;
  }

  // Get comprehensive dashboard data
  Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final results = await Future.wait([
        getTotalUsersCount(),
        getActiveUsersCount(),
        getTotalTransactionsCount(),
        getTotalExpenseAmount(),
        getTotalIncomeAmount(),
        getCategoryWiseExpenses(),
        getMonthlyTransactionTrends(),
        getUserRegistrationTrends(),
        getTopSpendingUsers(),
        getSalesTaxStatistics(),
        getAccountTypesDistribution(),
        getUserTypesDistribution(),
        getGlobalCategoriesStats(),
        getPlatformUsageStats(),
      ]);

      return {
        'totalUsers': results[0],
        'activeUsers': results[1],
        'totalTransactions': results[2],
        'totalExpenses': results[3],
        'totalIncome': results[4],
        'categoryExpenses': results[5],
        'monthlyTrends': results[6],
        'registrationTrends': results[7],
        'topSpendingUsers': results[8],
        'salesTaxStats': results[9],
        'accountTypesDistribution': results[10],
        'userTypesDistribution': results[11],
        'globalCategoriesStats': results[12],
        'platformUsageStats': results[13],
      };
    } catch (e) {
      log("Error getting dashboard data: $e");
      return {};
    }
  }

  // Admin helper methods

  // Check if current user is admin
  Future<bool> isCurrentUserAdmin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email');

      if (email == null) return false;

      final snapshot = await _firestore
          .collection('authentication')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final userData = snapshot.docs.first.data();
        return userData['user_type'] == 'admin' || userData['is_admin'] == true;
      }

      return false;
    } catch (e) {
      log("Error checking admin status: $e");
      return false;
    }
  }

  // Get system health statistics
  Future<Map<String, dynamic>> getSystemHealthStats() async {
    try {
      final now = DateTime.now();
      final lastHour = now.subtract(const Duration(hours: 1));
      final lastDay = now.subtract(const Duration(days: 1));

      // Get recent transactions
      final recentTransactionsSnapshot = await _firestore
          .collection('transactions')
          .where('timestamp', isGreaterThan: lastHour)
          .get();

      // Get recent user registrations
      final recentUsersSnapshot = await _firestore
          .collection('authentication')
          .where('created_at', isGreaterThan: lastDay)
          .get();

      return {
        'recentTransactionsCount': recentTransactionsSnapshot.docs.length,
        'recentUsersCount': recentUsersSnapshot.docs.length,
        'systemStatus': 'healthy',
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      log("Error getting system health stats: $e");
      return {
        'recentTransactionsCount': 0,
        'recentUsersCount': 0,
        'systemStatus': 'error',
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    }
  }
}
