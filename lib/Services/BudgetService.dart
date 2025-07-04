import 'package:ExpenseTracker/Services/BudgetNotificationService.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:developer';
import 'CategoriesService.dart';

class BudgetService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final uuid = const Uuid();

  /// Create a new budget
  static Future<Map<String, dynamic>> createBudget({
    required String name,
    required double amount,
    required String period, // 'monthly', 'weekly', 'yearly'
    String? categoryId, // Optional: link to specific category
    String? description,
    bool enableNotifications = true,
    double alertPercentage = 80.0,
    String? alertMessage,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email');
      if (email == null) {
        return {'success': false, 'message': 'User email not found'};
      }

      // Check if budget with same name already exists
      final existingBudget = await _firestore
          .collection('budgets')
          .where('email', isEqualTo: email)
          .where('name', isEqualTo: name)
          .where('is_active', isEqualTo: true)
          .limit(1)
          .get();

      if (existingBudget.docs.isNotEmpty) {
        return {
          'success': false,
          'message': 'Budget with this name already exists'
        };
      }

      final budgetId = uuid.v4();
      final now = DateTime.now();

      // Calculate period dates
      DateTime startDate, endDate;
      switch (period.toLowerCase()) {
        case 'weekly':
          startDate = now.subtract(Duration(days: now.weekday - 1));
          endDate = startDate.add(const Duration(days: 6));
          break;
        case 'yearly':
          startDate = DateTime(now.year, 1, 1);
          endDate = DateTime(now.year, 12, 31);
          break;
        case 'monthly':
        default:
          startDate = DateTime(now.year, now.month, 1);
          endDate = DateTime(now.year, now.month + 1, 0);
          break;
      }

      final budgetData = {
        'budget_id': budgetId,
        'name': name,
        'amount': amount,
        'spent_amount': 0.0,
        'period': period.toLowerCase(),
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'category_id': categoryId,
        'description': description ?? '',
        'email': email,
        'is_active': true,
        'enable_notifications': enableNotifications,
        'alert_percentage': alertPercentage,
        'alert_message':
            alertMessage ?? "You're approaching your budget limit!",
        'last_notification_date': null,
        'last_warning_date': null,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('budgets').doc(budgetId).set(budgetData);

      return {
        'success': true,
        'message': 'Budget created successfully',
        'budget_id': budgetId
      };
    } catch (e) {
      log('Error creating budget: $e');
      return {'success': false, 'message': 'Failed to create budget: $e'};
    }
  }

  /// Update budget
  static Future<Map<String, dynamic>> updateBudget({
    required String budgetId,
    String? name,
    double? amount,
    String? period,
    String? categoryId,
    String? description,
    bool? enableNotifications,
    double? alertPercentage,
    String? alertMessage,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email');
      if (email == null) {
        return {'success': false, 'message': 'User email not found'};
      }

      // Check if budget exists and belongs to user
      final budgetDoc =
          await _firestore.collection('budgets').doc(budgetId).get();
      if (!budgetDoc.exists) {
        return {'success': false, 'message': 'Budget not found'};
      }

      final budgetData = budgetDoc.data() as Map<String, dynamic>;
      if (budgetData['email'] != email) {
        return {'success': false, 'message': 'Unauthorized access'};
      }

      // Prepare update data
      Map<String, dynamic> updateData = {
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (name != null) updateData['name'] = name;
      if (amount != null) updateData['amount'] = amount;
      if (period != null) {
        updateData['period'] = period.toLowerCase();
        // Recalculate dates if period changed
        final now = DateTime.now();
        DateTime startDate, endDate;
        switch (period.toLowerCase()) {
          case 'weekly':
            startDate = now.subtract(Duration(days: now.weekday - 1));
            endDate = startDate.add(const Duration(days: 6));
            break;
          case 'yearly':
            startDate = DateTime(now.year, 1, 1);
            endDate = DateTime(now.year, 12, 31);
            break;
          case 'monthly':
          default:
            startDate = DateTime(now.year, now.month, 1);
            endDate = DateTime(now.year, now.month + 1, 0);
            break;
        }
        updateData['start_date'] = startDate.toIso8601String();
        updateData['end_date'] = endDate.toIso8601String();
      }
      if (categoryId != null) updateData['category_id'] = categoryId;
      if (description != null) updateData['description'] = description;
      if (enableNotifications != null)
        updateData['enable_notifications'] = enableNotifications;
      if (alertPercentage != null)
        updateData['alert_percentage'] = alertPercentage;
      if (alertMessage != null) updateData['alert_message'] = alertMessage;

      await _firestore.collection('budgets').doc(budgetId).update(updateData);

      return {'success': true, 'message': 'Budget updated successfully'};
    } catch (e) {
      log('Error updating budget: $e');
      return {'success': false, 'message': 'Failed to update budget: $e'};
    }
  }

  /// Get all active budgets for current user
  static Future<List<Map<String, dynamic>>> getAllBudgets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email');
      if (email == null) {
        return [];
      }

      final snapshot = await _firestore
          .collection('budgets')
          .where('email', isEqualTo: email)
          .where('is_active', isEqualTo: true)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      log('Error getting budgets: $e');
      return [];
    }
  }

  /// Get budget by ID
  static Future<Map<String, dynamic>?> getBudgetById(String budgetId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email');
      if (email == null) {
        return null;
      }

      final doc = await _firestore.collection('budgets').doc(budgetId).get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      if (data['email'] != email) {
        return null; // Security check
      }

      return data;
    } catch (e) {
      log('Error getting budget by ID: $e');
      return null;
    }
  }

  /// Get transactions related to a specific budget
  static Future<List<Map<String, dynamic>>> getBudgetTransactions(
      String budgetId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email');
      if (email == null) {
        return [];
      }

      // Get budget details first
      final budget = await getBudgetById(budgetId);
      if (budget == null) {
        return [];
      }

      final startDate = DateTime.parse(budget['start_date']);
      final endDate = DateTime.parse(budget['end_date']);
      final categoryId = budget['category_id'];

      Query query = _firestore
          .collection('transactions')
          .where('email', isEqualTo: email)
          .where('transaction_type', isEqualTo: 'Expense')
          .where('timestamp',
              isGreaterThanOrEqualTo: startDate.toUtc().toIso8601String())
          .where('timestamp',
              isLessThanOrEqualTo: endDate.toUtc().toIso8601String());

      // If budget is category-specific, filter by category
      if (categoryId != null) {
        query = query.where('category_id', isEqualTo: categoryId);
      }

      final snapshot = await query.orderBy('timestamp', descending: true).get();

      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      log('Error getting budget transactions: $e');
      return [];
    }
  }

  /// Get transactions that contributed to budget spending
  static Future<List<Map<String, dynamic>>> getBudgetRelatedTransactions(
      Map<String, dynamic> budget) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email');
      if (email == null) {
        return [];
      }

      final startDate = DateTime.parse(budget['start_date']);
      final endDate = DateTime.parse(budget['end_date']);
      final categoryId = budget['category_id'];

      // Base query for expense transactions within budget period
      Query query = _firestore
          .collection('transactions')
          .where('email', isEqualTo: email)
          .where('transaction_type', isEqualTo: 'Expense')
          .where('timestamp',
              isGreaterThanOrEqualTo: startDate.toUtc().toIso8601String())
          .where('timestamp',
              isLessThanOrEqualTo: endDate.toUtc().toIso8601String());

      QuerySnapshot snapshot;

      if (categoryId != null) {
        // For category-specific budgets, get transactions from that category
        snapshot = await query
            .where('category_id', isEqualTo: categoryId)
            .orderBy('timestamp', descending: true)
            .get();
      } else {
        // For general budgets, get all expense transactions in the period
        snapshot = await query.orderBy('timestamp', descending: true).get();
      }

      List<Map<String, dynamic>> transactions = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      // Add additional info for display
      for (var transaction in transactions) {
        transaction['contributes_to_budget'] = true;
        transaction['budget_name'] = budget['name'];
      }

      return transactions;
    } catch (e) {
      log('Error getting budget related transactions: $e');
      return [];
    }
  }

  /// Calculate budget spending from transactions
  static Future<double> calculateBudgetSpendingFromTransactions(
      String budgetId) async {
    try {
      final transactions = await getBudgetTransactions(budgetId);
      double totalSpent = 0.0;

      for (var transaction in transactions) {
        final amount = _parseAmount(transaction['amount']);
        totalSpent += amount;
      }

      return totalSpent;
    } catch (e) {
      log('Error calculating budget spending: $e');
      return 0.0;
    }
  }

  /// Helper method to parse amount from various formats
  static double _parseAmount(dynamic amount) {
    if (amount is double) return amount;
    if (amount is int) return amount.toDouble();
    if (amount is String) return double.tryParse(amount) ?? 0.0;
    return 0.0;
  }

  /// Sync budget spending with actual transactions
  static Future<bool> syncBudgetSpending(String budgetId) async {
    try {
      final actualSpending =
          await calculateBudgetSpendingFromTransactions(budgetId);

      await _firestore.collection('budgets').doc(budgetId).update({
        'spent_amount': actualSpending,
        'updated_at': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      log('Error syncing budget spending: $e');
      return false;
    }
  }

  /// Update budget spent amount when expense is added
  static Future<bool> updateBudgetSpending({
    required String budgetId,
    required double amount,
    required bool isAdd, // true for add expense, false for remove expense
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email');
      if (email == null) {
        return false;
      }

      Map<String, dynamic>? updatedBudget;

      await _firestore.runTransaction((transaction) async {
        final budgetRef = _firestore.collection('budgets').doc(budgetId);
        final budgetDoc = await transaction.get(budgetRef);

        if (!budgetDoc.exists) {
          throw Exception('Budget not found');
        }

        final budgetData = budgetDoc.data() as Map<String, dynamic>;
        if (budgetData['email'] != email) {
          throw Exception('Unauthorized access');
        }

        double currentSpent = (budgetData['spent_amount'] ?? 0.0).toDouble();
        double newSpentAmount =
            isAdd ? currentSpent + amount : currentSpent - amount;

        // Ensure spent amount doesn't go below 0
        if (newSpentAmount < 0) {
          newSpentAmount = 0;
        }

        Map<String, dynamic> updateData = {
          'spent_amount': newSpentAmount,
          'updated_at': FieldValue.serverTimestamp(),
        };

        transaction.update(budgetRef, updateData);

        // Store updated budget data for notification check
        updatedBudget = Map<String, dynamic>.from(budgetData);
        updatedBudget!['spent_amount'] = newSpentAmount;
      });

      // Check for notifications after successful update
      if (updatedBudget != null && isAdd) {
        await _checkAndSendNotifications(updatedBudget!);
      }

      return true;
    } catch (e) {
      log('Error updating budget spending: $e');
      return false;
    }
  }

  /// Check and send notifications for budget limits
  static Future<void> _checkAndSendNotifications(
      Map<String, dynamic> budget) async {
    try {
      final enableNotifications =
          budget['enable_notifications'] as bool? ?? true;
      if (!enableNotifications) return;

      final budgetAmount = (budget['amount'] ?? 0.0).toDouble();
      final spentAmount = (budget['spent_amount'] ?? 0.0).toDouble();
      final alertPercentage = (budget['alert_percentage'] ?? 80.0).toDouble();
      final alertMessage =
          budget['alert_message'] as String? ?? "Budget limit reached!";
      final budgetName = budget['name'] as String;
      final budgetId = budget['budget_id'] as String;

      if (budgetAmount <= 0) return;

      final spendPercentage = (spentAmount / budgetAmount) * 100;
      final today = DateTime.now().toIso8601String().split('T')[0];

      // Check if budget is exceeded
      if (spentAmount >= budgetAmount) {
        final lastNotificationDate =
            budget['last_notification_date'] as String?;

        if (lastNotificationDate != today) {
          await BudgetNotificationService.showBudgetExceededNotification(
            categoryName: budgetName,
            spentAmount: spentAmount,
            budgetAmount: budgetAmount,
            alertMessage: alertMessage,
          );

          // Update last notification date
          await _firestore.collection('budgets').doc(budgetId).update({
            'last_notification_date': today,
          });
        }
      }
      // Check if approaching budget limit
      else if (spendPercentage >= alertPercentage) {
        final lastWarningDate = budget['last_warning_date'] as String?;

        if (lastWarningDate != today) {
          await BudgetNotificationService.showBudgetWarningNotification(
            categoryName: budgetName,
            spentAmount: spentAmount,
            budgetAmount: budgetAmount,
            warningPercentage: spendPercentage,
          );

          // Update last warning date
          await _firestore.collection('budgets').doc(budgetId).update({
            'last_warning_date': today,
          });
        }
      }
    } catch (e) {
      log('Error checking notifications: $e');
    }
  }

  /// Check all budgets and send notifications
  static Future<void> checkAllBudgetsForNotifications() async {
    try {
      final budgets = await getAllBudgets();
      for (final budget in budgets) {
        if (isBudgetActive(budget)) {
          await _checkAndSendNotifications(budget);
        }
      }
    } catch (e) {
      log('Error checking all budgets for notifications: $e');
    }
  }

  /// Delete budget (soft delete)
  static Future<bool> deleteBudget(String budgetId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email');
      if (email == null) {
        return false;
      }

      // Get budget data for cleanup
      final budgetDoc =
          await _firestore.collection('budgets').doc(budgetId).get();
      if (budgetDoc.exists) {
        final budgetData = budgetDoc.data() as Map<String, dynamic>;
        final budgetName = budgetData['name'] as String;

        // Cancel any pending notifications for this budget
        await BudgetNotificationService.cancelCategoryNotification(budgetName);
      }

      await _firestore.collection('budgets').doc(budgetId).update({
        'is_active': false,
        'updated_at': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      log('Error deleting budget: $e');
      return false;
    }
  }

  /// Check if budget is exceeded
  static bool isBudgetExceeded(Map<String, dynamic> budget) {
    double amount = (budget['amount'] ?? 0.0).toDouble();
    double spentAmount = (budget['spent_amount'] ?? 0.0).toDouble();
    return spentAmount > amount;
  }

  /// Get budget progress percentage
  static double getBudgetProgress(Map<String, dynamic> budget) {
    double amount = (budget['amount'] ?? 0.0).toDouble();
    double spentAmount = (budget['spent_amount'] ?? 0.0).toDouble();

    if (amount == 0) return 0.0;
    return (spentAmount / amount) * 100;
  }

  /// Get remaining budget amount
  static double getRemainingAmount(Map<String, dynamic> budget) {
    double amount = (budget['amount'] ?? 0.0).toDouble();
    double spentAmount = (budget['spent_amount'] ?? 0.0).toDouble();
    return amount - spentAmount;
  }

  /// Check if budget is still active (within date range)
  static bool isBudgetActive(Map<String, dynamic> budget) {
    try {
      final now = DateTime.now();
      final startDate = DateTime.parse(budget['start_date']);
      final endDate = DateTime.parse(budget['end_date']);

      return now.isAfter(startDate) &&
          now.isBefore(endDate.add(const Duration(days: 1)));
    } catch (e) {
      return false;
    }
  }

  /// Get active budgets only (within date range)
  static Future<List<Map<String, dynamic>>> getActiveBudgets() async {
    final allBudgets = await getAllBudgets();
    return allBudgets.where((budget) => isBudgetActive(budget)).toList();
  }

  /// Get budgets by category
  static Future<List<Map<String, dynamic>>> getBudgetsByCategory(
      String categoryId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email');
      if (email == null) {
        return [];
      }

      final snapshot = await _firestore
          .collection('budgets')
          .where('email', isEqualTo: email)
          .where('category_id', isEqualTo: categoryId)
          .where('is_active', isEqualTo: true)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      log('Error getting budgets by category: $e');
      return [];
    }
  }

  /// Get budget statistics
  static Map<String, dynamic> getBudgetStats(
      List<Map<String, dynamic>> budgets) {
    int totalBudgets = budgets.length;
    int exceededBudgets = 0;
    int warningBudgets = 0;
    double totalBudgetAmount = 0.0;
    double totalSpentAmount = 0.0;

    for (final budget in budgets) {
      if (isBudgetActive(budget)) {
        totalBudgetAmount += (budget['amount'] ?? 0.0).toDouble();
        totalSpentAmount += (budget['spent_amount'] ?? 0.0).toDouble();

        if (isBudgetExceeded(budget)) {
          exceededBudgets++;
        } else {
          final progress = getBudgetProgress(budget);
          final alertPercentage =
              (budget['alert_percentage'] ?? 80.0).toDouble();
          if (progress >= alertPercentage) {
            warningBudgets++;
          }
        }
      }
    }

    return {
      'total_budgets': totalBudgets,
      'exceeded_budgets': exceededBudgets,
      'warning_budgets': warningBudgets,
      'total_budget_amount': totalBudgetAmount,
      'total_spent_amount': totalSpentAmount,
      'overall_progress': totalBudgetAmount > 0
          ? (totalSpentAmount / totalBudgetAmount) * 100
          : 0.0,
    };
  }
}
