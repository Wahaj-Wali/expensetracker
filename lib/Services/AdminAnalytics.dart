import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math' as math;

class UserData {
  final String userId;
  final String userName;
  final String email;
  final DateTime registrationDate;
  final DateTime lastActiveDate;
  final int totalExpenses;
  final double totalAmount;
  final List<String> favoriteCategories;
  final Map<String, double> categorySpending;
  final Map<String, int> monthlyExpenseCounts;
  final bool isActive;

  UserData({
    required this.userId,
    required this.userName,
    required this.email,
    required this.registrationDate,
    required this.lastActiveDate,
    required this.totalExpenses,
    required this.totalAmount,
    required this.favoriteCategories,
    required this.categorySpending,
    required this.monthlyExpenseCounts,
    this.isActive = true,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      email: json['email'] as String,
      registrationDate: DateTime.parse(json['registrationDate'] as String),
      lastActiveDate: DateTime.parse(json['lastActiveDate'] as String),
      totalExpenses: json['totalExpenses'] as int,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      favoriteCategories: List<String>.from(json['favoriteCategories'] as List),
      categorySpending: Map<String, double>.from(
        (json['categorySpending'] as Map).map(
          (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
        ),
      ),
      monthlyExpenseCounts: Map<String, int>.from(
        (json['monthlyExpenseCounts'] as Map).map(
          (key, value) => MapEntry(key.toString(), value as int),
        ),
      ),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'email': email,
      'registrationDate': registrationDate.toIso8601String(),
      'lastActiveDate': lastActiveDate.toIso8601String(),
      'totalExpenses': totalExpenses,
      'totalAmount': totalAmount,
      'favoriteCategories': favoriteCategories,
      'categorySpending': categorySpending,
      'monthlyExpenseCounts': monthlyExpenseCounts,
      'isActive': isActive,
    };
  }
}

class ExpenseAnalytics {
  final DateTime periodStart;
  final DateTime periodEnd;
  final double totalAmount;
  final int totalTransactions;
  final double averagePerTransaction;
  final Map<String, double> categoryBreakdown;
  final Map<String, int> categoryTransactionCounts;
  final List<Map<String, dynamic>> dailyTrends;
  final List<Map<String, dynamic>> monthlyTrends;
  final String topCategory;
  final double topCategoryAmount;
  final List<Map<String, dynamic>> topSpenders;

  ExpenseAnalytics({
    required this.periodStart,
    required this.periodEnd,
    required this.totalAmount,
    required this.totalTransactions,
    required this.averagePerTransaction,
    required this.categoryBreakdown,
    required this.categoryTransactionCounts,
    required this.dailyTrends,
    required this.monthlyTrends,
    required this.topCategory,
    required this.topCategoryAmount,
    required this.topSpenders,
  });
}

class AdminAnalyticsController extends ChangeNotifier {
  static const String _userDataKey = 'user_analytics_data';
  static const String _systemMetricsKey = 'system_metrics';

  List<UserData> _userData = [];
  Map<String, dynamic> _systemMetrics = {};
  bool _isLoading = false;
  String? _error;
  DateTime? _lastDataSync;

  // Getters
  List<UserData> get userData => List.unmodifiable(_userData);
  List<UserData> get activeUsers =>
      _userData.where((user) => user.isActive).toList();
  Map<String, dynamic> get systemMetrics => Map.unmodifiable(_systemMetrics);
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastDataSync => _lastDataSync;

  AdminAnalyticsController() {
    _initializeAnalytics();
  }

  // Initialize analytics data
  Future<void> _initializeAnalytics() async {
    _setLoading(true);

    try {
      await _loadUserData();
      await _loadSystemMetrics();
      await _generateSampleData(); // For demo purposes
      _lastDataSync = DateTime.now();
      _clearError();
    } catch (e) {
      _setError('Failed to initialize analytics: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load user data from storage
  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataJson = prefs.getString(_userDataKey);

      if (userDataJson != null) {
        final List<dynamic> userList = json.decode(userDataJson);
        _userData = userList.map((json) => UserData.fromJson(json)).toList();
      }
    } catch (e) {
      throw Exception('Failed to load user data: $e');
    }
  }

  // Load system metrics
  Future<void> _loadSystemMetrics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metricsJson = prefs.getString(_systemMetricsKey);

      if (metricsJson != null) {
        _systemMetrics = json.decode(metricsJson);
      } else {
        _systemMetrics = _getDefaultSystemMetrics();
      }
    } catch (e) {
      throw Exception('Failed to load system metrics: $e');
    }
  }

  // Save user data
  Future<void> _saveUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataJson = json.encode(
        _userData.map((user) => user.toJson()).toList(),
      );
      await prefs.setString(_userDataKey, userDataJson);
    } catch (e) {
      throw Exception('Failed to save user data: $e');
    }
  }

  // Save system metrics
  Future<void> _saveSystemMetrics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metricsJson = json.encode(_systemMetrics);
      await prefs.setString(_systemMetricsKey, metricsJson);
    } catch (e) {
      throw Exception('Failed to save system metrics: $e');
    }
  }

  // Get overall platform statistics
  Map<String, dynamic> getPlatformStats() {
    final totalUsers = _userData.length;
    final activeUsers = _userData.where((user) => user.isActive).length;
    final inactiveUsers = totalUsers - activeUsers;

    final totalExpenses = _userData.fold<int>(
      0,
      (sum, user) => sum + user.totalExpenses,
    );

    final totalAmount = _userData.fold<double>(
      0.0,
      (sum, user) => sum + user.totalAmount,
    );

    final averageExpensesPerUser =
        totalUsers > 0 ? totalExpenses / totalUsers : 0.0;
    final averageAmountPerUser =
        totalUsers > 0 ? totalAmount / totalUsers : 0.0;

    // Calculate user growth (last 30 days)
    final thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));
    final newUsersLast30Days = _userData
        .where(
          (user) => user.registrationDate.isAfter(thirtyDaysAgo),
        )
        .length;

    // Calculate active users (last 7 days)
    final sevenDaysAgo = DateTime.now().subtract(Duration(days: 7));
    final activeUsersLast7Days = _userData
        .where(
          (user) => user.lastActiveDate.isAfter(sevenDaysAgo),
        )
        .length;

    return {
      'totalUsers': totalUsers,
      'activeUsers': activeUsers,
      'inactiveUsers': inactiveUsers,
      'totalExpenses': totalExpenses,
      'totalAmount': totalAmount,
      'averageExpensesPerUser': averageExpensesPerUser,
      'averageAmountPerUser': averageAmountPerUser,
      'newUsersLast30Days': newUsersLast30Days,
      'activeUsersLast7Days': activeUsersLast7Days,
      'userGrowthRate':
          totalUsers > 0 ? (newUsersLast30Days / totalUsers) * 100 : 0.0,
      'userActivityRate':
          totalUsers > 0 ? (activeUsersLast7Days / totalUsers) * 100 : 0.0,
    };
  }

  // Get expense analytics for a date range
  ExpenseAnalytics getExpenseAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final start = startDate ?? DateTime.now().subtract(Duration(days: 30));
    final end = endDate ?? DateTime.now();

    // Filter users with expenses in the date range
    final relevantUsers = _userData
        .where((user) =>
            user.lastActiveDate.isAfter(start) &&
            user.lastActiveDate.isBefore(end.add(Duration(days: 1))))
        .toList();

    final totalAmount = relevantUsers.fold<double>(
      0.0,
      (sum, user) => sum + user.totalAmount,
    );

    final totalTransactions = relevantUsers.fold<int>(
      0,
      (sum, user) => sum + user.totalExpenses,
    );

    final averagePerTransaction =
        totalTransactions > 0 ? totalAmount / totalTransactions : 0.0;

    // Category breakdown
    final categoryBreakdown = <String, double>{};
    final categoryTransactionCounts = <String, int>{};

    for (final user in relevantUsers) {
      user.categorySpending.forEach((category, amount) {
        categoryBreakdown[category] =
            (categoryBreakdown[category] ?? 0.0) + amount;
        categoryTransactionCounts[category] =
            (categoryTransactionCounts[category] ?? 0) + 1;
      });
    }

    // Find top category
    String topCategory = 'None';
    double topCategoryAmount = 0.0;

    if (categoryBreakdown.isNotEmpty) {
      final topEntry = categoryBreakdown.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );
      topCategory = topEntry.key;
      topCategoryAmount = topEntry.value;
    }

    // Generate trends (simplified for demo)
    final dailyTrends = _generateDailyTrends(start, end, totalAmount);
    final monthlyTrends = _generateMonthlyTrends(start, end, totalAmount);

    // Top spenders
    final topSpenders = relevantUsers
        .map((user) => {
              'userId': user.userId,
              'userName': user.userName,
              'totalAmount': user.totalAmount,
              'totalExpenses': user.totalExpenses,
            })
        .toList()
      ..sort((a, b) =>
          (b['totalAmount'] as double).compareTo(a['totalAmount'] as double))
      ..take(10);

    return ExpenseAnalytics(
      periodStart: start,
      periodEnd: end,
      totalAmount: totalAmount,
      totalTransactions: totalTransactions,
      averagePerTransaction: averagePerTransaction,
      categoryBreakdown: categoryBreakdown,
      categoryTransactionCounts: categoryTransactionCounts,
      dailyTrends: dailyTrends,
      monthlyTrends: monthlyTrends,
      topCategory: topCategory,
      topCategoryAmount: topCategoryAmount,
      topSpenders: topSpenders.toList(),
    );
  }

  // Get category usage statistics
  Map<String, dynamic> getCategoryStats() {
    final allCategories = <String>{};
    final categoryUsage = <String, int>{};
    final categoryRevenue = <String, double>{};

    for (final user in _userData) {
      user.categorySpending.forEach((category, amount) {
        allCategories.add(category);
        categoryUsage[category] = (categoryUsage[category] ?? 0) + 1;
        categoryRevenue[category] = (categoryRevenue[category] ?? 0.0) + amount;
      });
    }

    // Most popular categories
    final popularCategories = categoryUsage.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Highest revenue categories
    final revenueCategories = categoryRevenue.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'totalCategories': allCategories.length,
      'categoryUsage': categoryUsage,
      'categoryRevenue': categoryRevenue,
      'mostPopularCategories': popularCategories.take(5).toList(),
      'highestRevenueCategories': revenueCategories.take(5).toList(),
      'averageRevenuePerCategory': allCategories.isNotEmpty
          ? categoryRevenue.values.reduce((a, b) => a + b) /
              allCategories.length
          : 0.0,
    };
  }

  // Get user engagement metrics
  Map<String, dynamic> getUserEngagementMetrics() {
    final now = DateTime.now();
    final last7Days = now.subtract(Duration(days: 7));
    final last30Days = now.subtract(Duration(days: 30));

    final activeUsersLast7Days = _userData
        .where(
          (user) => user.lastActiveDate.isAfter(last7Days),
        )
        .length;

    final activeUsersLast30Days = _userData
        .where(
          (user) => user.lastActiveDate.isAfter(last30Days),
        )
        .length;

    final newUsersLast7Days = _userData
        .where(
          (user) => user.registrationDate.isAfter(last7Days),
        )
        .length;

    final newUsersLast30Days = _userData
        .where(
          (user) => user.registrationDate.isAfter(last30Days),
        )
        .length;

    // Calculate retention rate (users active in last 7 days who registered more than 7 days ago)
    final eligibleForRetention = _userData
        .where(
          (user) => user.registrationDate.isBefore(last7Days),
        )
        .length;

    final retainedUsers = _userData
        .where(
          (user) =>
              user.registrationDate.isBefore(last7Days) &&
              user.lastActiveDate.isAfter(last7Days),
        )
        .length;

    final retentionRate = eligibleForRetention > 0
        ? (retainedUsers / eligibleForRetention) * 100
        : 0.0;

    return {
      'activeUsersLast7Days': activeUsersLast7Days,
      'activeUsersLast30Days': activeUsersLast30Days,
      'newUsersLast7Days': newUsersLast7Days,
      'newUsersLast30Days': newUsersLast30Days,
      'retentionRate': retentionRate,
      'averageExpensesPerActiveUser': activeUsersLast30Days > 0
          ? _userData
                  .where((user) => user.lastActiveDate.isAfter(last30Days))
                  .map((user) => user.totalExpenses)
                  .reduce((a, b) => a + b) /
              activeUsersLast30Days
          : 0.0,
      'churnRate': _userData.isNotEmpty
          ? ((_userData.length - activeUsersLast30Days) / _userData.length) *
              100
          : 0.0,
    };
  }

  // Get system performance metrics
  Map<String, dynamic> getSystemMetrics() {
    return {
      ..._systemMetrics,
      'lastUpdated': _lastDataSync?.toIso8601String(),
      'dataPoints': _userData.length,
      'storageUsed': _calculateStorageUsage(),
    };
  }

  // Export analytics data
  Future<Map<String, dynamic>> exportAnalyticsData({
    DateTime? startDate,
    DateTime? endDate,
    List<String>? includeMetrics,
  }) async {
    try {
      final analytics = getExpenseAnalytics(
        startDate: startDate,
        endDate: endDate,
      );

      final platformStats = getPlatformStats();
      final categoryStats = getCategoryStats();
      final engagementMetrics = getUserEngagementMetrics();

      final exportData = {
        'exportTimestamp': DateTime.now().toIso8601String(),
        'periodStart': analytics.periodStart.toIso8601String(),
        'periodEnd': analytics.periodEnd.toIso8601String(),
        'platformStats': includeMetrics?.contains('platformStats') ?? true
            ? platformStats
            : null,
        'expenseAnalytics': includeMetrics?.contains('expenseAnalytics') ?? true
            ? {
                'totalAmount': analytics.totalAmount,
                'totalTransactions': analytics.totalTransactions,
                'averagePerTransaction': analytics.averagePerTransaction,
                'categoryBreakdown': analytics.categoryBreakdown,
                'categoryTransactionCounts':
                    analytics.categoryTransactionCounts,
                'topCategory': analytics.topCategory,
                'topCategoryAmount': analytics.topCategoryAmount,
                'topSpenders': analytics.topSpenders,
              }
            : null,
        'categoryStats': includeMetrics?.contains('categoryStats') ?? true
            ? categoryStats
            : null,
        'engagementMetrics':
            includeMetrics?.contains('engagementMetrics') ?? true
                ? engagementMetrics
                : null,
        'systemMetrics': includeMetrics?.contains('systemMetrics') ?? true
            ? getSystemMetrics()
            : null,
      };

      return exportData;
    } catch (e) {
      throw Exception('Failed to export analytics data: $e');
    }
  }

  // Helper method to generate daily trends
  List<Map<String, dynamic>> _generateDailyTrends(
    DateTime start,
    DateTime end,
    double totalAmount,
  ) {
    final days = end.difference(start).inDays + 1;
    final random = math.Random();
    final dailyAmount = totalAmount / days;

    return List.generate(days, (index) {
      final date = start.add(Duration(days: index));
      final variance = (random.nextDouble() - 0.5) * 0.4; // ±20% variance

      return {
        'date': date.toIso8601String(),
        'amount': dailyAmount * (1 + variance),
        'transactions': (dailyAmount * (1 + variance) / 50)
            .round(), // Assuming average transaction of $50
      };
    });
  }

  // Helper method to generate monthly trends
  List<Map<String, dynamic>> _generateMonthlyTrends(
    DateTime start,
    DateTime end,
    double totalAmount,
  ) {
    final months = (end.year - start.year) * 12 + end.month - start.month + 1;
    final random = math.Random();
    final monthlyAmount = totalAmount / months;

    return List.generate(months, (index) {
      final date = DateTime(
        start.year,
        start.month + index,
        1,
      );
      final variance = (random.nextDouble() - 0.5) * 0.3; // ±15% variance

      return {
        'month': date.toIso8601String(),
        'amount': monthlyAmount * (1 + variance),
        'transactions': (monthlyAmount * (1 + variance) / 50).round(),
      };
    });
  }

  // Helper method to calculate storage usage
  double _calculateStorageUsage() {
    final userDataString = json.encode(_userData);
    final metricsString = json.encode(_systemMetrics);

    // Approximate storage in KB
    return (userDataString.length + metricsString.length) / 1024;
  }

  // Helper method to get default system metrics
  Map<String, dynamic> _getDefaultSystemMetrics() {
    return {
      'version': '1.0.0',
      'startTime': DateTime.now().toIso8601String(),
      'dataVersion': '1',
      'isHealthy': true,
      'performanceMetrics': {
        'averageResponseTime': 0.0,
        'errorRate': 0.0,
        'uptime': 0,
      },
    };
  }

  // Helper method to generate sample data for demo purposes
  Future<void> _generateSampleData() async {
    if (_userData.isEmpty) {
      final random = math.Random();
      final categories = [
        'Food',
        'Transportation',
        'Shopping',
        'Entertainment',
        'Healthcare',
      ];

      for (var i = 0; i < 100; i++) {
        final user = UserData(
          userId: 'user_$i',
          userName: 'User ${i + 1}',
          email: 'user${i + 1}@example.com',
          registrationDate: DateTime.now().subtract(
            Duration(days: random.nextInt(365)),
          ),
          lastActiveDate: DateTime.now().subtract(
            Duration(days: random.nextInt(30)),
          ),
          totalExpenses: random.nextInt(100) + 50,
          totalAmount: (random.nextDouble() * 5000) + 1000,
          favoriteCategories: categories.take(random.nextInt(3) + 1).toList(),
          categorySpending: Map.fromEntries(
            categories.map((category) => MapEntry(
                  category,
                  (random.nextDouble() * 1000) + 100,
                )),
          ),
          monthlyExpenseCounts: Map.fromEntries(
            List.generate(
                12,
                (index) => MapEntry(
                      '${DateTime.now().year}-${index + 1}',
                      random.nextInt(30) + 10,
                    )),
          ),
        );
        _userData.add(user);
      }

      await _saveUserData();
    }
  }

  // Helper methods for state management
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
