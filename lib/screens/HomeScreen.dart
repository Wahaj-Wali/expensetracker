import 'package:ExpenseTracker/screens/ProfileScreen.dart';
import 'package:ExpenseTracker/widgets/expense_pie_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:ExpenseTracker/screens/TransactionPage.dart';
import 'package:ExpenseTracker/widgets/CircularMenuWidget.dart';
import 'package:ExpenseTracker/widgets/CustomBottomNavigationBar.dart';
import 'package:ExpenseTracker/widgets/custom_loader.dart';
import 'package:ExpenseTracker/widgets/line_chart_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Services/auth_service.dart';
import 'LoginPage.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService auth = AuthService(); // Add this line
  final int _activeIndex = 0;

  double totalBalance = 0.0;

  double totalIncome = 0.0;
  double totalExpense = 0.0;
  String currentMonth = DateFormat('MMMM').format(DateTime.now());

  List<Widget> transactionWidgets = [];

  void _logout() async {
    await auth.signout();
  }

  Future<void> fetchMonthlyIncomeAndExpense(String month) async {
    await CustomLoader.showLoaderForTask(
        context: context,
        task: () async {
          //Code
          SharedPreferences prefs = await SharedPreferences.getInstance();
          String? email = prefs.getString('email');
          double income = 0.0;
          double expense = 0.0;

          if (email == null) {
            // If email is not found in SharedPreferences, exit the method.
            print("No email found in SharedPreferences.");
            return;
          }

          try {
            // Query to fetch transactions from Firestore.
            QuerySnapshot querySnapshot = await FirebaseFirestore.instance
                .collection('transactions')
                .where('email', isEqualTo: email)
                .where('transaction_type',
                    whereIn: ['Income', 'Expense']).get();

            if (querySnapshot.docs.isEmpty) {
              print("No transactions found for this email.");
            }

            // Loop through each document in the snapshot.
            for (var doc in querySnapshot.docs) {
              // Extract timestamp and convert to DateTime.
              DateTime timestamp = (doc['timestamp'] as Timestamp).toDate();

              // Format the timestamp to extract the month name (e.g., "January").
              String transactionMonth = DateFormat('MMMM').format(timestamp);

              // Debugging: Check the formatted month
              print(
                  "Transaction Month: $transactionMonth, Selected Month: $month");

              // If the transaction month matches the selected month, process the transaction.
              if (transactionMonth == month) {
                double amount = doc['amount']?.toDouble() ??
                    0.0; // Ensure amount is a double.
                String type = doc['transaction_type'];

                // Add to income or expense depending on the transaction type.
                if (type == 'Income') {
                  income += amount;
                } else if (type == 'Expense') {
                  expense += amount;
                }
              }
            }

            // Update the UI with the total income and expense.
            setState(() {
              totalIncome = income;
              totalExpense = expense;
            });
          } catch (e) {
            print("Error fetching transactions: $e");
          }
        });
  }

  Future<void> fetchTotalBalance() async {
    await CustomLoader.showLoaderForTask(
        context: context,
        task: () async {
          //Code
          try {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            String? email = prefs.getString('email');

            if (email != null) {
              CollectionReference accounts =
                  FirebaseFirestore.instance.collection('accounts');
              QuerySnapshot querySnapshot =
                  await accounts.where('email', isEqualTo: email).get();

              // Initialize a variable to hold the sum of balances
              double totalBalanceSum = 0.0;

              // Loop through each document and sum up the balance field
              for (var document in querySnapshot.docs) {
                var balance = document.get('balance') ??
                    '0.0'; // Get balance as a string (default to '0.0')

                // Convert balance to double if it's a string
                if (balance is String) {
                  totalBalanceSum += double.tryParse(balance) ??
                      0.0; // Safely parse the string to double
                } else if (balance is double) {
                  totalBalanceSum +=
                      balance; // If balance is already a double, add it directly
                }
              }

              // Update state with the total balance sum
              setState(() {
                totalBalance = totalBalanceSum;
              });
            } else {
              setState(() {
                totalBalance = 0.0;
              });
            }
          } catch (e) {
            print("Error fetching balance: $e");
            setState(() {
              totalBalance = 0.0;
            });
          }
        });
  }

  Future<void> _checkPlanValidity() async {
    await CustomLoader.showLoaderForTask(
        context: context,
        task: () async {
          //Code
          final prefs = await SharedPreferences.getInstance();
          final email = prefs.getString('email'); // Retrieve the user's email

          if (email != null) {
            final userDoc = await FirebaseFirestore.instance
                .collection('authentication')
                .where('email', isEqualTo: email)
                .get();

            if (userDoc.docs.isNotEmpty) {
              final user = userDoc.docs.first;
              final userType = user['user_type'] as String?;

              // Check if the user is a premium user
              if (userType == 'premium user') {
                final planValidity = user.data().containsKey('plan_validity')
                    ? user['plan_validity'] as String?
                    : null;

                if (planValidity != null) {
                  final endDate = DateTime.parse(planValidity.split(' To ')[1]);
                  final currentDate = DateTime.now();

                  // Check if the plan validity date has passed
                  if (currentDate.isAfter(endDate)) {
                    await FirebaseFirestore.instance
                        .collection('authentication')
                        .doc(user.id)
                        .update({
                      'plan_validity': null,
                      'user_type': 'basic user',
                    });
                    print(
                        'Plan validity expired. User type updated to basic user.');
                  }
                }
              }
            }
          }
        });
  }

  @override
  void initState() {
    super.initState();
    fetchTotalBalance();

    _checkPlanValidity();
    _fetchTransactions();
    fetchMonthlyIncomeAndExpense(DateFormat('MMMM').format(DateTime.now()));
  }

  final Map<String, IconData> _flutterIcons = {
    'Restaurant': Icons.restaurant,
    'Dining': Icons.local_dining,
    'Fastfood': Icons.fastfood,
    'Cafe': Icons.local_cafe,
    'Cake': Icons.cake,

    // Transportation
    'Car': Icons.directions_car,
    'Bus': Icons.directions_bus,
    'Bike': Icons.directions_bike,
    'Taxi': Icons.local_taxi,

    // Utilities

    'Plumbing': Icons.plumbing,

    // Entertainment
    'Movie': Icons.movie,
    'M': Icons.music_note,
    'Games': Icons.sports_esports,
    'Ticket': Icons.local_movies,

    // Shopping
    'Groceries': Icons.shopping_cart,
    'Clothing': Icons.local_mall,

    // Health and Fitness
    'Gym': Icons.fitness_center,
    'Hospital': Icons.local_hospital,
    'Pharmacy': Icons.local_pharmacy,

    'FirstAid': Icons.healing,

    // Home and Rent
    'Rent': Icons.home,
    'Apartment': Icons.apartment,

    'Kitchen': Icons.kitchen,
    'Furniture': Icons.weekend,
    // Add more icons as needed
  };

  List<bool> isSelected = [true, false, false, false]; // Default to 'Today'
  List<Map<String, dynamic>> _transactions = [];

  void _onFilterChanged(int index) {
    setState(() {
      for (int i = 0; i < isSelected.length; i++) {
        isSelected[i] = i == index;
      }
    });
    _fetchTransactions(); // Re-fetch transactions based on the selected filter
  }

  void _fetchTransactions() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? email = prefs.getString('email');
      if (email == null) {
        print('Error: Email not found in shared preferences.');
        setState(() {
          _transactions = [];
        });
        return;
      }

      DateTime now = DateTime.now();
      DateTime startDate;
      DateTime endDate = now;

      if (isSelected[0]) {
        // Today
        startDate = DateTime(now.year, now.month, now.day);
        endDate = startDate.add(const Duration(days: 1));
      } else if (isSelected[1]) {
        // Week
        startDate = now.subtract(Duration(days: now.weekday - 1));
        endDate = startDate.add(const Duration(days: 7));
      } else if (isSelected[2]) {
        // Month
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 1);
      } else {
        // Year
        startDate = DateTime(now.year, 1, 1);
        endDate = DateTime(now.year + 1, 1, 1);
      }

      QuerySnapshot transactionsSnapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('email', isEqualTo: email)
          .where('transaction_type', whereIn: ['Expense', 'Income'])
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThan: Timestamp.fromDate(endDate))
          .get();

      if (transactionsSnapshot.docs.isEmpty) {
        print('No transactions found.');
        setState(() {
          _transactions = [];
        });
        return;
      }

      QuerySnapshot categoriesSnapshot = await FirebaseFirestore.instance
          .collection('categories')
          .where('email', isEqualTo: email)
          .get();

      Map<String, String> categoryIcons = {
        for (var doc in categoriesSnapshot.docs) doc['name']: doc['iconName']
      };

      List<Map<String, dynamic>> transactions =
          transactionsSnapshot.docs.map((doc) {
        String categoryName = doc['category_name'];
        String iconName = categoryIcons[categoryName] ?? 'shopping_bag';
        IconData? icon = _flutterIcons[iconName];

        String amount = doc['transaction_type'] == 'Income'
            ? '+ Rs${doc['converted_amount']}'
            : '- Rs${doc['converted_amount']}';

        return {
          'title': categoryName,
          'subtitle': doc['description'],
          'amount': amount,
          'time': (doc['timestamp'] as Timestamp)
              .toDate()
              .toLocal()
              .toString()
              .substring(11, 16),
          'icon': icon ?? Icons.money,
        };
      }).toList();

      setState(() {
        _transactions = transactions;
      });
    } catch (e) {
      print('Error fetching transactions: $e');
      setState(() {
        _transactions = [];
      });
    }
  }

  Widget _buildTransactionCard(String title, String subtitle, String amount,
      String time, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: GestureDetector(
        onTap: () {
          // If you need to navigate to transaction details, add the navigation here
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 0.5,
                blurRadius: 0.5,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ListTile(
            leading: Container(
              height: 55,
              width: 55,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                // Determine background color based on transaction type
                color: amount.contains('-')
                    ? const Color.fromRGBO(253, 60, 74, 1).withOpacity(0.1)
                    : const Color.fromRGBO(0, 168, 107, 1).withOpacity(0.1),
              ),
              child: Icon(
                icon,
                // Determine icon color based on transaction type
                color: amount.contains('-')
                    ? const Color.fromRGBO(253, 60, 74, 1)
                    : const Color.fromRGBO(0, 168, 107, 1),
                size: 30,
              ),
            ),
            title: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text(subtitle),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amount,
                  style: TextStyle(
                    color: amount.contains('-')
                        ? const Color.fromRGBO(253, 60, 74, 1)
                        : const Color.fromRGBO(0, 168, 107, 1),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
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
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge,
        overlays: [SystemUiOverlay.top]);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0.0),
                child: Column(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color.fromARGB(255, 255, 255, 255),
                            Color.fromARGB(1, 255, 246, 229),
                          ],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Column(
                          children: [
                            Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const ProfileScreen()),
                                        );
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: const Color.fromRGBO(
                                              126, 61, 255, 0.1),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(15.0),
                                          child: Image.asset(
                                            'assets/images/profile.png', // Fixed path separator to forward slash
                                            width: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                    MonthDropdownButton(
                                      onMonthSelected: (String month) {
                                        setState(() {
                                          currentMonth = month;
                                        });
                                        fetchMonthlyIncomeAndExpense(month);
                                      },
                                    ),
                                    GestureDetector(
                                        onTap: () async {
                                          await CustomLoader.showLoaderForTask(
                                              context: context,
                                              task: () async {
                                                _logout();
                                                Navigator.pushReplacement(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          const LoginPage()),
                                                );
                                              });
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: const Color.fromRGBO(
                                                255, 61, 61, 0.1),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(15.0),
                                            child: SvgPicture.asset(
                                              'assets/icons/logout.svg',
                                              height: 20, // Add specific height
                                              width: 20,
                                            ),
                                          ),
                                        ))
                                  ],
                                )),
                            const SizedBox(height: 10),
                            Column(
                              children: [
                                const Text(
                                  'Total Balance',
                                  style: TextStyle(
                                    fontSize: 25,
                                    fontWeight: FontWeight.w700,
                                    color: Color.fromRGBO(0, 0, 0, 170),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Rs ${totalBalance.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      fontSize: 50,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                _buildIncomeExpenseCard(
                                  'Expense',
                                  totalExpense.toStringAsFixed(0),
                                  const Color(
                                      0xFFDC2626), // red color for expense
                                ),
                                const SizedBox(width: 10),
                                _buildIncomeExpenseCard(
                                  'Income',
                                  totalIncome.toStringAsFixed(0),
                                  const Color(
                                      0xFF22C55E), // green color for income
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            const Text(
                              'Spend Frequency',
                              style: TextStyle(fontSize: 15),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 200,
                              width: double.infinity,
                              child: LineChartWidget(),
                            ),
                            const SizedBox(height: 20),
                            // Updated ExpensePieChart implementation
                            ExpensePieChart(
                              month: currentMonth,
                            ),
                            const SizedBox(height: 20),
                            Expanded(
                              child: FilterBar(
                                isSelected: isSelected,
                                onFilterChanged: _onFilterChanged,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Recent Transactions',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const Transactionpage()),
                                    );
                                  },
                                  child: Container(
                                    height: 35,
                                    width: 60,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: const Color.fromRGBO(
                                          126, 61, 255, 0.297),
                                      border: Border.all(
                                          color: const Color.fromRGBO(
                                              126, 61, 255, 1)),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'See All',
                                        style: TextStyle(
                                            color: Color.fromRGBO(
                                                126, 61, 255, 1)),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 250,
                              child: _transactions.isEmpty
                                  ? const Text('No transactions found.')
                                  : Expanded(
                                      child: ListView.builder(
                                        itemCount: _transactions.length,
                                        itemBuilder: (context, index) {
                                          final transaction =
                                              _transactions[index];
                                          return _buildTransactionCard(
                                            transaction['title'],
                                            transaction['subtitle'],
                                            transaction['amount'],
                                            transaction['time'],
                                            transaction['icon'],
                                          );
                                        },
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        activeIndex: _activeIndex,
      ),
      floatingActionButton: const CircularMenuWidget(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildIncomeExpenseCard(String title, String amount, Color color) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          // Navigate to TransactionPage with the transaction type
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => Transactionpage(initialFilter: title),
            ),
          );
        },
        child: Container(
          width: 150,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Rs $amount',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MonthDropdownButton extends StatefulWidget {
  final Function(String) onMonthSelected;

  const MonthDropdownButton({Key? key, required this.onMonthSelected})
      : super(key: key);

  @override
  State<MonthDropdownButton> createState() => _MonthDropdownButtonState();
}

class _MonthDropdownButtonState extends State<MonthDropdownButton> {
  final List<String> items = [
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
    'December',
  ];
  String? selectedValue;

  @override
  void initState() {
    super.initState();
    // Set current month as default
    selectedValue = DateFormat('MMMM').format(DateTime.now());
    // Call fetchMonthlyIncomeAndExpense with current month
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Using addPostFrameCallback to ensure the widget is mounted
      widget.onMonthSelected(selectedValue!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton2<String>(
        isExpanded: true,
        hint: const Row(
          children: [
            Expanded(
              child: Text(
                'Months',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 0, 0, 0),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        items: items
            .map((String item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ))
            .toList(),
        value: selectedValue,
        onChanged: (String? value) {
          setState(() {
            selectedValue = value;
          });
          if (value != null) {
            widget.onMonthSelected(
                value); // Call the callback with the selected month
          }
        },
        buttonStyleData: ButtonStyleData(
          height: 50,
          width: 180,
          padding: const EdgeInsets.only(left: 14, right: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: const Color.fromARGB(0, 252, 252, 252),
          ),
          elevation: 0,
        ),
        iconStyleData: const IconStyleData(
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
          ),
          iconSize: 45,
          iconEnabledColor: Color.fromRGBO(127, 61, 255, 1),
          iconDisabledColor: Color.fromARGB(255, 255, 255, 255),
        ),
        dropdownStyleData: DropdownStyleData(
          elevation: 1,
          maxHeight: 135,
          width: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: const Color.fromARGB(255, 255, 255, 255),
          ),
          offset: const Offset(-20, 0),
          scrollbarTheme: ScrollbarThemeData(
            radius: const Radius.circular(40),
            thickness: WidgetStateProperty.all<double>(6),
            thumbVisibility: WidgetStateProperty.all<bool>(true),
          ),
        ),
        menuItemStyleData: const MenuItemStyleData(
          height: 40,
          padding: EdgeInsets.only(left: 14, right: 14),
        ),
      ),
    );
  }
}

class FilterBar extends StatelessWidget {
  final List<bool> isSelected;
  final Function(int) onFilterChanged;

  const FilterBar(
      {super.key, required this.isSelected, required this.onFilterChanged});

  @override
  Widget build(BuildContext context) {
    return Expanded(
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
          selectedBorderColor:
              const Color(0xFFE8E8E8), // Light grey border when selected
          borderColor: const Color(0xFFE8E8E8), // Light grey border
          selectedColor: const Color.fromRGBO(127, 61, 255, 1),
          color: Colors.black,
          constraints: const BoxConstraints(
            minHeight: 35.0,
            minWidth: 75.0,
          ),
          isSelected: isSelected,
          onPressed: onFilterChanged,
          // Add vertical dividers between buttons
          renderBorder: true, // Enable border rendering
          children: const <Widget>[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'Today',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'Week',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'Month',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'Year',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
