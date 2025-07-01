import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer';

class AdminCategoriesService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Admin collection for global categories
  static const String _adminCategoriesCollection = 'admin_categories';

  /// User categories collection (existing)
  static const String _userCategoriesCollection = 'categories';

  /// Creates a new admin category that will be available to all users
  ///
  /// [iconName] - The name of the icon
  /// [iconColor] - The hex color string (e.g., '#FF5722')
  /// [name] - The category name
  /// [isActive] - Whether the category is active (optional, defaults to true)
  /// Returns the document ID if successful, null otherwise
  static Future<String?> createAdminCategory({
    required String iconName,
    required String iconColor,
    required String name,
    bool isActive = true,
  }) async {
    try {
      // Check if category with same name already exists
      final existingCategory = await _firestore
          .collection(_adminCategoriesCollection)
          .where('name', isEqualTo: name)
          .limit(1)
          .get();

      if (existingCategory.docs.isNotEmpty) {
        log("Admin category with name '$name' already exists");
        return null;
      }

      // Create the admin category
      DocumentReference categoryRef =
          _firestore.collection(_adminCategoriesCollection).doc();

      await categoryRef.set({
        'iconName': iconName,
        'iconColor': iconColor,
        'name': name,
        'isActive': isActive,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'created_by': 'admin', // You can replace this with actual admin ID
      });

      log("Successfully created admin category: $name");

      // Sync this category to all existing users
      await _syncCategoryToAllUsers(categoryRef.id, {
        'iconName': iconName,
        'iconColor': iconColor,
        'name': name,
        'is_admin_category': true,
        'admin_category_id': categoryRef.id,
        'created_at': FieldValue.serverTimestamp(),
      });

      return categoryRef.id;
    } catch (e) {
      log("Error creating admin category: $e");
      return null;
    }
  }

  /// Updates an existing admin category
  ///
  /// [categoryId] - The admin category document ID
  /// [iconName] - The name of the icon (optional)
  /// [iconColor] - The hex color string (optional)
  /// [name] - The category name (optional)
  /// [isActive] - Whether the category is active (optional)
  /// Returns true if successful, false otherwise
  static Future<bool> updateAdminCategory({
    required String categoryId,
    String? iconName,
    String? iconColor,
    String? name,
    bool? isActive,
  }) async {
    try {
      Map<String, dynamic> updateData = {
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (iconName != null) updateData['iconName'] = iconName;
      if (iconColor != null) updateData['iconColor'] = iconColor;
      if (name != null) updateData['name'] = name;
      if (isActive != null) updateData['isActive'] = isActive;

      // Update admin category
      await _firestore
          .collection(_adminCategoriesCollection)
          .doc(categoryId)
          .update(updateData);

      // Update in all user categories
      Map<String, dynamic> userUpdateData = {};
      if (iconName != null) userUpdateData['iconName'] = iconName;
      if (iconColor != null) userUpdateData['iconColor'] = iconColor;
      if (name != null) userUpdateData['name'] = name;

      if (userUpdateData.isNotEmpty) {
        await _updateCategoryInAllUsers(categoryId, userUpdateData);
      }

      // If category is deactivated, remove from all users
      if (isActive == false) {
        await _removeCategoryFromAllUsers(categoryId);
      } else if (isActive == true) {
        // If reactivated, add back to all users
        final adminCategory = await _firestore
            .collection(_adminCategoriesCollection)
            .doc(categoryId)
            .get();

        if (adminCategory.exists) {
          final data = adminCategory.data()!;
          await _syncCategoryToAllUsers(categoryId, {
            'iconName': data['iconName'],
            'iconColor': data['iconColor'],
            'name': data['name'],
            'is_admin_category': true,
            'admin_category_id': categoryId,
            'created_at': FieldValue.serverTimestamp(),
          });
        }
      }

      log("Successfully updated admin category: $categoryId");
      return true;
    } catch (e) {
      log("Error updating admin category: $e");
      return false;
    }
  }

  /// Deletes an admin category (soft delete by setting isActive to false)
  ///
  /// [categoryId] - The admin category document ID
  /// [hardDelete] - Whether to permanently delete (optional, defaults to false)
  /// Returns true if successful, false otherwise
  static Future<bool> deleteAdminCategory({
    required String categoryId,
    bool hardDelete = false,
  }) async {
    try {
      if (hardDelete) {
        // Permanently delete from admin collection
        await _firestore
            .collection(_adminCategoriesCollection)
            .doc(categoryId)
            .delete();
      } else {
        // Soft delete by setting isActive to false
        await _firestore
            .collection(_adminCategoriesCollection)
            .doc(categoryId)
            .update({
          'isActive': false,
          'updated_at': FieldValue.serverTimestamp(),
        });
      }

      // Remove from all user categories
      await _removeCategoryFromAllUsers(categoryId);

      log("Successfully deleted admin category: $categoryId");
      return true;
    } catch (e) {
      log("Error deleting admin category: $e");
      return false;
    }
  }

  /// Gets all admin categories
  ///
  /// [activeOnly] - Whether to return only active categories (optional, defaults to true)
  /// Returns list of admin categories
  static Future<List<Map<String, dynamic>>> getAllAdminCategories({
    bool activeOnly = true,
  }) async {
    try {
      Query query = _firestore.collection(_adminCategoriesCollection);

      if (activeOnly) {
        query = query.where('isActive', isEqualTo: true);
      }

      final snapshot =
          await query.orderBy('created_at', descending: false).get();

      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();
    } catch (e) {
      log("Error getting admin categories: $e");
      return [];
    }
  }

  /// Syncs all admin categories to a specific user (useful for new users)
  ///
  /// [userEmail] - The user's email address
  /// Returns true if successful, false otherwise
  static Future<bool> syncAdminCategoriesToUser(String userEmail) async {
    try {
      // Get all active admin categories
      final adminCategories = await getAllAdminCategories(activeOnly: true);

      if (adminCategories.isEmpty) {
        log("No admin categories to sync for user: $userEmail");
        return true;
      }

      // Create batch write for better performance
      WriteBatch batch = _firestore.batch();

      for (var adminCategory in adminCategories) {
        // Check if user already has this admin category
        final existingCategory = await _firestore
            .collection(_userCategoriesCollection)
            .where('email', isEqualTo: userEmail)
            .where('admin_category_id', isEqualTo: adminCategory['id'])
            .limit(1)
            .get();

        if (existingCategory.docs.isEmpty) {
          // Add admin category to user's categories
          DocumentReference userCategoryRef =
              _firestore.collection(_userCategoriesCollection).doc();

          batch.set(userCategoryRef, {
            'iconName': adminCategory['iconName'],
            'iconColor': adminCategory['iconColor'],
            'name': adminCategory['name'],
            'email': userEmail,
            'is_admin_category': true,
            'admin_category_id': adminCategory['id'],
            'created_at': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();
      log("Successfully synced ${adminCategories.length} admin categories to user: $userEmail");
      return true;
    } catch (e) {
      log("Error syncing admin categories to user $userEmail: $e");
      return false;
    }
  }

  /// Private method to sync a category to all existing users
  static Future<void> _syncCategoryToAllUsers(
      String adminCategoryId, Map<String, dynamic> categoryData) async {
    try {
      // Get all unique user emails
      final usersSnapshot =
          await _firestore.collection(_userCategoriesCollection).get();

      Set<String> userEmails = {};
      for (var doc in usersSnapshot.docs) {
        final email = doc.data()['email'] as String?;
        if (email != null) {
          userEmails.add(email);
        }
      }

      // Also get users from authentication collection
      final authSnapshot = await _firestore.collection('authentication').get();

      for (var doc in authSnapshot.docs) {
        final email = doc.data()['email'] as String?;
        if (email != null) {
          userEmails.add(email);
        }
      }

      // Create batch writes (Firestore has a limit of 500 operations per batch)
      List<String> emailList = userEmails.toList();

      for (int i = 0; i < emailList.length; i += 400) {
        WriteBatch batch = _firestore.batch();
        int endIndex =
            (i + 400 < emailList.length) ? i + 400 : emailList.length;

        for (int j = i; j < endIndex; j++) {
          String email = emailList[j];

          // Check if user already has this admin category
          final existingCategory = await _firestore
              .collection(_userCategoriesCollection)
              .where('email', isEqualTo: email)
              .where('admin_category_id', isEqualTo: adminCategoryId)
              .limit(1)
              .get();

          if (existingCategory.docs.isEmpty) {
            DocumentReference userCategoryRef =
                _firestore.collection(_userCategoriesCollection).doc();

            batch.set(userCategoryRef, {
              ...categoryData,
              'email': email,
            });
          }
        }

        await batch.commit();
      }

      log("Successfully synced admin category to all users");
    } catch (e) {
      log("Error syncing category to all users: $e");
    }
  }

  /// Private method to update a category in all users
  static Future<void> _updateCategoryInAllUsers(
      String adminCategoryId, Map<String, dynamic> updateData) async {
    try {
      final userCategories = await _firestore
          .collection(_userCategoriesCollection)
          .where('admin_category_id', isEqualTo: adminCategoryId)
          .get();

      // Update in batches
      List<DocumentSnapshot> docs = userCategories.docs;

      for (int i = 0; i < docs.length; i += 400) {
        WriteBatch batch = _firestore.batch();
        int endIndex = (i + 400 < docs.length) ? i + 400 : docs.length;

        for (int j = i; j < endIndex; j++) {
          batch.update(docs[j].reference, updateData);
        }

        await batch.commit();
      }

      log("Successfully updated admin category in all user categories");
    } catch (e) {
      log("Error updating category in all users: $e");
    }
  }

  /// Private method to remove a category from all users
  static Future<void> _removeCategoryFromAllUsers(
      String adminCategoryId) async {
    try {
      final userCategories = await _firestore
          .collection(_userCategoriesCollection)
          .where('admin_category_id', isEqualTo: adminCategoryId)
          .get();

      // Delete in batches
      List<DocumentSnapshot> docs = userCategories.docs;

      for (int i = 0; i < docs.length; i += 400) {
        WriteBatch batch = _firestore.batch();
        int endIndex = (i + 400 < docs.length) ? i + 400 : docs.length;

        for (int j = i; j < endIndex; j++) {
          batch.delete(docs[j].reference);
        }

        await batch.commit();
      }

      log("Successfully removed admin category from all user categories");
    } catch (e) {
      log("Error removing category from all users: $e");
    }
  }

  /// Gets statistics about admin categories usage
  static Future<Map<String, dynamic>> getAdminCategoriesStats() async {
    try {
      final adminCategories =
          await _firestore.collection(_adminCategoriesCollection).get();

      final userCategories = await _firestore
          .collection(_userCategoriesCollection)
          .where('is_admin_category', isEqualTo: true)
          .get();

      final uniqueUsers = userCategories.docs
          .map((doc) => doc.data()['email'] as String?)
          .where((email) => email != null)
          .toSet()
          .length;

      return {
        'total_admin_categories': adminCategories.docs.length,
        'active_admin_categories': adminCategories.docs
            .where((doc) => doc.data()['isActive'] == true)
            .length,
        'total_user_instances': userCategories.docs.length,
        'users_with_admin_categories': uniqueUsers,
      };
    } catch (e) {
      log("Error getting admin categories stats: $e");
      return {};
    }
  }
}
