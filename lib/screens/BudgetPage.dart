import 'package:ExpenseTracker/Services/BudgetModificationController.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ExpenseTracker/screens/AddBudgetPage.dart';
import 'package:ExpenseTracker/screens/DetailBudgetPage.dart';
import 'package:ExpenseTracker/widgets/CircularMenuWidget.dart';
import 'package:ExpenseTracker/widgets/CustomBottomNavigationBar.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  _BudgetPageState createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  final int _activeIndex = 2;
  int _currentMonthIndex = 4;
  final BudgetController _budgetController = BudgetController();

  final List<String> _months = [
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December"
  ];

  @override
  void initState() {
    super.initState();
    _setCurrentMonth();
  }

  Future<String> _getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('email') ?? '';
  }

  void _goToPreviousMonth() {
    setState(() {
      _currentMonthIndex =
          (_currentMonthIndex - 1 + _months.length) % _months.length;
    });
  }

  void _goToNextMonth() {
    setState(() {
      _currentMonthIndex = (_currentMonthIndex + 1) % _months.length;
    });
  }

  void _setCurrentMonth() {
    final currentMonth = DateTime.now().month - 1;
    setState(() {
      _currentMonthIndex = currentMonth;
    });
  }

  void _goToDetailPage(Map<String, dynamic> budgetItem) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailBudgetPage(budgetItem: budgetItem),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getBudgetItems() async {
    try {
      final selectedMonthNumber = _currentMonthIndex + 1;
      final currentYear = DateTime.now().year;

      // Get all budgets from BudgetController
      List<Map<String, dynamic>> allBudgets =
          await _budgetController.getAllBudgets();

      // Filter budgets based on selected month and current year
      List<Map<String, dynamic>> filteredBudgets = allBudgets.where((budget) {
        final budgetMonth = budget['current_month'] as int? ?? 0;
        final budgetYear = budget['current_year'] as int? ?? 0;

        // For monthly budgets, check if they match the selected month and year
        if (budget['period'] == 'monthly') {
          return budgetMonth == selectedMonthNumber &&
              budgetYear == currentYear;
        }
        // For yearly budgets, just check the year
        else if (budget['period'] == 'yearly') {
          return budgetYear == currentYear;
        }
        // For weekly budgets, include all from current year (you might want to refine this)
        else if (budget['period'] == 'weekly') {
          return budgetYear == currentYear;
        }
        // For custom periods, include all from current year
        else {
          return budgetYear == currentYear;
        }
      }).toList();

      // Transform budget data to match the expected format
      List<Map<String, dynamic>> budgetItems = filteredBudgets.map((budget) {
        final budgetLimit = (budget['budget_limit'] as num?)?.toDouble() ?? 0.0;
        final spend = (budget['spend'] as num?)?.toDouble() ?? 0.0;
        final progress = (budgetLimit > 0) ? spend / budgetLimit : 0.0;
        final remaining = (budgetLimit - spend).clamp(0.0, double.infinity);
        final isReached = budget['is_reached'] as bool? ?? false;
        final alertPercentage =
            (budget['alert_percentage'] as num?)?.toDouble() ?? 80.0;

        bool alert = spend >= budgetLimit || isReached;
        bool warning = !alert && (spend / budgetLimit) * 100 >= alertPercentage;

        String alertMessage = '';
        if (alert) {
          alertMessage =
              budget['alert_msg'] as String? ?? 'You\'ve exceeded the limit!';
        } else if (warning) {
          alertMessage = 'Approaching budget limit!';
        }

        Color progressColor;
        if (alert) {
          progressColor = Colors.red;
        } else if (warning) {
          progressColor = Colors.orange;
        } else {
          progressColor = Colors.green;
        }

        return {
          'id': budget['id'],
          'budget_id': budget['budget_id'],
          'category': budget['budget_name'],
          'description': budget['description'] ?? '',
          'remaining': 'Rs${remaining.toStringAsFixed(2)}',
          'spent':
              'Rs${spend.toStringAsFixed(2)} of Rs${budgetLimit.toStringAsFixed(2)}',
          'progress': progress.clamp(0.0, 1.0),
          'progressColor': progressColor,
          'alert': alert,
          'warning': warning,
          'alertMessage': alertMessage,
          'period': budget['period'],
          'budget_limit': budgetLimit,
          'spend': spend,
          'is_alert': budget['is_alert'] ?? false,
          'alert_percentage': alertPercentage,
          'created_at': budget['created_at'],
          'updated_at': budget['updated_at'],
        };
      }).toList();

      return budgetItems;
    } catch (e) {
      debugPrint("Error getting budget items: $e");
      return [];
    }
  }

  Widget _buildBudgetCard(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () => _goToDetailPage(item),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: Container(
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 3,
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['category'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 25,
                              color: Colors.black,
                            ),
                          ),
                          if (item['description'].isNotEmpty)
                            Text(
                              item['description'],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      // Period indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          item['period'].toString().toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Alert/Warning icon
                      if (item['alert'])
                        const Icon(Icons.error, color: Colors.red, size: 20)
                      else if (item['warning'])
                        const Icon(Icons.warning,
                            color: Colors.orange, size: 20),
                    ],
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      "Remaining ${item['remaining']}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5.0),
                      child: LinearPercentIndicator(
                        width: MediaQuery.of(context).size.width - 50,
                        barRadius: const Radius.circular(10),
                        lineHeight: 10.0,
                        percent: item['progress'],
                        backgroundColor: Colors.grey[300],
                        progressColor: item['progressColor'],
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    Text(
                      item['spent'],
                      style: const TextStyle(color: Colors.grey),
                    ),
                    if (item['alertMessage'].isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          item['alertMessage'],
                          style: TextStyle(
                            color: item['alert'] ? Colors.red : Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateBudgetCard() {
    return GestureDetector(
      onTap: () {
        Navigator.of(context)
            .push(
          MaterialPageRoute(
            builder: (context) => const AddBudgetPage(),
          ),
        )
            .then((_) {
          // Refresh the page when returning from AddBudgetPage
          setState(() {});
        });
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: Container(
          height: 150,
          decoration: BoxDecoration(
            color: const Color.fromRGBO(126, 61, 255, 0.297),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 3,
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add,
                  color: Color.fromRGBO(127, 61, 255, 1),
                  size: 40,
                ),
                SizedBox(height: 10),
                Text(
                  "Create a budget",
                  style: TextStyle(
                    fontSize: 18,
                    color: Color.fromRGBO(127, 61, 255, 1),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedMonth = _months[_currentMonthIndex];
    final previousMonth =
        _months[(_currentMonthIndex - 1 + _months.length) % _months.length];
    final nextMonth = _months[(_currentMonthIndex + 1) % _months.length];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Budget",
          style: TextStyle(
            color: Colors.black,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            height: 200,
            color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.2),
          ),
          SafeArea(
            child: Column(
              children: [
                // Months Section
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 6.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          spreadRadius: 0,
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ToggleButtons(
                      borderRadius: BorderRadius.circular(20),
                      fillColor: const Color.fromRGBO(126, 61, 255, 0.297),
                      selectedBorderColor: const Color(0xFFE8E8E8),
                      borderColor: const Color(0xFFE8E8E8),
                      selectedColor: const Color.fromRGBO(127, 61, 255, 1),
                      color: Colors.black,
                      constraints: BoxConstraints(
                        minHeight: 35.0,
                        minWidth: MediaQuery.of(context).size.width / 3 - 20,
                      ),
                      isSelected: const [false, true, false],
                      onPressed: (index) {
                        if (index == 0) {
                          _goToPreviousMonth();
                        } else if (index == 2) {
                          _goToNextMonth();
                        }
                      },
                      renderBorder: true,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            previousMonth,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            selectedMonth,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            nextMonth,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Budget List
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: _getBudgetItems(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline,
                                    size: 48, color: Colors.red),
                                const SizedBox(height: 16),
                                Text(
                                  'Error loading budgets: ${snapshot.error}',
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {}); // Refresh
                                  },
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          );
                        }

                        final budgetItems = snapshot.data ?? [];

                        if (budgetItems.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              children: [
                                _buildCreateBudgetCard(),
                                const Expanded(
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.account_balance_wallet_outlined,
                                          size: 64,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          'No budgets found',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Create your first budget to start tracking your expenses',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.all(10.0),
                          itemCount:
                              budgetItems.length + 1, // +1 for create card
                          itemBuilder: (context, index) {
                            if (index == budgetItems.length) {
                              return _buildCreateBudgetCard();
                            }
                            return _buildBudgetCard(budgetItems[index]);
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
