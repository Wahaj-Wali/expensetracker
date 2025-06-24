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

  /// Creates default categories for a new user
  ///
  /// [email] - The user's email address
  /// Returns true if successful, false otherwise
  static Future<bool> createDefaultCategories(String email) async {
    try {
      // Check if user already has categories
      final existingCategories = await _firestore
          .collection('categories')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      // If user already has categories, don't create defaults
      if (existingCategories.docs.isNotEmpty) {
        log("User $email already has categories, skipping default creation");
        return true;
      }

      // Create batch write for better performance
      WriteBatch batch = _firestore.batch();

      for (var category in _defaultCategories) {
        DocumentReference categoryRef =
            _firestore.collection('categories').doc();
        batch.set(categoryRef, {
          ...category,
          'email': email,
          'created_at': FieldValue.serverTimestamp(),
          'is_default': true, // Mark as default category
        });
      }

      await batch.commit();
      log("Successfully created ${_defaultCategories.length} default categories for user: $email");
      return true;
    } catch (e) {
      log("Error creating default categories for $email: $e");
      return false;
    }
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
      // Delete all existing categories for the user
      final existingCategories = await _firestore
          .collection('categories')
          .where('email', isEqualTo: email)
          .get();

      WriteBatch deleteBatch = _firestore.batch();
      for (var doc in existingCategories.docs) {
        deleteBatch.delete(doc.reference);
      }
      await deleteBatch.commit();

      // Create default categories
      return await createDefaultCategories(email);
    } catch (e) {
      log("Error resetting categories to defaults for $email: $e");
      return false;
    }
  }

  /// Checks if a user has any categories
  ///
  /// [email] - The user's email address
  /// Returns true if user has categories, false otherwise
  static Future<bool> userHasCategories(String email) async {
    try {
      final snapshot = await _firestore
          .collection('categories')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      log("Error checking if user has categories: $e");
      return false;
    }
  }

  /// Gets the count of categories for a user
  ///
  /// [email] - The user's email address
  /// Returns the number of categories
  static Future<int> getCategoryCount(String email) async {
    try {
      final snapshot = await _firestore
          .collection('categories')
          .where('email', isEqualTo: email)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      log("Error getting category count: $e");
      return 0;
    }
  }
}
