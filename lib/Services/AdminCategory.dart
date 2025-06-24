import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ExpenseCategory {
  final String id;
  final String name;
  final String description;
  final String iconName;
  final String colorHex;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int sortOrder;
  final bool isDefault; // Cannot be deleted if true

  ExpenseCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    required this.colorHex,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.sortOrder = 0,
    this.isDefault = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconName': iconName,
      'colorHex': colorHex,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'sortOrder': sortOrder,
      'isDefault': isDefault,
    };
  }

  factory ExpenseCategory.fromJson(Map<String, dynamic> json) {
    return ExpenseCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      iconName: json['iconName'] as String,
      colorHex: json['colorHex'] as String,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      sortOrder: json['sortOrder'] as int? ?? 0,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  ExpenseCategory copyWith({
    String? name,
    String? description,
    String? iconName,
    String? colorHex,
    bool? isActive,
    DateTime? updatedAt,
    int? sortOrder,
  }) {
    return ExpenseCategory(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      sortOrder: sortOrder ?? this.sortOrder,
      isDefault: isDefault,
    );
  }
}

class AdminCategoryController extends ChangeNotifier {
  static const String _categoriesKey = 'expense_categories';

  List<ExpenseCategory> _categories = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<ExpenseCategory> get categories => List.unmodifiable(_categories);
  List<ExpenseCategory> get activeCategories =>
      _categories.where((cat) => cat.isActive).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  AdminCategoryController() {
    _initializeCategories();
  }

  // Initialize with default categories
  Future<void> _initializeCategories() async {
    _setLoading(true);

    try {
      await _loadCategories();

      // Add default categories if none exist
      if (_categories.isEmpty) {
        await _createDefaultCategories();
      }

      _clearError();
    } catch (e) {
      _setError('Failed to initialize categories: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load categories from storage
  Future<void> _loadCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final categoriesJson = prefs.getString(_categoriesKey);

      if (categoriesJson != null) {
        final List<dynamic> categoryList = json.decode(categoriesJson);
        _categories =
            categoryList.map((json) => ExpenseCategory.fromJson(json)).toList();

        // Sort by sortOrder
        _categories.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      }
    } catch (e) {
      throw Exception('Failed to load categories: $e');
    }
  }

  // Save categories to storage
  Future<void> _saveCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final categoriesJson = json.encode(
        _categories.map((cat) => cat.toJson()).toList(),
      );
      await prefs.setString(_categoriesKey, categoriesJson);
    } catch (e) {
      throw Exception('Failed to save categories: $e');
    }
  }

  // Create a new category
  Future<bool> createCategory({
    required String name,
    required String description,
    required String iconName,
    required String colorHex,
    int? sortOrder,
  }) async {
    try {
      // Validate input
      if (name.trim().isEmpty) {
        throw Exception('Category name cannot be empty');
      }

      // Check for duplicate names
      if (_categories
          .any((cat) => cat.name.toLowerCase() == name.toLowerCase())) {
        throw Exception('Category with this name already exists');
      }

      final now = DateTime.now();
      final newCategory = ExpenseCategory(
        id: _generateId(),
        name: name.trim(),
        description: description.trim(),
        iconName: iconName,
        colorHex: colorHex,
        createdAt: now,
        updatedAt: now,
        sortOrder: sortOrder ?? _categories.length,
      );

      _categories.add(newCategory);
      _categories.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      await _saveCategories();
      _clearError();
      notifyListeners();

      return true;
    } catch (e) {
      _setError('Failed to create category: $e');
      return false;
    }
  }

  // Update an existing category
  Future<bool> updateCategory({
    required String id,
    String? name,
    String? description,
    String? iconName,
    String? colorHex,
    bool? isActive,
    int? sortOrder,
  }) async {
    try {
      final index = _categories.indexWhere((cat) => cat.id == id);
      if (index == -1) {
        throw Exception('Category not found');
      }

      final category = _categories[index];

      // Validate name if provided
      if (name != null && name.trim().isEmpty) {
        throw Exception('Category name cannot be empty');
      }

      // Check for duplicate names (excluding current category)
      if (name != null &&
          _categories.any((cat) =>
              cat.id != id && cat.name.toLowerCase() == name.toLowerCase())) {
        throw Exception('Category with this name already exists');
      }

      final updatedCategory = category.copyWith(
        name: name?.trim(),
        description: description?.trim(),
        iconName: iconName,
        colorHex: colorHex,
        isActive: isActive,
        sortOrder: sortOrder,
        updatedAt: DateTime.now(),
      );

      _categories[index] = updatedCategory;
      _categories.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      await _saveCategories();
      _clearError();
      notifyListeners();

      return true;
    } catch (e) {
      _setError('Failed to update category: $e');
      return false;
    }
  }

  // Delete a category
  Future<bool> deleteCategory(String id) async {
    try {
      final category = _categories.firstWhere(
        (cat) => cat.id == id,
        orElse: () => throw Exception('Category not found'),
      );

      // Cannot delete default categories
      if (category.isDefault) {
        throw Exception('Cannot delete default category');
      }

      _categories.removeWhere((cat) => cat.id == id);

      await _saveCategories();
      _clearError();
      notifyListeners();

      return true;
    } catch (e) {
      _setError('Failed to delete category: $e');
      return false;
    }
  }

  // Toggle category active status
  Future<bool> toggleCategoryStatus(String id) async {
    try {
      final index = _categories.indexWhere((cat) => cat.id == id);
      if (index == -1) {
        throw Exception('Category not found');
      }

      final category = _categories[index];
      final updatedCategory = category.copyWith(
        isActive: !category.isActive,
        updatedAt: DateTime.now(),
      );

      _categories[index] = updatedCategory;

      await _saveCategories();
      _clearError();
      notifyListeners();

      return true;
    } catch (e) {
      _setError('Failed to toggle category status: $e');
      return false;
    }
  }

  // Reorder categories
  Future<bool> reorderCategories(List<String> orderedIds) async {
    try {
      if (orderedIds.length != _categories.length) {
        throw Exception('Invalid reorder data');
      }

      final reorderedCategories = <ExpenseCategory>[];

      for (int i = 0; i < orderedIds.length; i++) {
        final category = _categories.firstWhere(
          (cat) => cat.id == orderedIds[i],
          orElse: () => throw Exception('Category not found'),
        );

        reorderedCategories.add(category.copyWith(
          sortOrder: i,
          updatedAt: DateTime.now(),
        ));
      }

      _categories = reorderedCategories;

      await _saveCategories();
      _clearError();
      notifyListeners();

      return true;
    } catch (e) {
      _setError('Failed to reorder categories: $e');
      return false;
    }
  }

  // Get category by ID
  ExpenseCategory? getCategoryById(String id) {
    try {
      return _categories.firstWhere((cat) => cat.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get category statistics
  Map<String, dynamic> getCategoryStats() {
    final totalCategories = _categories.length;
    final activeCategories = _categories.where((cat) => cat.isActive).length;
    final inactiveCategories = totalCategories - activeCategories;
    final defaultCategories = _categories.where((cat) => cat.isDefault).length;

    return {
      'total': totalCategories,
      'active': activeCategories,
      'inactive': inactiveCategories,
      'default': defaultCategories,
      'custom': totalCategories - defaultCategories,
    };
  }

  // Refresh categories
  Future<void> refreshCategories() async {
    _setLoading(true);

    try {
      await _loadCategories();
      _clearError();
    } catch (e) {
      _setError('Failed to refresh categories: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Create default categories
  Future<void> _createDefaultCategories() async {
    final defaultCategories = [
      {
        'name': 'Food & Dining',
        'description': 'Restaurant, groceries, food delivery',
        'icon': 'restaurant',
        'color': 'FF4CAF50'
      },
      {
        'name': 'Transportation',
        'description': 'Gas, parking, public transport, taxi',
        'icon': 'directions_car',
        'color': 'FF2196F3'
      },
      {
        'name': 'Shopping',
        'description': 'Clothing, electronics, general shopping',
        'icon': 'shopping_bag',
        'color': 'FFE91E63'
      },
      {
        'name': 'Entertainment',
        'description': 'Movies, games, hobbies, recreation',
        'icon': 'movie',
        'color': 'FF9C27B0'
      },
      {
        'name': 'Bills & Utilities',
        'description': 'Electric, water, internet, phone bills',
        'icon': 'receipt',
        'color': 'FFFF9800'
      },
      {
        'name': 'Healthcare',
        'description': 'Doctor, pharmacy, medical expenses',
        'icon': 'local_hospital',
        'color': 'FFF44336'
      },
      {
        'name': 'Education',
        'description': 'Books, courses, school fees',
        'icon': 'school',
        'color': 'FF673AB7'
      },
      {
        'name': 'Travel',
        'description': 'Vacation, business trips, accommodation',
        'icon': 'flight',
        'color': 'FF00BCD4'
      },
      {
        'name': 'Personal Care',
        'description': 'Haircut, cosmetics, personal items',
        'icon': 'face',
        'color': 'FFCDDC39'
      },
      {
        'name': 'Other',
        'description': 'Miscellaneous expenses',
        'icon': 'category',
        'color': 'FF607D8B'
      },
    ];

    final now = DateTime.now();

    for (int i = 0; i < defaultCategories.length; i++) {
      final catData = defaultCategories[i];
      _categories.add(ExpenseCategory(
        id: _generateId(),
        name: catData['name']!,
        description: catData['description']!,
        iconName: catData['icon']!,
        colorHex: catData['color']!,
        createdAt: now,
        updatedAt: now,
        sortOrder: i,
        isDefault: true,
      ));
    }

    await _saveCategories();
  }

  // Helper methods
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    debugPrint('AdminCategoryController Error: $error');
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
