import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class TaxRate {
  final String id;
  final String name;
  final String description;
  final double rate; // Percentage (e.g., 18.0 for 18%)
  final String type; // 'inclusive' or 'exclusive'
  final bool isActive;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? region; // Country/State where applicable
  final int sortOrder;

  TaxRate({
    required this.id,
    required this.name,
    required this.description,
    required this.rate,
    required this.type,
    this.isActive = true,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
    this.region,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'rate': rate,
      'type': type,
      'isActive': isActive,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'region': region,
      'sortOrder': sortOrder,
    };
  }

  factory TaxRate.fromJson(Map<String, dynamic> json) {
    return TaxRate(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      rate: (json['rate'] as num).toDouble(),
      type: json['type'] as String,
      isActive: json['isActive'] as bool? ?? true,
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      region: json['region'] as String?,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }

  TaxRate copyWith({
    String? name,
    String? description,
    double? rate,
    String? type,
    bool? isActive,
    bool? isDefault,
    DateTime? updatedAt,
    String? region,
    int? sortOrder,
  }) {
    return TaxRate(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      rate: rate ?? this.rate,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      region: region ?? this.region,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  // Calculate tax amount
  double calculateTaxAmount(double amount) {
    if (!isActive) return 0.0;

    if (type == 'inclusive') {
      // Tax is included in the amount
      return amount * (rate / (100 + rate));
    } else {
      // Tax is exclusive (added to amount)
      return amount * (rate / 100);
    }
  }

  // Calculate total amount including tax
  double calculateTotalAmount(double baseAmount) {
    if (!isActive) return baseAmount;

    if (type == 'inclusive') {
      // Amount already includes tax
      return baseAmount;
    } else {
      // Add tax to base amount
      return baseAmount + calculateTaxAmount(baseAmount);
    }
  }

  // Calculate base amount excluding tax
  double calculateBaseAmount(double totalAmount) {
    if (!isActive) return totalAmount;

    if (type == 'inclusive') {
      // Remove tax from total
      return totalAmount - calculateTaxAmount(totalAmount);
    } else {
      // Total amount is already base amount
      return totalAmount;
    }
  }
}

class AdminTaxController extends ChangeNotifier {
  static const String _taxRatesKey = 'tax_rates';

  List<TaxRate> _taxRates = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<TaxRate> get taxRates => List.unmodifiable(_taxRates);
  List<TaxRate> get activeTaxRates =>
      _taxRates.where((tax) => tax.isActive).toList();
  TaxRate? get defaultTaxRate =>
      _taxRates.where((tax) => tax.isDefault && tax.isActive).isNotEmpty
          ? _taxRates.firstWhere((tax) => tax.isDefault && tax.isActive)
          : null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AdminTaxController() {
    _initializeTaxRates();
  }

  // Initialize tax rates
  Future<void> _initializeTaxRates() async {
    _setLoading(true);

    try {
      await _loadTaxRates();

      // Add default tax rates if none exist
      if (_taxRates.isEmpty) {
        await _createDefaultTaxRates();
      }

      _clearError();
    } catch (e) {
      _setError('Failed to initialize tax rates: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load tax rates from storage
  Future<void> _loadTaxRates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final taxRatesJson = prefs.getString(_taxRatesKey);

      if (taxRatesJson != null) {
        final List<dynamic> taxRatesList = json.decode(taxRatesJson);
        _taxRates = taxRatesList.map((json) => TaxRate.fromJson(json)).toList();

        // Sort by sortOrder
        _taxRates.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      }
    } catch (e) {
      throw Exception('Failed to load tax rates: $e');
    }
  }

  // Save tax rates to storage
  Future<void> _saveTaxRates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final taxRatesJson = json.encode(
        _taxRates.map((tax) => tax.toJson()).toList(),
      );
      await prefs.setString(_taxRatesKey, taxRatesJson);
    } catch (e) {
      throw Exception('Failed to save tax rates: $e');
    }
  }

  // Create a new tax rate
  Future<bool> createTaxRate({
    required String name,
    required String description,
    required double rate,
    required String type,
    String? region,
    bool isDefault = false,
    int? sortOrder,
  }) async {
    try {
      // Validate input
      if (name.trim().isEmpty) {
        throw Exception('Tax rate name cannot be empty');
      }

      if (rate < 0 || rate > 100) {
        throw Exception('Tax rate must be between 0 and 100');
      }

      if (!['inclusive', 'exclusive'].contains(type)) {
        throw Exception('Tax type must be either inclusive or exclusive');
      }

      // Check for duplicate names
      if (_taxRates
          .any((tax) => tax.name.toLowerCase() == name.toLowerCase())) {
        throw Exception('Tax rate with this name already exists');
      }

      // If setting as default, remove default from others
      if (isDefault) {
        await _clearDefaultTaxRates();
      }

      final now = DateTime.now();
      final newTaxRate = TaxRate(
        id: _generateId(),
        name: name.trim(),
        description: description.trim(),
        rate: rate,
        type: type,
        isDefault: isDefault,
        createdAt: now,
        updatedAt: now,
        region: region?.trim(),
        sortOrder: sortOrder ?? _taxRates.length,
      );

      _taxRates.add(newTaxRate);
      _taxRates.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      await _saveTaxRates();
      _clearError();
      notifyListeners();

      return true;
    } catch (e) {
      _setError('Failed to create tax rate: $e');
      return false;
    }
  }

  // Update an existing tax rate
  Future<bool> updateTaxRate({
    required String id,
    String? name,
    String? description,
    double? rate,
    String? type,
    bool? isActive,
    bool? isDefault,
    String? region,
    int? sortOrder,
  }) async {
    try {
      final index = _taxRates.indexWhere((tax) => tax.id == id);
      if (index == -1) {
        throw Exception('Tax rate not found');
      }

      final taxRate = _taxRates[index];

      // Validate input
      if (name != null && name.trim().isEmpty) {
        throw Exception('Tax rate name cannot be empty');
      }

      if (rate != null && (rate < 0 || rate > 100)) {
        throw Exception('Tax rate must be between 0 and 100');
      }

      if (type != null && !['inclusive', 'exclusive'].contains(type)) {
        throw Exception('Tax type must be either inclusive or exclusive');
      }

      // Check for duplicate names (excluding current tax rate)
      if (name != null &&
          _taxRates.any((tax) =>
              tax.id != id && tax.name.toLowerCase() == name.toLowerCase())) {
        throw Exception('Tax rate with this name already exists');
      }

      // If setting as default, remove default from others
      if (isDefault == true) {
        await _clearDefaultTaxRates();
      }

      final updatedTaxRate = taxRate.copyWith(
        name: name?.trim(),
        description: description?.trim(),
        rate: rate,
        type: type,
        isActive: isActive,
        isDefault: isDefault,
        region: region?.trim(),
        sortOrder: sortOrder,
        updatedAt: DateTime.now(),
      );

      _taxRates[index] = updatedTaxRate;
      _taxRates.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      await _saveTaxRates();
      _clearError();
      notifyListeners();

      return true;
    } catch (e) {
      _setError('Failed to update tax rate: $e');
      return false;
    }
  }

  // Delete a tax rate
  Future<bool> deleteTaxRate(String id) async {
    try {
      final taxRate = _taxRates.firstWhere(
        (tax) => tax.id == id,
        orElse: () => throw Exception('Tax rate not found'),
      );

      _taxRates.removeWhere((tax) => tax.id == id);

      await _saveTaxRates();
      _clearError();
      notifyListeners();

      return true;
    } catch (e) {
      _setError('Failed to delete tax rate: $e');
      return false;
    }
  }

  // Toggle tax rate active status
  Future<bool> toggleTaxRateStatus(String id) async {
    try {
      final index = _taxRates.indexWhere((tax) => tax.id == id);
      if (index == -1) {
        throw Exception('Tax rate not found');
      }

      final taxRate = _taxRates[index];
      final updatedTaxRate = taxRate.copyWith(
        isActive: !taxRate.isActive,
        updatedAt: DateTime.now(),
      );

      _taxRates[index] = updatedTaxRate;

      await _saveTaxRates();
      _clearError();
      notifyListeners();

      return true;
    } catch (e) {
      _setError('Failed to toggle tax rate status: $e');
      return false;
    }
  }

  // Set default tax rate
  Future<bool> setDefaultTaxRate(String id) async {
    try {
      final index = _taxRates.indexWhere((tax) => tax.id == id);
      if (index == -1) {
        throw Exception('Tax rate not found');
      }

      // Clear all default flags
      await _clearDefaultTaxRates();

      // Set new default
      final taxRate = _taxRates[index];
      final updatedTaxRate = taxRate.copyWith(
        isDefault: true,
        isActive: true, // Default tax rate should be active
        updatedAt: DateTime.now(),
      );

      _taxRates[index] = updatedTaxRate;

      await _saveTaxRates();
      _clearError();
      notifyListeners();

      return true;
    } catch (e) {
      _setError('Failed to set default tax rate: $e');
      return false;
    }
  }

  // Clear all default tax rates
  Future<void> _clearDefaultTaxRates() async {
    for (int i = 0; i < _taxRates.length; i++) {
      if (_taxRates[i].isDefault) {
        _taxRates[i] = _taxRates[i].copyWith(
          isDefault: false,
          updatedAt: DateTime.now(),
        );
      }
    }
  }

  // Reorder tax rates
  Future<bool> reorderTaxRates(List<String> orderedIds) async {
    try {
      if (orderedIds.length != _taxRates.length) {
        throw Exception('Invalid reorder data');
      }

      final reorderedTaxRates = <TaxRate>[];

      for (int i = 0; i < orderedIds.length; i++) {
        final taxRate = _taxRates.firstWhere(
          (tax) => tax.id == orderedIds[i],
          orElse: () => throw Exception('Tax rate not found'),
        );

        reorderedTaxRates.add(taxRate.copyWith(
          sortOrder: i,
          updatedAt: DateTime.now(),
        ));
      }

      _taxRates = reorderedTaxRates;

      await _saveTaxRates();
      _clearError();
      notifyListeners();

      return true;
    } catch (e) {
      _setError('Failed to reorder tax rates: $e');
      return false;
    }
  }

  // Get tax rate by ID
  TaxRate? getTaxRateById(String id) {
    try {
      return _taxRates.firstWhere((tax) => tax.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get tax rates by region
  List<TaxRate> getTaxRatesByRegion(String region) {
    return _taxRates
        .where((tax) => tax.region?.toLowerCase() == region.toLowerCase())
        .toList();
  }

  // Calculate tax for amount using specific tax rate
  Map<String, double> calculateTax(double amount, String taxRateId) {
    final taxRate = getTaxRateById(taxRateId);
    if (taxRate == null || !taxRate.isActive) {
      return {
        'baseAmount': amount,
        'taxAmount': 0.0,
        'totalAmount': amount,
      };
    }

    final taxAmount = taxRate.calculateTaxAmount(amount);
    final totalAmount = taxRate.calculateTotalAmount(amount);
    final baseAmount = taxRate.calculateBaseAmount(totalAmount);

    return {
      'baseAmount': baseAmount,
      'taxAmount': taxAmount,
      'totalAmount': totalAmount,
    };
  }

  // Calculate tax using default tax rate
  Map<String, double> calculateDefaultTax(double amount) {
    final defaultTax = defaultTaxRate;
    if (defaultTax == null) {
      return {
        'baseAmount': amount,
        'taxAmount': 0.0,
        'totalAmount': amount,
      };
    }

    return calculateTax(amount, defaultTax.id);
  }

  // Get tax rate statistics
  Map<String, dynamic> getTaxRateStats() {
    final totalTaxRates = _taxRates.length;
    final activeTaxRates = _taxRates.where((tax) => tax.isActive).length;
    final inactiveTaxRates = totalTaxRates - activeTaxRates;
    final inclusiveTaxRates =
        _taxRates.where((tax) => tax.type == 'inclusive').length;
    final exclusiveTaxRates =
        _taxRates.where((tax) => tax.type == 'exclusive').length;

    final regions = _taxRates
        .where((tax) => tax.region != null)
        .map((tax) => tax.region!)
        .toSet()
        .length;

    final averageRate = _taxRates.isNotEmpty
        ? _taxRates.map((tax) => tax.rate).reduce((a, b) => a + b) /
            _taxRates.length
        : 0.0;

    return {
      'total': totalTaxRates,
      'active': activeTaxRates,
      'inactive': inactiveTaxRates,
      'inclusive': inclusiveTaxRates,
      'exclusive': exclusiveTaxRates,
      'regions': regions,
      'averageRate': averageRate,
      'hasDefault': defaultTaxRate != null,
    };
  }

  // Refresh tax rates
  Future<void> refreshTaxRates() async {
    _setLoading(true);

    try {
      await _loadTaxRates();
      _clearError();
    } catch (e) {
      _setError('Failed to refresh tax rates: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Create default tax rates
  Future<void> _createDefaultTaxRates() async {
    final defaultTaxRates = [
      {
        'name': 'No Tax',
        'description': 'No tax applied',
        'rate': 0.0,
        'type': 'exclusive',
        'isDefault': true
      },
      {
        'name': 'GST 5%',
        'description': 'Goods and Services Tax 5%',
        'rate': 5.0,
        'type': 'exclusive'
      },
      {
        'name': 'GST 12%',
        'description': 'Goods and Services Tax 12%',
        'rate': 12.0,
        'type': 'exclusive'
      },
      {
        'name': 'GST 18%',
        'description': 'Goods and Services Tax 18%',
        'rate': 18.0,
        'type': 'exclusive'
      },
      {
        'name': 'GST 28%',
        'description': 'Goods and Services Tax 28%',
        'rate': 28.0,
        'type': 'exclusive'
      },
    ];

    final now = DateTime.now();

    for (int i = 0; i < defaultTaxRates.length; i++) {
      final taxData = defaultTaxRates[i];
      _taxRates.add(TaxRate(
        id: _generateId(),
        name: taxData['name'] as String,
        description: taxData['description'] as String,
        rate: taxData['rate'] as double,
        type: taxData['type'] as String,
        isDefault: taxData['isDefault'] as bool? ?? false,
        createdAt: now,
        updatedAt: now,
        sortOrder: i,
      ));
    }

    await _saveTaxRates();
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
    debugPrint('AdminTaxController Error: $error');
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
