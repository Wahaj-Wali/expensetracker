import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer';

class AdminStatsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
        activeUserEmails.add(doc['email']);
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
        final amount = doc['amount'];
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
        final amount = doc['amount'];
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

  // Get category-wise expense data
  Future<Map<String, double>> getCategoryWiseExpenses() async {
    try {
      final snapshot = await _firestore
          .collection('transactions')
          .where('transaction_type', isEqualTo: 'Expense')
          .get();

      Map<String, double> categoryExpenses = {};

      for (var doc in snapshot.docs) {
        final categoryName = doc['category_name'] ?? 'Unknown';
        final amount = doc['amount'];

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
        final timestamp = (doc['timestamp'] as Timestamp?)?.toDate();
        if (timestamp == null) continue;

        final monthKey =
            '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}';
        final type = doc['transaction_type'];
        final amount = doc['amount'];

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
        // If there's a registration date field, use it; otherwise use document creation time
        DateTime? registrationDate;

        if (doc.data().containsKey('created_at')) {
          registrationDate = (doc['created_at'] as Timestamp?)?.toDate();
        } else {
          // Fallback to document creation time (not ideal but better than nothing)
          registrationDate =
              DateTime.now(); // You might want to add created_at field
        }

        if (registrationDate != null) {
          final monthKey =
              '${registrationDate.year}-${registrationDate.month.toString().padLeft(2, '0')}';
          monthlyRegistrations[monthKey] =
              (monthlyRegistrations[monthKey] ?? 0) + 1;
        }
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
        final email = doc['email'];
        final amount = doc['amount'];

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

  // Get sales tax statistics
  Future<Map<String, dynamic>> getSalesTaxStatistics() async {
    try {
      final snapshot = await _firestore
          .collection('transactions')
          .where('transaction_type', isEqualTo: 'Expense')
          .get();

      double totalTaxableAmount = 0.0;
      double totalTaxAmount = 0.0;
      Map<String, double> categoryTaxes = {};

      // Get tax rates (you might want to cache this)
      final categoriesSnapshot =
          await _firestore.collection('categories').get();
      final globalCategoriesSnapshot =
          await _firestore.collection('global_categories').get();

      Map<String, double> taxRates = {};

      // Add global categories tax rates (default 18% for most, 0% for healthcare/housing)
      for (var doc in globalCategoriesSnapshot.docs) {
        final categoryName = doc['name'];
        // Set default tax rates based on category
        if (categoryName == 'Healthcare' || categoryName == 'Housing') {
          taxRates[categoryName] = 0.0;
        } else {
          taxRates[categoryName] = 0.18; // 18% default
        }
      }

      // Override with user-specific tax rates if any
      for (var doc in categoriesSnapshot.docs) {
        final categoryName = doc['name'];
        final salesTaxApplicable = doc['salesTaxApplicable'] ?? true;
        final salesTaxRate = doc['salesTaxRate'] ?? 0.18;

        taxRates[categoryName] = salesTaxApplicable ? salesTaxRate : 0.0;
      }

      for (var doc in snapshot.docs) {
        final categoryName = doc['category_name'];
        final amount = doc['amount'];

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

  // Get account types distribution
  Future<Map<String, int>> getAccountTypesDistribution() async {
    try {
      final snapshot = await _firestore.collection('accounts').get();

      Map<String, int> accountTypes = {};

      for (var doc in snapshot.docs) {
        final accountImage = doc['account_image'] ?? '';
        String accountType = 'Unknown';

        if (accountImage.contains('wallet')) {
          accountType = 'Wallet';
        } else if (accountImage.contains('easypaisa') ||
            accountImage.contains('jazzcash') ||
            accountImage.contains('nayapay') ||
            accountImage.contains('sadapay') ||
            accountImage.contains('zindagi') ||
            accountImage.contains('upaisa')) {
          accountType = 'UPI Account';
        } else if (accountImage.contains('listBank')) {
          accountType = 'Bank Account';
        }

        accountTypes[accountType] = (accountTypes[accountType] ?? 0) + 1;
      }

      return accountTypes;
    } catch (e) {
      log("Error getting account types distribution: $e");
      return {};
    }
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
      };
    } catch (e) {
      log("Error getting dashboard data: $e");
      return {};
    }
  }
}
