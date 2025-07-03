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
  List<Map<String, dynamic>> categoryData = [];
  double totalExpenses = 0;
  Map<String, Color> categoryColors = {};
  int? touchedIndex;
  bool isLoading = true;

  // Fallback colors for categories if global categories don't have colors
  final List<Color> _fallbackColors = [
    const Color(0xFFFF5722), // Red Orange
    const Color(0xFF2196F3), // Blue
    const Color(0xFF4CAF50), // Green
    const Color(0xFF9C27B0), // Purple
    const Color(0xFFFF9800), // Orange
    const Color(0xFFF44336), // Red
    const Color(0xFF00BCD4), // Cyan
    const Color(0xFFE91E63), // Pink
    const Color(0xFF607D8B), // Blue Grey
    const Color(0xFFFFC107), // Amber
    const Color(0xFF3F51B5), // Indigo
    const Color(0xFF009688), // Teal
    const Color(0xFF795548), // Brown
    const Color(0xFF8BC34A), // Light Green
    const Color(0xFFFF6F00), // Deep Orange
  ];

  Color _hexToColor(String hexString) {
    try {
      hexString = hexString.replaceAll('#', '');
      if (hexString.length == 6) {
        return Color(int.parse('FF$hexString', radix: 16));
      }
      return const Color(0xFF7E3DFF);
    } catch (e) {
      return const Color(0xFF7E3DFF);
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
      setState(() {
        isLoading = true;
      });
      _fetchCategoryExpenses();
    }
  }

  Future<void> _fetchCategoryExpenses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email');

      if (email == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Parse the month properly - handle both current year and make it more robust
      final now = DateTime.now();
      DateTime startDate;
      DateTime endDate;

      try {
        // Try to parse the month name to get the month number
        final monthNames = [
          'January',
          'February',
          'March',
          'April',
          'May',
          'June',
          'July',
          'August',
          'September',
          'October',
          'November',
          'December'
        ];

        final monthIndex = monthNames.indexOf(widget.month) + 1;

        if (monthIndex > 0) {
          startDate = DateTime(now.year, monthIndex, 1);
          endDate = DateTime(now.year, monthIndex + 1, 0, 23, 59, 59);
        } else {
          // Fallback to current month if parsing fails
          startDate = DateTime(now.year, now.month, 1);
          endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        }
      } catch (e) {
        // Fallback to current month if parsing fails
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      }

      // Fetch global categories for color mapping
      final QuerySnapshot globalCategoriesSnapshot = await FirebaseFirestore
          .instance
          .collection('global_categories')
          .get();

      // Create a map of category names to their colors from global categories
      categoryColors = {};
      for (var doc in globalCategoriesSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final categoryName = data['name'] as String? ?? '';
        final iconColor = data['iconColor'] as String? ?? '';

        if (categoryName.isNotEmpty && iconColor.isNotEmpty) {
          categoryColors[categoryName] = _hexToColor(iconColor);
        }
      }

      // Get expense transactions for the month
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
        final data = doc.data() as Map<String, dynamic>;
        final categoryName = data['category_name'] as String? ?? 'Other';

        // Handle amount parsing (could be string or number)
        double amount = 0.0;
        final amountData = data['amount'];
        if (amountData is double) {
          amount = amountData;
        } else if (amountData is int) {
          amount = amountData.toDouble();
        } else if (amountData is String) {
          amount = double.tryParse(amountData) ?? 0.0;
        }

        categoryExpenses[categoryName] =
            (categoryExpenses[categoryName] ?? 0) + amount;
      }

      // Convert to sorted list with colors
      List<Map<String, dynamic>> tempData = [];
      int colorIndex = 0;

      for (var entry in categoryExpenses.entries) {
        // Get color for category, use fallback if not found
        Color categoryColor = categoryColors[entry.key] ??
            _fallbackColors[colorIndex % _fallbackColors.length];

        tempData.add({
          'name': entry.key,
          'spend': entry.value,
          'color': categoryColor,
        });
        colorIndex++;
      }

      // Sort by spend amount (highest first)
      tempData.sort(
          (a, b) => (b['spend'] as double).compareTo(a['spend'] as double));

      // Calculate total expenses
      double total =
          tempData.fold(0, (sum, item) => sum + (item['spend'] as double));

      setState(() {
        categoryData = tempData;
        totalExpenses = total;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching expense data: $e');
      setState(() {
        categoryData = [];
        totalExpenses = 0;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 500,
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
                const Text(
                  'Expense Distribution',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
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
                if (totalExpenses > 0)
                  Text(
                    'Total: Rs ${totalExpenses.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Loading or Content
          if (isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (categoryData.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.pie_chart_outline,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No expense data available for ${widget.month}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: Column(
                children: [
                  // Pie Chart
                  Expanded(
                    flex: 3,
                    child: PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback:
                              (FlTouchEvent event, pieTouchResponse) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  pieTouchResponse == null ||
                                  pieTouchResponse.touchedSection == null) {
                                touchedIndex = -1;
                                return;
                              }
                              touchedIndex = pieTouchResponse
                                  .touchedSection!.touchedSectionIndex;
                            });
                          },
                        ),
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: categoryData.asMap().entries.map((entry) {
                          final index = entry.key;
                          final data = entry.value;
                          final percentage =
                              (data['spend'] / totalExpenses) * 100;
                          final isTouched = index == touchedIndex;
                          final double fontSize = isTouched ? 16 : 12;
                          final double radius = isTouched ? 85 : 75;
                          final Color color = data['color'] as Color;

                          return PieChartSectionData(
                            color: color.withOpacity(isTouched ? 1.0 : 0.9),
                            value: data['spend'],
                            title: percentage > 5
                                ? '${percentage.toStringAsFixed(1)}%'
                                : '',
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
                    flex: 2,
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: categoryData.asMap().entries.map((entry) {
                          final index = entry.key;
                          final data = entry.value;
                          final percentage =
                              (data['spend'] / totalExpenses) * 100;
                          final isSelected = index == touchedIndex;

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: EdgeInsets.symmetric(
                              horizontal: isSelected ? 12 : 8,
                              vertical: isSelected ? 8 : 6,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (data['color'] as Color).withOpacity(0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: isSelected
                                  ? Border.all(
                                      color: (data['color'] as Color)
                                          .withOpacity(0.3),
                                      width: 1,
                                    )
                                  : null,
                            ),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  touchedIndex = isSelected ? -1 : index;
                                });
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: data['color'] as Color,
                                      borderRadius: BorderRadius.circular(2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: (data['color'] as Color)
                                              .withOpacity(0.3),
                                          spreadRadius: 1,
                                          blurRadius: 2,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          data['name'] as String,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isSelected
                                                ? data['color'] as Color
                                                : Colors.black87,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          'Rs ${data['spend'].toStringAsFixed(0)} (${percentage.toStringAsFixed(1)}%)',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
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
