import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class ExpensePieChart extends StatefulWidget {
  final String month;

  const ExpensePieChart({
    Key? key,
    required this.month,
  }) : super(key: key);

  @override
  State<ExpensePieChart> createState() => _ExpensePieChartState();
}

class _ExpensePieChartState extends State<ExpensePieChart> {
  late List<Map<String, dynamic>> categoryData = [];
  double totalExpenses = 0;
  Map<String, Color> categoryColors = {};
  int? touchedIndex;

  Color _hexToColor(String hexString) {
    try {
      hexString = hexString.replaceAll('#', '');
      if (hexString.length == 6) {
        return Color(int.parse('FF$hexString', radix: 16));
      }
      return const Color.fromRGBO(126, 61, 255, 1);
    } catch (e) {
      return const Color.fromRGBO(126, 61, 255, 1);
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchCategoryExpenses();
  }

  @override
  void didUpdateWidget(ExpensePieChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.month != widget.month) {
      _fetchCategoryExpenses();
    }
  }

  Future<void> _fetchCategoryExpenses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email');

      if (email == null) return;

      // Get the start and end date for the selected month
      final now = DateTime.now();
      final selectedMonth = DateFormat('MMMM').parse(widget.month);
      final startDate = DateTime(now.year, selectedMonth.month, 1);
      final endDate =
          DateTime(now.year, selectedMonth.month + 1, 0, 23, 59, 59);

      // First get all categories to get their colors
      final QuerySnapshot categoriesSnapshot = await FirebaseFirestore.instance
          .collection('categories')
          .where('email', isEqualTo: email)
          .get();

      // Create a map of category names to their colors
      categoryColors = {};
      for (var doc in categoriesSnapshot.docs) {
        final categoryName = doc['name'] as String;
        final iconColor =
            doc['iconColor'] as String; // Get the hex color string
        categoryColors[categoryName] =
            _hexToColor(iconColor); // Convert hex to Color
      }

      // Get transactions for the month
      final QuerySnapshot transactionsSnapshot = await FirebaseFirestore
          .instance
          .collection('transactions')
          .where('email', isEqualTo: email)
          .where('transaction_type', isEqualTo: 'Expense')
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      // Calculate expenses by category
      Map<String, double> categoryExpenses = {};

      for (var doc in transactionsSnapshot.docs) {
        final categoryName = doc['category_name'] as String;
        final amount = (doc['amount'] as num).toDouble();
        categoryExpenses[categoryName] =
            (categoryExpenses[categoryName] ?? 0) + amount;
      }

      // Convert to sorted list with colors
      List<Map<String, dynamic>> tempData = categoryExpenses.entries
          .map((entry) => {
                'name': entry.key,
                'spend': entry.value,
                'color': categoryColors[entry.key] ??
                    const Color.fromRGBO(126, 61, 255, 1),
              })
          .toList();

      tempData.sort(
          (a, b) => (b['spend'] as double).compareTo(a['spend'] as double));

      double total =
          tempData.fold(0, (sum, item) => sum + (item['spend'] as double));

      setState(() {
        categoryData = tempData;
        totalExpenses = total;
      });
    } catch (e) {
      print('Error fetching expense data: $e');
      setState(() {
        categoryData = [];
        totalExpenses = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (categoryData.isEmpty) {
      return Container(
        height: 350,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.pie_chart_outline,
                size: 48,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'No expense data available for this month',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 500, // Increased height for better spacing
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 5,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                Text(
                  'Expense Distribution',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color.fromRGBO(51, 51, 51, 1),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.month,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Pie Chart
          AspectRatio(
            aspectRatio: 1.5,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        touchedIndex = -1;
                        return;
                      }
                      touchedIndex =
                          pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                sectionsSpace: 3,
                centerSpaceRadius: 40,
                sections: categoryData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value;
                  final percentage = (data['spend'] / totalExpenses) * 100;
                  final isTouched = index == touchedIndex;
                  final double fontSize = isTouched ? 18 : 14;
                  final double radius = isTouched ? 90 : 80;
                  final Color color = data['color'] as Color;

                  return PieChartSectionData(
                    color: color.withOpacity(isTouched ? 1 : 0.9),
                    value: data['spend'],
                    title: '${percentage.toStringAsFixed(1)}%',
                    radius: radius,
                    titleStyle: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: const [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Legend
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 16,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: categoryData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value;
                  final percentage = (data['spend'] / totalExpenses) * 100;
                  final isSelected = index == touchedIndex;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.all(isSelected ? 8 : 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (data['color'] as Color).withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: data['color'] as Color,
                            borderRadius: BorderRadius.circular(3),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    (data['color'] as Color).withOpacity(0.3),
                                spreadRadius: 1,
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['name'] as String,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? data['color'] as Color
                                    : Colors.black87,
                              ),
                            ),
                            Text(
                              'Rs${data['spend'].toStringAsFixed(0)} (${percentage.toStringAsFixed(1)}%)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
