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

  /// Creates default categories as global categories (not user-specific)
  /// This should be called once during app initialization or admin setup
  static Future<bool> createGlobalDefaultCategories() async {
    try {
      // Check if global default categories already exist
      final existingCategories =
          await _firestore.collection('global_categories').limit(1).get();

      // If global categories already exist, don't create defaults
      if (existingCategories.docs.isNotEmpty) {
        log("Global default categories already exist, skipping creation");
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
          'is_default': true, // Mark as default category
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

  /// Gets all categories (both global defaults and user-created ones)
  /// [email] - The user's email address
  static Future<List<Map<String, dynamic>>> getAllCategories(
      String email) async {
    try {
      List<Map<String, dynamic>> allCategories = [];

      // Get global default categories
      final globalCategoriesSnapshot =
          await _firestore.collection('global_categories').get();

      for (var doc in globalCategoriesSnapshot.docs) {
        allCategories.add({
          'id': doc.id,
          'iconName': doc['iconName'],
          'iconColor': doc['iconColor'],
          'name': doc['name'],
          'is_default': doc['is_default'] ?? true,
          'is_global': true, // Mark as global category
          'salesTaxApplicable': true, // Default tax settings
          'salesTaxPercentage': 18.0,
        });
      }

      // Get user-specific categories
      final userCategoriesSnapshot = await _firestore
          .collection('categories')
          .where('email', isEqualTo: email)
          .get();

      for (var doc in userCategoriesSnapshot.docs) {
        allCategories.add({
          'id': doc.id,
          'iconName': doc['iconName'],
          'iconColor': doc['iconColor'],
          'name': doc['name'],
          'is_default': doc.data().toString().contains('is_default')
              ? doc['is_default']
              : false,
          'is_global': false, // Mark as user category
          'salesTaxApplicable':
              doc.data().toString().contains('salesTaxApplicable')
                  ? doc['salesTaxApplicable']
                  : true,
          'salesTaxPercentage':
              doc.data().toString().contains('salesTaxPercentage')
                  ? doc['salesTaxPercentage']
                  : 18.0,
        });
      }

      return allCategories;
    } catch (e) {
      log("Error getting all categories: $e");
      return [];
    }
  }

  /// Creates default categories for a new user (DEPRECATED - use createGlobalDefaultCategories instead)
  /// This method is kept for backward compatibility but does nothing
  @deprecated
  static Future<bool> createDefaultCategories(String email) async {
    log("createDefaultCategories is deprecated. Use createGlobalDefaultCategories instead.");
    return true;
  }

  /// Adds a new default category to the configuration
  ///
  /// [iconName] - The name of the icon
  /// [iconColor] - The hex color string (e.g., '#FF5722')
  /// [name] - The category name
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

  /// Removes a default category from the configuration
  ///
  /// [name] - The category name to remove
  static void removeDefaultCategory(String name) {
    _defaultCategories.removeWhere((category) => category['name'] == name);
  }

  /// Gets the list of default categories
  static List<Map<String, dynamic>> getDefaultCategories() {
    return List.from(_defaultCategories);
  }

  /// Resets a user's categories to defaults (removes all existing and creates defaults)
  /// Use with caution - this will delete all user's custom categories
  ///
  /// [email] - The user's email address
  /// Returns true if successful, false otherwise
  static Future<bool> resetToDefaultCategories(String email) async {
    try {
      // Delete all existing user categories
      final existingCategories = await _firestore
          .collection('categories')
          .where('email', isEqualTo: email)
          .get();

      WriteBatch deleteBatch = _firestore.batch();
      for (var doc in existingCategories.docs) {
        deleteBatch.delete(doc.reference);
      }
      await deleteBatch.commit();

      // Note: We don't create new categories here since they're now global
      log("User categories reset. Global categories will be available automatically.");
      return true;
    } catch (e) {
      log("Error resetting categories to defaults for $email: $e");
      return false;
    }
  }

  /// Checks if a user has any custom categories (not including global ones)
  ///
  /// [email] - The user's email address
  /// Returns true if user has custom categories, false otherwise
  static Future<bool> userHasCustomCategories(String email) async {
    try {
      final snapshot = await _firestore
          .collection('categories')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      log("Error checking if user has custom categories: $e");
      return false;
    }
  }

  /// Gets the count of custom categories for a user (not including global ones)
  ///
  /// [email] - The user's email address
  /// Returns the number of custom categories
  static Future<int> getCustomCategoryCount(String email) async {
    try {
      final snapshot = await _firestore
          .collection('categories')
          .where('email', isEqualTo: email)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      log("Error getting custom category count: $e");
      return 0;
    }
  }

  /// Gets the total count of categories for a user (global + custom)
  ///
  /// [email] - The user's email address
  /// Returns the total number of categories
  static Future<int> getTotalCategoryCount(String email) async {
    try {
      // Get global categories count
      final globalSnapshot =
          await _firestore.collection('global_categories').get();

      // Get user categories count
      final userSnapshot = await _firestore
          .collection('categories')
          .where('email', isEqualTo: email)
          .get();

      return globalSnapshot.docs.length + userSnapshot.docs.length;
    } catch (e) {
      log("Error getting total category count: $e");
      return 0;
    }
  }

  /// Initialize global categories (call this once when the app starts)
  static Future<void> initializeGlobalCategories() async {
    await createGlobalDefaultCategories();
  }
}
