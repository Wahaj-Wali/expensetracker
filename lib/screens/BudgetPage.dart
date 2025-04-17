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
                // Months Section (wrapped in black rounded container)
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
                        minWidth: MediaQuery.of(context).size.width / 3 -
                            20, // Divide width by 3 for each month
                      ),
                      isSelected: const [
                        false,
                        true,
                        false
                      ], // Middle month (selected) is true
                      onPressed: (index) {
                        // Handle month selection if needed
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
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: FutureBuilder<String>(
                      future: _getUserEmail(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        final email = snapshot.data!;
                        return StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('categories')
                              .where('email', isEqualTo: email)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }

                            List<Map<String, dynamic>> budgetItems =
                                snapshot.data!.docs.where((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final currentMonth =
                                  data['current_month'] as String? ?? '';
                              return currentMonth.startsWith(selectedMonth);
                            }).map((doc) {
                              final balance = doc['balance'] ?? 0.0;
                              final spend = doc['spend'] ?? 0.0;
                              final progress =
                                  (balance > 0) ? spend / balance : 0.0;
                              final remaining =
                                  (balance - spend).clamp(0.0, double.infinity);
                              bool alert = spend > balance;
                              String alertMessage =
                                  alert ? 'Youve exceeded the limit!' : '';

                              return {
                                'category': doc['name'],
                                'remaining':
                                    'Rs${remaining.toStringAsFixed(2)}',
                                'spent':
                                    'Rs${spend.toStringAsFixed(2)} of Rs${balance.toStringAsFixed(2)}',
                                'progress': progress.clamp(0.0, 1.0),
                                'progressColor': progress >= 1
                                    ? Colors.red
                                    : progress >= 0.5
                                        ? Colors.orange
                                        : Colors.green,
                                'alert': alert,
                                'alertMessage': alertMessage,
                              };
                            }).toList();

                            return ListView.builder(
                              padding: const EdgeInsets.all(10.0),
                              itemCount: budgetItems.length +
                                  1, // Add 1 for the "Create" card
                              itemBuilder: (context, index) {
                                if (index == budgetItems.length) {
                                  // "Create a budget" card
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const AddBudgetPage(),
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 20.0),
                                      child: Container(
                                        height: 150,
                                        decoration: BoxDecoration(
                                          color: const Color.fromRGBO(
                                              126, 61, 255, 0.297),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.grey.withOpacity(0.2),
                                              spreadRadius: 3,
                                              blurRadius: 12,
                                              offset: const Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        child: const Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.add,
                                                  color: Color.fromRGBO(
                                                      127, 61, 255, 1),
                                                  size: 40),
                                              SizedBox(height: 10),
                                              Text(
                                                "Create a budget",
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  color: Color.fromRGBO(
                                                      127, 61, 255, 1),
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

                                final item = budgetItems[index];
                                return GestureDetector(
                                  onTap: () => _goToDetailPage(item),
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 20.0),
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    left:
                                                        10.0), // Added left padding to align with "Remaining"
                                                child: Text(
                                                  item['category'],
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 25,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ),
                                              if (item['alert'])
                                                const Icon(Icons.error_outline,
                                                    color: Colors.red),
                                            ],
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 10.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
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
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 5.0),
                                                  child: LinearPercentIndicator(
                                                    width: MediaQuery.of(
                                                                context)
                                                            .size
                                                            .width -
                                                        50, // Adjusted to account for container padding
                                                    barRadius:
                                                        const Radius.circular(
                                                            10),
                                                    lineHeight: 10.0,
                                                    percent: item['progress'],
                                                    backgroundColor:
                                                        Colors.grey[300],
                                                    progressColor:
                                                        item['progressColor'],
                                                    padding: EdgeInsets.zero,
                                                  ),
                                                ),
                                                Text(
                                                  item['spent'],
                                                  style: const TextStyle(
                                                      color: Colors.grey),
                                                ),
                                                if (item['alert'])
                                                  Text(
                                                    item['alertMessage'],
                                                    style: const TextStyle(
                                                        color: Colors.red),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
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
      bottomNavigationBar: CustomBottomNavigationBar(
        activeIndex: _activeIndex,
      ),
      floatingActionButton: const CircularMenuWidget(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
