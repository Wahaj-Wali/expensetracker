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

        transaction.update(budgetRef, {
          'spent_amount': newSpentAmount,
          'updated_at': FieldValue.serverTimestamp(),
        });
      });

      return true;
    } catch (e) {
      log('Error updating budget spending: $e');
      return false;
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
}
