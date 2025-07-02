import 'package:ExpenseTracker/Services/BudgetNotificationService.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class BudgetController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Update spend amount for a specific budget by name
  Future<void> updateSpendAmount(double amount, String budgetName) async {
    try {
      // Retrieve email from shared preferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? email = prefs.getString('email');

      if (email == null) {
        debugPrint("Email not found in shared preferences.");
        return;
      }

      // Find the budget by name for the current user
      QuerySnapshot budgetSnapshot = await _firestore
          .collection('budgets')
          .where('email', isEqualTo: email)
          .where('budget_name', isEqualTo: budgetName)
          .where('is_active', isEqualTo: true)
          .limit(1)
          .get();

      if (budgetSnapshot.docs.isEmpty) {
        debugPrint("Budget not found: $budgetName");
        return;
      }

      DocumentReference budgetDoc = budgetSnapshot.docs.first.reference;
      DocumentSnapshot budgetDocSnapshot = await budgetDoc.get();
      var budgetData = budgetDocSnapshot.data() as Map<String, dynamic>;

      // Get current spend amount, defaulting to 0 if not present
      num currentSpend = budgetData['spend'] ?? 0;
      double updatedSpend = currentSpend.toDouble() + amount;

      // Update the spend field
      await budgetDoc.update({
        'spend': updatedSpend,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });

      debugPrint("Spend updated successfully for budget: $budgetName");

      // Check for budget alerts after updating spend
      await _checkBudgetAlerts(budgetData, updatedSpend, budgetName);
    } catch (e) {
      debugPrint("Error updating spend amount: $e");
    }
  }

  /// Check if budget alerts should be triggered
  Future<void> _checkBudgetAlerts(Map<String, dynamic> budgetData,
      double newSpendAmount, String budgetName) async {
    try {
      final balance = (budgetData['budget_limit'] as num?)?.toDouble() ?? 0.0;
      final isAlert = budgetData['is_alert'] as bool? ?? false;
      final alertPercentage =
          (budgetData['alert_percentage'] as num?)?.toDouble() ?? 80.0;
      final alertMessage = budgetData['alert_msg'] as String? ??
          "You've exceeded your budget limit!";

      // Skip if no budget is set or alerts are disabled
      if (balance <= 0 || !isAlert) return;

      final spendPercentage = (newSpendAmount / balance) * 100;

      if (newSpendAmount >= balance) {
        await BudgetNotificationService.showBudgetExceededNotification(
          categoryName: budgetName,
          spentAmount: newSpendAmount,
          budgetAmount: balance,
          alertMessage: alertMessage,
        );

        // Mark budget as reached
        await _markBudgetAsReached(budgetName, true);
      }
      // Check if approaching budget limit
      else if (spendPercentage >= alertPercentage) {
        await BudgetNotificationService.showBudgetWarningNotification(
          categoryName: budgetName,
          spentAmount: newSpendAmount,
          budgetAmount: balance,
          warningPercentage: spendPercentage,
        );
      }

      debugPrint(
          "Budget check completed for $budgetName: ${spendPercentage.toStringAsFixed(1)}% used");
    } catch (e) {
      debugPrint("Error checking budget alerts: $e");
    }
  }

  /// Mark budget as reached or not reached
  Future<void> _markBudgetAsReached(String budgetName, bool isReached) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? email = prefs.getString('email');

      if (email == null) return;

      QuerySnapshot budgetSnapshot = await _firestore
          .collection('budgets')
          .where('email', isEqualTo: email)
          .where('budget_name', isEqualTo: budgetName)
          .where('is_active', isEqualTo: true)
          .limit(1)
          .get();

      if (budgetSnapshot.docs.isNotEmpty) {
        await budgetSnapshot.docs.first.reference.update({
          'is_reached': isReached,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint("Error marking budget as reached: $e");
    }
  }

  /// Create a new budget
  Future<bool> createBudget({
    required String budgetName,
    required double budgetLimit,
    required String period, // 'monthly', 'weekly', 'yearly'
    String? description,
    bool isAlert = true,
    double alertPercentage = 80.0,
    String? alertMessage,
  }) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? email = prefs.getString('email');

      if (email == null) {
        debugPrint("Email not found in shared preferences.");
        return false;
      }

      // Check if budget with same name already exists
      QuerySnapshot existingBudget = await _firestore
          .collection('budgets')
          .where('email', isEqualTo: email)
          .where('budget_name', isEqualTo: budgetName)
          .where('is_active', isEqualTo: true)
          .limit(1)
          .get();

      if (existingBudget.docs.isNotEmpty) {
        debugPrint("Budget with name '$budgetName' already exists");
        return false;
      }

      var uuid = const Uuid();
      String budgetId = uuid.v4();

      await _firestore.collection('budgets').doc(budgetId).set({
        'budget_id': budgetId,
        'budget_name': budgetName,
        'description': description ?? '',
        'budget_limit': budgetLimit,
        'spend': 0.0,
        'period': period,
        'is_alert': isAlert,
        'alert_percentage': alertPercentage,
        'alert_msg': alertMessage ?? "You've exceeded your budget limit!",
        'is_reached': false,
        'is_active': true,
        'email': email,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        'current_month': DateTime.now().month,
        'current_year': DateTime.now().year,
      });

      debugPrint("Budget '$budgetName' created successfully");
      return true;
    } catch (e) {
      debugPrint("Error creating budget: $e");
      return false;
    }
  }

  /// Get budget information for a specific budget name
  Future<Map<String, dynamic>?> getBudgetByName(String budgetName) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? email = prefs.getString('email');

      if (email == null) {
        debugPrint("Email not found in shared preferences.");
        return null;
      }

      QuerySnapshot budgetSnapshot = await _firestore
          .collection('budgets')
          .where('email', isEqualTo: email)
          .where('budget_name', isEqualTo: budgetName)
          .where('is_active', isEqualTo: true)
          .limit(1)
          .get();

      if (budgetSnapshot.docs.isNotEmpty) {
        var doc = budgetSnapshot.docs.first;
        var data = doc.data() as Map<String, dynamic>;

        return {
          'id': doc.id,
          'budget_id': data['budget_id'],
          'budget_name': data['budget_name'],
          'description': data['description'] ?? '',
          'budget_limit': data['budget_limit'],
          'spend': data['spend'] ?? 0,
          'period': data['period'],
          'current_month': data['current_month'],
          'current_year': data['current_year'],
          'is_alert': data['is_alert'] ?? false,
          'alert_percentage': data['alert_percentage'],
          'alert_msg': data['alert_msg'],
          'is_reached': data['is_reached'] ?? false,
          'created_at': data['created_at'],
          'updated_at': data['updated_at'],
        };
      }

      return null;
    } catch (e) {
      debugPrint("Error getting budget by name: $e");
      return null;
    }
  }

  /// Get all budgets for current user
  Future<List<Map<String, dynamic>>> getAllBudgets() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? email = prefs.getString('email');

      if (email == null) {
        debugPrint("Email not found in shared preferences.");
        return [];
      }

      QuerySnapshot budgetsSnapshot = await _firestore
          .collection('budgets')
          .where('email', isEqualTo: email)
          .where('is_active', isEqualTo: true)
          .orderBy('budget_name')
          .get();

      List<Map<String, dynamic>> budgets = [];

      for (var doc in budgetsSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        budgets.add({
          'id': doc.id,
          'budget_id': data['budget_id'],
          'budget_name': data['budget_name'],
          'description': data['description'] ?? '',
          'budget_limit': data['budget_limit'],
          'spend': data['spend'] ?? 0,
          'period': data['period'],
          'current_month': data['current_month'],
          'current_year': data['current_year'],
          'is_alert': data['is_alert'] ?? false,
          'alert_percentage': data['alert_percentage'],
          'alert_msg': data['alert_msg'],
          'is_reached': data['is_reached'] ?? false,
          'created_at': data['created_at'],
          'updated_at': data['updated_at'],
        });
      }

      return budgets;
    } catch (e) {
      debugPrint("Error getting all budgets: $e");
      return [];
    }
  }

  /// Update budget
  Future<bool> updateBudget({
    required String budgetName,
    String? newBudgetName,
    double? budgetLimit,
    String? period,
    String? description,
    bool? isAlert,
    double? alertPercentage,
    String? alertMessage,
  }) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? email = prefs.getString('email');

      if (email == null) {
        debugPrint("Email not found in shared preferences.");
        return false;
      }

      QuerySnapshot budgetSnapshot = await _firestore
          .collection('budgets')
          .where('email', isEqualTo: email)
          .where('budget_name', isEqualTo: budgetName)
          .where('is_active', isEqualTo: true)
          .limit(1)
          .get();

      if (budgetSnapshot.docs.isEmpty) {
        debugPrint("Budget not found: $budgetName");
        return false;
      }

      // Check if new name already exists (if changing name)
      if (newBudgetName != null && newBudgetName != budgetName) {
        QuerySnapshot existingBudget = await _firestore
            .collection('budgets')
            .where('email', isEqualTo: email)
            .where('budget_name', isEqualTo: newBudgetName)
            .where('is_active', isEqualTo: true)
            .limit(1)
            .get();

        if (existingBudget.docs.isNotEmpty) {
          debugPrint("Budget with name '$newBudgetName' already exists");
          return false;
        }
      }

      // Prepare update data
      Map<String, dynamic> updateData = {
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      if (newBudgetName != null) updateData['budget_name'] = newBudgetName;
      if (budgetLimit != null) updateData['budget_limit'] = budgetLimit;
      if (period != null) updateData['period'] = period;
      if (description != null) updateData['description'] = description;
      if (isAlert != null) updateData['is_alert'] = isAlert;
      if (alertPercentage != null)
        updateData['alert_percentage'] = alertPercentage;
      if (alertMessage != null) updateData['alert_msg'] = alertMessage;

      await budgetSnapshot.docs.first.reference.update(updateData);

      debugPrint("Budget '$budgetName' updated successfully");
      return true;
    } catch (e) {
      debugPrint("Error updating budget: $e");
      return false;
    }
  }

  /// Delete budget (soft delete)
  Future<bool> deleteBudget(String budgetName) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? email = prefs.getString('email');

      if (email == null) {
        debugPrint("Email not found in shared preferences.");
        return false;
      }

      QuerySnapshot budgetSnapshot = await _firestore
          .collection('budgets')
          .where('email', isEqualTo: email)
          .where('budget_name', isEqualTo: budgetName)
          .where('is_active', isEqualTo: true)
          .limit(1)
          .get();

      if (budgetSnapshot.docs.isEmpty) {
        debugPrint("Budget not found: $budgetName");
        return false;
      }

      await budgetSnapshot.docs.first.reference.update({
        'is_active': false,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });

      debugPrint("Budget '$budgetName' deleted successfully");
      return true;
    } catch (e) {
      debugPrint("Error deleting budget: $e");
      return false;
    }
  }

  /// Check if a budget has exceeded its limit
  Future<bool> isBudgetExceeded(String budgetName) async {
    try {
      var budgetInfo = await getBudgetByName(budgetName);
      if (budgetInfo == null) {
        return false;
      }

      double budgetLimit = budgetInfo['budget_limit']?.toDouble() ?? 0;
      double spend = budgetInfo['spend']?.toDouble() ?? 0;

      return spend >= budgetLimit;
    } catch (e) {
      debugPrint("Error checking if budget exceeded: $e");
      return false;
    }
  }

  /// Get budget progress for a budget (0.0 to 1.0)
  Future<double> getBudgetProgress(String budgetName) async {
    try {
      var budgetInfo = await getBudgetByName(budgetName);
      if (budgetInfo == null) {
        return 0.0;
      }

      double budgetLimit = budgetInfo['budget_limit']?.toDouble() ?? 0;
      double spend = budgetInfo['spend']?.toDouble() ?? 0;

      if (budgetLimit <= 0) return 0.0;

      double progress = spend / budgetLimit;
      return progress > 1.0 ? 1.0 : progress;
    } catch (e) {
      debugPrint("Error getting budget progress: $e");
      return 0.0;
    }
  }

  /// Reset budget spend to zero (useful for new periods)
  Future<bool> resetBudgetSpend(String budgetName) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? email = prefs.getString('email');

      if (email == null) {
        debugPrint("Email not found in shared preferences.");
        return false;
      }

      QuerySnapshot budgetSnapshot = await _firestore
          .collection('budgets')
          .where('email', isEqualTo: email)
          .where('budget_name', isEqualTo: budgetName)
          .where('is_active', isEqualTo: true)
          .limit(1)
          .get();

      if (budgetSnapshot.docs.isEmpty) {
        debugPrint("Budget not found: $budgetName");
        return false;
      }

      await budgetSnapshot.docs.first.reference.update({
        'spend': 0.0,
        'is_reached': false,
        'current_month': DateTime.now().month,
        'current_year': DateTime.now().year,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });

      debugPrint("Budget spend reset for '$budgetName'");
      return true;
    } catch (e) {
      debugPrint("Error resetting budget spend: $e");
      return false;
    }
  }

  /// Get budgets by period
  Future<List<Map<String, dynamic>>> getBudgetsByPeriod(String period) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? email = prefs.getString('email');

      if (email == null) {
        debugPrint("Email not found in shared preferences.");
        return [];
      }

      QuerySnapshot budgetsSnapshot = await _firestore
          .collection('budgets')
          .where('email', isEqualTo: email)
          .where('period', isEqualTo: period)
          .where('is_active', isEqualTo: true)
          .orderBy('budget_name')
          .get();

      List<Map<String, dynamic>> budgets = [];

      for (var doc in budgetsSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        budgets.add({
          'id': doc.id,
          'budget_id': data['budget_id'],
          'budget_name': data['budget_name'],
          'description': data['description'] ?? '',
          'budget_limit': data['budget_limit'],
          'spend': data['spend'] ?? 0,
          'period': data['period'],
          'current_month': data['current_month'],
          'current_year': data['current_year'],
          'is_alert': data['is_alert'] ?? false,
          'alert_percentage': data['alert_percentage'],
          'alert_msg': data['alert_msg'],
          'is_reached': data['is_reached'] ?? false,
          'created_at': data['created_at'],
          'updated_at': data['updated_at'],
        });
      }

      return budgets;
    } catch (e) {
      debugPrint("Error getting budgets by period: $e");
      return [];
    }
  }

  /// Manual check for all budget alerts
  Future<void> checkAllBudgetAlerts() async {
    try {
      List<Map<String, dynamic>> allBudgets = await getAllBudgets();

      for (var budget in allBudgets) {
        await _checkBudgetAlerts(
            budget, budget['spend']?.toDouble() ?? 0.0, budget['budget_name']);
      }

      debugPrint(
          "Manual budget alert check completed for ${allBudgets.length} budgets");
    } catch (e) {
      debugPrint("Error in manual budget alert check: $e");
    }
  }

  /// Get budget summary statistics
  Future<Map<String, dynamic>> getBudgetSummary() async {
    try {
      List<Map<String, dynamic>> allBudgets = await getAllBudgets();

      int totalBudgets = allBudgets.length;
      int exceededBudgets = 0;
      int warningBudgets = 0;
      double totalBudgetLimit = 0;
      double totalSpent = 0;

      for (var budget in allBudgets) {
        double budgetLimit = budget['budget_limit']?.toDouble() ?? 0;
        double spend = budget['spend']?.toDouble() ?? 0;
        double alertPercentage = budget['alert_percentage']?.toDouble() ?? 80;

        totalBudgetLimit += budgetLimit;
        totalSpent += spend;

        if (spend >= budgetLimit) {
          exceededBudgets++;
        } else if ((spend / budgetLimit) * 100 >= alertPercentage) {
          warningBudgets++;
        }
      }

      return {
        'total_budgets': totalBudgets,
        'exceeded_budgets': exceededBudgets,
        'warning_budgets': warningBudgets,
        'total_budget_limit': totalBudgetLimit,
        'total_spent': totalSpent,
        'remaining_budget': totalBudgetLimit - totalSpent,
        'overall_progress':
            totalBudgetLimit > 0 ? (totalSpent / totalBudgetLimit) : 0.0,
      };
    } catch (e) {
      debugPrint("Error getting budget summary: $e");
      return {
        'total_budgets': 0,
        'exceeded_budgets': 0,
        'warning_budgets': 0,
        'total_budget_limit': 0.0,
        'total_spent': 0.0,
        'remaining_budget': 0.0,
        'overall_progress': 0.0,
      };
    }
  }

  /// Get available budget periods
  List<String> getBudgetPeriods() {
    return ['monthly', 'weekly', 'yearly', 'custom'];
  }
}
