import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> updateSpendAmount(double amount, String categoryName) async {
    try {
      // Retrieve email from shared preferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? email = prefs.getString('email');

      if (email == null) {
        debugPrint("Email not found in shared preferences.");
        return; // Exit if email is not found
      }

      // First, try to find the category in user-specific categories
      QuerySnapshot userCategorySnapshot = await _firestore
          .collection('categories')
          .where('email', isEqualTo: email)
          .where('name', isEqualTo: categoryName)
          .limit(1)
          .get();

      DocumentReference? categoryDoc;
      bool isUserCategory = false;

      if (userCategorySnapshot.docs.isNotEmpty) {
        // Found in user-specific categories
        categoryDoc = userCategorySnapshot.docs.first.reference;
        isUserCategory = true;
      } else {
        // Check if it's a global category and create a user-specific budget entry
        QuerySnapshot globalCategorySnapshot = await _firestore
            .collection('global_categories')
            .where('name', isEqualTo: categoryName)
            .limit(1)
            .get();

        if (globalCategorySnapshot.docs.isNotEmpty) {
          // Create a user-specific category entry for budget tracking
          var globalCategoryData =
              globalCategorySnapshot.docs.first.data() as Map<String, dynamic>;

          // Create new user category document for budget tracking
          DocumentReference newCategoryDoc =
              _firestore.collection('categories').doc();

          await newCategoryDoc.set({
            'email': email,
            'name': categoryName,
            'iconName': globalCategoryData['iconName'],
            'iconColor': globalCategoryData['iconColor'],
            'is_default': globalCategoryData['is_default'] ?? true,
            'salesTaxApplicable':
                globalCategoryData['salesTaxApplicable'] ?? true,
            'salesTaxPercentage':
                globalCategoryData['salesTaxPercentage'] ?? 18.0,
            'spend': amount, // Initialize with the current spend amount
            'created_at': FieldValue.serverTimestamp(),
          });

          debugPrint(
              "Created user-specific category for budget tracking: $categoryName");
          return;
        } else {
          debugPrint(
              "Category not found in both user and global categories: $categoryName");
          return;
        }
      }

      // Update the spend amount for existing user category
      if (categoryDoc != null) {
        // Retrieve document snapshot
        DocumentSnapshot categorySnapshot = await categoryDoc.get();
        var categoryData = categorySnapshot.data() as Map<String, dynamic>?;

        if (categoryData == null) {
          debugPrint("Category data not found.");
          return;
        }

        // Get current spend amount, defaulting to 0 if not present
        num currentSpend = categoryData['spend'] ?? 0;
        double updatedSpend = currentSpend.toDouble() + amount;

        // Update the spend field
        await categoryDoc.update({'spend': updatedSpend});

        debugPrint(
            "Spend updated successfully for ${isUserCategory ? 'user' : 'global'} category: $categoryName");
      }
    } catch (e) {
      debugPrint("Error updating spend amount: $e");
    }
  }

  /// Get budget information for a specific category
  Future<Map<String, dynamic>?> getCategoryBudget(String categoryName) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? email = prefs.getString('email');

      if (email == null) {
        debugPrint("Email not found in shared preferences.");
        return null;
      }

      // Check user-specific categories first
      QuerySnapshot userCategorySnapshot = await _firestore
          .collection('categories')
          .where('email', isEqualTo: email)
          .where('name', isEqualTo: categoryName)
          .limit(1)
          .get();

      if (userCategorySnapshot.docs.isNotEmpty) {
        var doc = userCategorySnapshot.docs.first;
        var data = doc.data() as Map<String, dynamic>;

        return {
          'id': doc.id,
          'name': data['name'],
          'iconName': data['iconName'],
          'iconColor': data['iconColor'],
          'balance': data['balance'],
          'spend': data['spend'] ?? 0,
          'current_month': data['current_month'],
          'is_alert': data['is_alert'] ?? false,
          'alert_percentage': data['alert_percentage'],
          'alert_msg': data['alert_msg'],
          'is_reached': data['is_reached'] ?? false,
          'has_budget': data.containsKey('balance'), // Check if budget is set
        };
      }

      // If not found in user categories, check global categories
      QuerySnapshot globalCategorySnapshot = await _firestore
          .collection('global_categories')
          .where('name', isEqualTo: categoryName)
          .limit(1)
          .get();

      if (globalCategorySnapshot.docs.isNotEmpty) {
        var doc = globalCategorySnapshot.docs.first;
        var data = doc.data() as Map<String, dynamic>;

        return {
          'id': doc.id,
          'name': data['name'],
          'iconName': data['iconName'],
          'iconColor': data['iconColor'],
          'balance': null, // No budget set for global categories
          'spend': 0,
          'current_month': null,
          'is_alert': false,
          'alert_percentage': null,
          'alert_msg': null,
          'is_reached': false,
          'has_budget':
              false, // Global categories don't have budgets by default
        };
      }

      return null;
    } catch (e) {
      debugPrint("Error getting category budget: $e");
      return null;
    }
  }

  /// Get all categories with budget information
  Future<List<Map<String, dynamic>>> getAllCategoriesWithBudgets() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? email = prefs.getString('email');

      if (email == null) {
        debugPrint("Email not found in shared preferences.");
        return [];
      }

      List<Map<String, dynamic>> allCategories = [];

      // Get user-specific categories
      QuerySnapshot userCategoriesSnapshot = await _firestore
          .collection('categories')
          .where('email', isEqualTo: email)
          .get();

      Set<String> userCategoryNames = {};

      for (var doc in userCategoriesSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        userCategoryNames.add(data['name']);

        allCategories.add({
          'id': doc.id,
          'name': data['name'],
          'iconName': data['iconName'],
          'iconColor': data['iconColor'],
          'balance': data['balance'],
          'spend': data['spend'] ?? 0,
          'current_month': data['current_month'],
          'is_alert': data['is_alert'] ?? false,
          'alert_percentage': data['alert_percentage'],
          'alert_msg': data['alert_msg'],
          'is_reached': data['is_reached'] ?? false,
          'has_budget': data.containsKey('balance'),
          'is_global': false,
        });
      }

      // Get global categories that are not overridden by user categories
      QuerySnapshot globalCategoriesSnapshot =
          await _firestore.collection('global_categories').get();

      for (var doc in globalCategoriesSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        String categoryName = data['name'];

        // Only add if not already present in user categories
        if (!userCategoryNames.contains(categoryName)) {
          allCategories.add({
            'id': doc.id,
            'name': categoryName,
            'iconName': data['iconName'],
            'iconColor': data['iconColor'],
            'balance': null,
            'spend': 0,
            'current_month': null,
            'is_alert': false,
            'alert_percentage': null,
            'alert_msg': null,
            'is_reached': false,
            'has_budget': false,
            'is_global': true,
          });
        }
      }

      return allCategories;
    } catch (e) {
      debugPrint("Error getting all categories with budgets: $e");
      return [];
    }
  }

  /// Check if a category has exceeded its budget
  Future<bool> isBudgetExceeded(String categoryName) async {
    try {
      var budgetInfo = await getCategoryBudget(categoryName);
      if (budgetInfo == null || !budgetInfo['has_budget']) {
        return false;
      }

      double balance = budgetInfo['balance']?.toDouble() ?? 0;
      double spend = budgetInfo['spend']?.toDouble() ?? 0;

      return spend >= balance;
    } catch (e) {
      debugPrint("Error checking if budget exceeded: $e");
      return false;
    }
  }

  /// Get budget progress for a category (0.0 to 1.0)
  Future<double> getBudgetProgress(String categoryName) async {
    try {
      var budgetInfo = await getCategoryBudget(categoryName);
      if (budgetInfo == null || !budgetInfo['has_budget']) {
        return 0.0;
      }

      double balance = budgetInfo['balance']?.toDouble() ?? 0;
      double spend = budgetInfo['spend']?.toDouble() ?? 0;

      if (balance <= 0) return 0.0;

      double progress = spend / balance;
      return progress > 1.0 ? 1.0 : progress;
    } catch (e) {
      debugPrint("Error getting budget progress: $e");
      return 0.0;
    }
  }
}
