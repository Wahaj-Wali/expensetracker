import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer';

class DefaultCategoriesService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Default categories configuration
  static final List<Map<String, dynamic>> _defaultCategories = [
    {
      'iconName': 'Restaurant',
      'iconColor': '#FF5722',
      'name': 'Food & Dining',
    },
    {
      'iconName': 'Car',
      'iconColor': '#2196F3',
      'name': 'Transportation',
    },
    {
      'iconName': 'Groceries',
      'iconColor': '#4CAF50',
      'name': 'Groceries',
    },
    {
      'iconName': 'Movie',
      'iconColor': '#9C27B0',
      'name': 'Entertainment',
    },
    {
      'iconName': 'Rent',
      'iconColor': '#FF9800',
      'name': 'Housing',
    },
    {
      'iconName': 'Hospital',
      'iconColor': '#F44336',
      'name': 'Healthcare',
    },
    {
      'iconName': 'Gym',
      'iconColor': '#00BCD4',
      'name': 'Fitness',
    },
    {
      'iconName': 'Clothing',
      'iconColor': '#E91E63',
      'name': 'Shopping',
    },
    {
      'iconName': 'Plumbing',
      'iconColor': '#607D8B',
      'name': 'Utilities',
    },
    {
      'iconName': 'Cake',
      'iconColor': '#FFC107',
      'name': 'Gifts & Treats',
    },
  ];

  /// Creates default categories as global categories (prevents duplicates)
  static Future<bool> createGlobalDefaultCategories() async {
    try {
      // Check if global categories already exist
      final existingSnapshot =
          await _firestore.collection('global_categories').get();

      if (existingSnapshot.docs.isNotEmpty) {
        log("Global categories already exist (${existingSnapshot.docs.length} categories). Skipping creation.");
        return true;
      }

      // Create batch write for better performance
      WriteBatch batch = _firestore.batch();

      for (var category in _defaultCategories) {
        DocumentReference categoryRef =
            _firestore.collection('global_categories').doc();
        batch.set(categoryRef, {
          ...category,
          'created_at': FieldValue.serverTimestamp(),
          'is_default': true,
          'salesTaxApplicable': true,
          'salesTaxPercentage': 18.0,
        });
      }

      await batch.commit();
      log("Successfully created ${_defaultCategories.length} global default categories");
      return true;
    } catch (e) {
      log("Error creating global default categories: $e");
      return false;
    }
  }

  /// Gets all categories (ONLY global categories - no user-specific categories)
  static Future<List<Map<String, dynamic>>> getAllCategories(
      String email) async {
    try {
      List<Map<String, dynamic>> allCategories = [];

      // Get ONLY global categories
      final globalCategoriesSnapshot = await _firestore
          .collection('global_categories')
          .orderBy('name') // Sort alphabetically
          .get();

      for (var doc in globalCategoriesSnapshot.docs) {
        allCategories.add({
          'id': doc.id,
          'iconName': doc['iconName'] ?? 'Restaurant',
          'iconColor': doc['iconColor'] ?? '#FF5722',
          'name': doc['name'] ?? 'Unknown',
          'is_default': doc['is_default'] ?? true,
          'is_global': true,
          'salesTaxApplicable': doc['salesTaxApplicable'] ?? true,
          'salesTaxPercentage': doc['salesTaxPercentage'] ?? 18.0,
        });
      }

      log("Retrieved ${allCategories.length} global categories for user: $email");
      return allCategories;
    } catch (e) {
      log("Error getting all categories: $e");
      return [];
    }
  }

  /// Get a specific category by ID (global only)
  static Future<Map<String, dynamic>?> getCategoryById(
      String categoryId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('global_categories')
          .doc(categoryId)
          .get();

      if (doc.exists) {
        return {
          'id': doc.id,
          'iconName': doc['iconName'] ?? 'Restaurant',
          'iconColor': doc['iconColor'] ?? '#FF5722',
          'name': doc['name'] ?? 'Unknown',
          'is_default': doc['is_default'] ?? true,
          'is_global': true,
          'salesTaxApplicable': doc['salesTaxApplicable'] ?? true,
          'salesTaxPercentage': doc['salesTaxPercentage'] ?? 18.0,
        };
      }
      return null;
    } catch (e) {
      log("Error getting category by ID: $e");
      return null;
    }
  }

  /// Get category by name (global only)
  static Future<Map<String, dynamic>?> getCategoryByName(
      String categoryName) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('global_categories')
          .where('name', isEqualTo: categoryName)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        var doc = snapshot.docs.first;
        return {
          'id': doc.id,
          'iconName': doc['iconName'] ?? 'Restaurant',
          'iconColor': doc['iconColor'] ?? '#FF5722',
          'name': doc['name'] ?? 'Unknown',
          'is_default': doc['is_default'] ?? true,
          'is_global': true,
          'salesTaxApplicable': doc['salesTaxApplicable'] ?? true,
          'salesTaxPercentage': doc['salesTaxPercentage'] ?? 18.0,
        };
      }
      return null;
    } catch (e) {
      log("Error getting category by name: $e");
      return null;
    }
  }

  /// Add a new global category (Admin only)
  static Future<bool> addGlobalCategory({
    required String iconName,
    required String iconColor,
    required String name,
    bool salesTaxApplicable = true,
    double salesTaxPercentage = 18.0,
  }) async {
    try {
      // Check if category with same name already exists
      QuerySnapshot existingSnapshot = await _firestore
          .collection('global_categories')
          .where('name', isEqualTo: name)
          .limit(1)
          .get();

      if (existingSnapshot.docs.isNotEmpty) {
        log("Category '$name' already exists");
        return false;
      }

      // Add new global category
      await _firestore.collection('global_categories').add({
        'iconName': iconName,
        'iconColor': iconColor,
        'name': name,
        'is_default': false, // Custom added category
        'salesTaxApplicable': salesTaxApplicable,
        'salesTaxPercentage': salesTaxPercentage,
        'created_at': FieldValue.serverTimestamp(),
      });

      log("Global category '$name' added successfully");
      return true;
    } catch (e) {
      log("Error adding global category: $e");
      return false;
    }
  }

  /// Update a global category (Admin only)
  static Future<bool> updateGlobalCategory({
    required String categoryId,
    String? iconName,
    String? iconColor,
    String? name,
    bool? salesTaxApplicable,
    double? salesTaxPercentage,
  }) async {
    try {
      Map<String, dynamic> updateData = {
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (iconName != null) updateData['iconName'] = iconName;
      if (iconColor != null) updateData['iconColor'] = iconColor;
      if (name != null) updateData['name'] = name;
      if (salesTaxApplicable != null)
        updateData['salesTaxApplicable'] = salesTaxApplicable;
      if (salesTaxPercentage != null)
        updateData['salesTaxPercentage'] = salesTaxPercentage;

      await _firestore
          .collection('global_categories')
          .doc(categoryId)
          .update(updateData);

      log("Global category updated successfully");
      return true;
    } catch (e) {
      log("Error updating global category: $e");
      return false;
    }
  }

  /// Delete a global category (Admin only)
  static Future<bool> deleteGlobalCategory(String categoryId) async {
    try {
      await _firestore.collection('global_categories').doc(categoryId).delete();

      log("Global category deleted successfully");
      return true;
    } catch (e) {
      log("Error deleting global category: $e");
      return false;
    }
  }

  /// DEPRECATED METHODS - These are kept for backward compatibility but do nothing
  @deprecated
  static Future<bool> createDefaultCategories(String email) async {
    log("createDefaultCategories is deprecated. All categories are now global.");
    return true;
  }

  @deprecated
  static Future<bool> resetToDefaultCategories(String email) async {
    log("resetToDefaultCategories is deprecated. All categories are now global.");
    return true;
  }

  @deprecated
  static Future<bool> userHasCustomCategories(String email) async {
    log("userHasCustomCategories is deprecated. All categories are now global.");
    return false;
  }

  @deprecated
  static Future<int> getCustomCategoryCount(String email) async {
    log("getCustomCategoryCount is deprecated. All categories are now global.");
    return 0;
  }

  /// Gets the total count of categories (global only)
  static Future<int> getTotalCategoryCount(String email) async {
    try {
      final snapshot = await _firestore.collection('global_categories').get();
      return snapshot.docs.length;
    } catch (e) {
      log("Error getting total category count: $e");
      return 0;
    }
  }

  /// Checks if global categories exist
  static Future<bool> globalCategoriesExist() async {
    try {
      final snapshot =
          await _firestore.collection('global_categories').limit(1).get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      log("Error checking if global categories exist: $e");
      return false;
    }
  }

  /// Gets the count of global categories
  static Future<int> getGlobalCategoryCount() async {
    try {
      final snapshot = await _firestore.collection('global_categories').get();
      return snapshot.docs.length;
    } catch (e) {
      log("Error getting global category count: $e");
      return 0;
    }
  }

  /// Gets the list of default categories configuration
  static List<Map<String, dynamic>> getDefaultCategories() {
    return List.from(_defaultCategories);
  }

  /// Adds a default category to the configuration (for development use)
  static void addDefaultCategory({
    required String iconName,
    required String iconColor,
    required String name,
  }) {
    _defaultCategories.add({
      'iconName': iconName,
      'iconColor': iconColor,
      'name': name,
    });
  }

  /// Removes a default category from the configuration (for development use)
  static void removeDefaultCategory(String name) {
    _defaultCategories.removeWhere((category) => category['name'] == name);
  }

  /// Clean up any existing user-specific categories (Admin utility)
  /// This will move all user categories to global or delete them
  static Future<bool> cleanupUserCategories() async {
    try {
      // Get all user-specific categories
      final userCategoriesSnapshot =
          await _firestore.collection('categories').get();

      if (userCategoriesSnapshot.docs.isEmpty) {
        log("No user-specific categories found to cleanup");
        return true;
      }

      // Delete all user-specific categories since we only want global ones
      WriteBatch batch = _firestore.batch();

      for (var doc in userCategoriesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      log("Cleaned up ${userCategoriesSnapshot.docs.length} user-specific categories");
      return true;
    } catch (e) {
      log("Error cleaning up user categories: $e");
      return false;
    }
  }
}
