import 'package:ExpenseTracker/Services/BudgetController.dart';
import 'package:ExpenseTracker/Services/CategoriesService.dart';
import 'package:flutter/material.dart';
import 'dart:developer';

class BudgetService {
  final BudgetController _budgetController = BudgetController();

  /// Get all available categories for budget creation
  Future<List<Map<String, dynamic>>> getAvailableCategories(
      String email) async {
    try {
      return await DefaultCategoriesService.getAllCategories(email);
    } catch (e) {
      log("Error getting available categories: $e");
      return [];
    }
  }

  /// Create a new budget with validation
  Future<Map<String, dynamic>> createBudget({
    required String budgetName,
    required double budgetAmount,
    required String budgetPeriod,
    required List<String> categoryIds,
    DateTime? startDate,
    DateTime? endDate,
    String? description,
  }) async {
    // Validation
    if (budgetName.trim().isEmpty) {
      return {
        'success': false,
        'message': "Budget name cannot be empty.",
      };
    }

    if (budgetAmount <= 0) {
      return {
        'success': false,
        'message': "Budget amount must be greater than 0.",
      };
    }

    if (categoryIds.isEmpty) {
      return {
        'success': false,
        'message': "Please select at least one category.",
      };
    }

    if (!BudgetController.getAllowedPeriods().contains(budgetPeriod)) {
      return {
        'success': false,
        'message': "Invalid budget period selected.",
      };
    }

    return await _budgetController.createBudget(
      budgetName: budgetName,
      budgetAmount: budgetAmount,
      budgetPeriod: budgetPeriod,
      categoryIds: categoryIds,
      startDate: startDate,
      endDate: endDate,
      description: description,
    );
  }

  /// Update an existing budget
  Future<Map<String, dynamic>> updateBudget({
    required String budgetId,
    String? budgetName,
    double? budgetAmount,
    String? budgetPeriod,
    List<String>? categoryIds,
    DateTime? startDate,
    DateTime? endDate,
    String? description,
    bool? isActive,
  }) async {
    // Validation
    if (budgetName != null && budgetName.trim().isEmpty) {
      return {
        'success': false,
        'message': "Budget name cannot be empty.",
      };
    }

    if (budgetAmount != null && budgetAmount <= 0) {
      return {
        'success': false,
        'message': "Budget amount must be greater than 0.",
      };
    }

    if (categoryIds != null && categoryIds.isEmpty) {
      return {
        'success': false,
        'message': "Please select at least one category.",
      };
    }

    if (budgetPeriod != null &&
        !BudgetController.getAllowedPeriods().contains(budgetPeriod)) {
      return {
        'success': false,
        'message': "Invalid budget period selected.",
      };
    }

    return await _budgetController.updateBudget(
      budgetId: budgetId,
      budgetName: budgetName,
      budgetAmount: budgetAmount,
      budgetPeriod: budgetPeriod,
      categoryIds: categoryIds,
      startDate: startDate,
      endDate: endDate,
      description: description,
      isActive: isActive,
    );
  }

  /// Delete a budget
  Future<Map<String, dynamic>> deleteBudget(String budgetId) async {
    return await _budgetController.deleteBudget(budgetId);
  }

  /// Get all budgets with their tracking information
  Future<List<Map<String, dynamic>>> getAllBudgetsWithTracking() async {
    return await _budgetController.getAllBudgetsWithTracking();
  }

  /// Get budget details by ID
  Future<Map<String, dynamic>?> getBudgetById(String budgetId) async {
    return await _budgetController.getBudgetById(budgetId);
  }

  /// Get budget tracking information
  Future<Map<String, dynamic>> getBudgetTracking(String budgetId) async {
    return await _budgetController.getBudgetTracking(budgetId);
  }

  /// Get budget alerts (budgets that are near limit or over budget)
  Future<List<Map<String, dynamic>>> getBudgetAlerts() async {
    return await _budgetController.getBudgetAlerts();
  }

  /// Get category-wise spending for a budget
  Future<Map<String, double>> getCategoryWiseSpending(String budgetId) async {
    return await _budgetController.getCategoryWiseSpending(budgetId: budgetId);
  }

  /// Get budget summary
  Future<Map<String, dynamic>> getBudgetSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _budgetController.getBudgetSummary(
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Get budget status color based on spent percentage
  Color getBudgetStatusColor(double spentPercentage) {
    if (spentPercentage >= 100) {
      return Colors.red;
    } else if (spentPercentage >= 90) {
      return Colors.orange;
    } else if (spentPercentage >= 75) {
      return Colors.amber;
    } else {
      return Colors.green;
    }
  }

  /// Get budget status icon based on spent percentage
  IconData getBudgetStatusIcon(double spentPercentage) {
    if (spentPercentage >= 100) {
      return Icons.error;
    } else if (spentPercentage >= 90) {
      return Icons.warning;
    } else if (spentPercentage >= 75) {
      return Icons.info;
    } else {
      return Icons.check_circle;
    }
  }

  /// Format currency amount
  String formatCurrency(double amount) {
    return 'PKR ${amount.toStringAsFixed(2)}';
  }

  /// Format percentage
  String formatPercentage(double percentage) {
    return '${percentage.toStringAsFixed(1)}%';
  }

  /// Get budget period options
  List<String> getBudgetPeriods() {
    return [
      BudgetController.WEEKLY,
      BudgetController.MONTHLY,
      BudgetController.YEARLY,
    ];
  }

  /// Get budget recommendation based on spending history
  Future<Map<String, dynamic>> getBudgetRecommendation({
    required List<String> categoryIds,
    required String budgetPeriod,
    int historyMonths = 3,
  }) async {
    try {
      // Get spending history for the selected categories
      DateTime endDate = DateTime.now();
      DateTime startDate =
          DateTime.now().subtract(Duration(days: historyMonths * 30));

      // This would need to be implemented based on your transaction history
      // For now, returning a simple recommendation structure
      return {
        'success': true,
        'recommendedAmount': 0.0,
        'averageSpending': 0.0,
        'message':
            'Based on your spending history, we recommend setting a budget.',
      };
    } catch (e) {
      log("Error getting budget recommendation: $e");
      return {
        'success': false,
        'message': "Unable to calculate budget recommendation.",
      };
    }
  }

  /// Validate budget dates
  Map<String, dynamic> validateBudgetDates({
    required DateTime startDate,
    required DateTime endDate,
    required String budgetPeriod,
  }) {
    // Check if start date is in the future (more than 7 days)
    if (startDate.difference(DateTime.now()).inDays > 7) {
      return {
        'isValid': false,
        'message': "Start date cannot be more than 7 days in the future.",
      };
    }

    // Check if end date is before start date
    if (endDate.isBefore(startDate)) {
      return {
        'isValid': false,
        'message': "End date cannot be before start date.",
      };
    }

    // Check if the period matches the selected budget period
    int daysDifference = endDate.difference(startDate).inDays;

    switch (budgetPeriod) {
      case BudgetController.WEEKLY:
        if (daysDifference < 6 || daysDifference > 8) {
          return {
            'isValid': false,
            'message':
                "For weekly budgets, the period should be approximately 7 days.",
          };
        }
        break;
      case BudgetController.MONTHLY:

        /// Validate budget dates (continuation from your existing code)
        /// Validate budget dates (continuation from your existing code)
        if (daysDifference < 28 || daysDifference > 32) {
          return {
            'isValid': false,
            'message':
                "For monthly budgets, the period should be approximately 30 days.",
          };
        }
        break;
      case BudgetController.YEARLY:
        if (daysDifference < 360 || daysDifference > 370) {
          return {
            'isValid': false,
            'message':
                "For yearly budgets, the period should be approximately 365 days.",
          };
        }
        break;
      default:
        return {
          'isValid': false,
          'message': "Invalid budget period selected.",
        };
    }

    return {
      'isValid': true,
      'message': "Budget dates are valid.",
    };
  }

  /// Get budget status text based on spent percentage
  String getBudgetStatusText(double spentPercentage) {
    if (spentPercentage >= 100) {
      return 'Over Budget';
    } else if (spentPercentage >= 90) {
      return 'Near Limit';
    } else if (spentPercentage >= 75) {
      return 'Warning';
    } else {
      return 'On Track';
    }
  }

  /// Calculate budget progress color opacity based on spent percentage
  double getBudgetProgressOpacity(double spentPercentage) {
    if (spentPercentage >= 100) {
      return 1.0;
    } else if (spentPercentage >= 75) {
      return 0.8;
    } else if (spentPercentage >= 50) {
      return 0.6;
    } else {
      return 0.4;
    }
  }

  /// Get budget priority level (1-5, 5 being highest priority)
  int getBudgetPriorityLevel(double spentPercentage, int daysRemaining) {
    if (spentPercentage >= 100) {
      return 5; // Critical - Over budget
    } else if (spentPercentage >= 90) {
      return 4; // High - Near limit
    } else if (spentPercentage >= 75) {
      return 3; // Medium - Warning
    } else if (daysRemaining <= 3 && spentPercentage >= 50) {
      return 3; // Medium - Time-sensitive
    } else {
      return 1; // Low - On track
    }
  }

  /// Format time remaining text
  String formatTimeRemaining(DateTime endDate) {
    DateTime now = DateTime.now();
    Duration difference = endDate.difference(now);

    if (difference.isNegative) {
      return "Expired";
    }

    int days = difference.inDays;
    int hours = difference.inHours % 24;

    if (days > 0) {
      return days == 1 ? "1 day remaining" : "$days days remaining";
    } else if (hours > 0) {
      return hours == 1 ? "1 hour remaining" : "$hours hours remaining";
    } else {
      return "Less than 1 hour remaining";
    }
  }

  /// Get next budget period start date
  DateTime getNextBudgetPeriodStart(
      DateTime currentEndDate, String budgetPeriod) {
    switch (budgetPeriod) {
      case BudgetController.WEEKLY:
        return currentEndDate.add(const Duration(days: 1));
      case BudgetController.MONTHLY:
        return DateTime(currentEndDate.year, currentEndDate.month + 1, 1);
      case BudgetController.YEARLY:
        return DateTime(currentEndDate.year + 1, 1, 1);
      default:
        return currentEndDate.add(const Duration(days: 1));
    }
  }

  /// Check if budget period is valid for the selected dates
  bool isBudgetPeriodValid(
      DateTime startDate, DateTime endDate, String budgetPeriod) {
    int daysDifference = endDate.difference(startDate).inDays;

    switch (budgetPeriod) {
      case BudgetController.WEEKLY:
        return daysDifference >= 6 && daysDifference <= 8;
      case BudgetController.MONTHLY:
        return daysDifference >= 28 && daysDifference <= 32;
      case BudgetController.YEARLY:
        return daysDifference >= 360 && daysDifference <= 370;
      default:
        return false;
    }
  }

  /// Get suggested budget amount based on category and period
  Future<double> getSuggestedBudgetAmount({
    required List<String> categoryIds,
    required String budgetPeriod,
    int historyMonths = 6,
  }) async {
    try {
      // Get spending history for the selected categories
      DateTime endDate = DateTime.now();
      DateTime startDate = endDate.subtract(Duration(days: historyMonths * 30));

      // This is a simplified calculation - you might want to implement
      // more sophisticated algorithms based on your transaction data
      double totalSpent = 0;
      int periodCount = 0;

      switch (budgetPeriod) {
        case BudgetController.WEEKLY:
          periodCount = (historyMonths * 4.33).round(); // Approximate weeks
          break;
        case BudgetController.MONTHLY:
          periodCount = historyMonths;
          break;
        case BudgetController.YEARLY:
          periodCount = 1;
          break;
      }

      // Calculate average and add 10% buffer
      double averageSpending = periodCount > 0 ? totalSpent / periodCount : 0;
      return averageSpending * 1.1; // Add 10% buffer
    } catch (e) {
      log("Error getting suggested budget amount: $e");
      return 0.0;
    }
  }

  /// Get budget health score (0-100)
  double getBudgetHealthScore(
      double spentPercentage, int daysRemaining, int totalDays) {
    if (spentPercentage >= 100) {
      return 0; // Over budget = 0 health
    }

    double timeProgress =
        totalDays > 0 ? (totalDays - daysRemaining) / totalDays : 0;
    double idealSpentPercentage = timeProgress * 100;

    if (spentPercentage <= idealSpentPercentage) {
      return 100; // Perfect or under ideal spending
    } else {
      // Calculate score based on how far over the ideal spending
      double overSpent = spentPercentage - idealSpentPercentage;
      double penalty = overSpent * 2; // Penalty factor
      return (100 - penalty).clamp(0, 100);
    }
  }

  /// Get budget trend (improving, stable, declining)
  String getBudgetTrend(List<double> weeklySpentAmounts) {
    if (weeklySpentAmounts.length < 2) {
      return 'Stable';
    }

    double recentAverage =
        weeklySpentAmounts.take(2).reduce((a, b) => a + b) / 2;
    double olderAverage =
        weeklySpentAmounts.skip(2).take(2).reduce((a, b) => a + b) / 2;

    if (recentAverage < olderAverage * 0.9) {
      return 'Improving';
    } else if (recentAverage > olderAverage * 1.1) {
      return 'Declining';
    } else {
      return 'Stable';
    }
  }

  /// Get all allowed budget periods
  static List<String> getAllowedPeriods() {
    return [
      BudgetController.WEEKLY,
      BudgetController.MONTHLY,
      BudgetController.YEARLY,
    ];
  }

  /// Validate budget amount
  Map<String, dynamic> validateBudgetAmount(
      double amount, String budgetPeriod) {
    if (amount <= 0) {
      return {
        'isValid': false,
        'message': "Budget amount must be greater than 0.",
      };
    }

    // Set reasonable limits based on period
    double maxAmount;
    switch (budgetPeriod) {
      case BudgetController.WEEKLY:
        maxAmount = 1000000; // 1M PKR per week
        break;
      case BudgetController.MONTHLY:
        maxAmount = 10000000; // 10M PKR per month
        break;
      case BudgetController.YEARLY:
        maxAmount = 100000000; // 100M PKR per year
        break;
      default:
        maxAmount = 1000000;
    }

    if (amount > maxAmount) {
      return {
        'isValid': false,
        'message':
            "Budget amount exceeds maximum limit of ${formatCurrency(maxAmount)}.",
      };
    }

    return {
      'isValid': true,
      'message': "Budget amount is valid.",
    };
  }

  /// Get budget categories summary
  Future<Map<String, dynamic>> getBudgetCategoriesSummary(
      String budgetId) async {
    try {
      Map<String, double> categorySpending =
          await getCategoryWiseSpending(budgetId);

      if (categorySpending.isEmpty) {
        return {
          'success': false,
          'message': "No spending data found for this budget.",
        };
      }

      String topSpendingCategory = '';
      double highestSpending = 0;
      double totalSpending = 0;

      categorySpending.forEach((category, amount) {
        totalSpending += amount;
        if (amount > highestSpending) {
          highestSpending = amount;
          topSpendingCategory = category;
        }
      });

      return {
        'success': true,
        'totalCategories': categorySpending.length,
        'totalSpending': totalSpending,
        'topSpendingCategory': topSpendingCategory,
        'topSpendingAmount': highestSpending,
        'topSpendingPercentage':
            totalSpending > 0 ? (highestSpending / totalSpending) * 100 : 0,
        'categoryBreakdown': categorySpending,
      };
    } catch (e) {
      log("Error getting budget categories summary: $e");
      return {
        'success': false,
        'message': "Error calculating categories summary: ${e.toString()}",
      };
    }
  }

  /// Format duration text
  String formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return "${duration.inDays} days";
    } else if (duration.inHours > 0) {
      return "${duration.inHours} hours";
    } else {
      return "${duration.inMinutes} minutes";
    }
  }

  /// Dispose resources
  void dispose() {
    // Clean up any resources if needed
    // Currently no resources to dispose
  }
}
