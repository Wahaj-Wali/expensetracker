import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:ExpenseTracker/Services/BudgetModificationController.dart';
import 'package:ExpenseTracker/Services/TransactionController.dart';
import 'package:ExpenseTracker/screens/DetailTransactionPage.dart';
import 'package:ExpenseTracker/widgets/custom_loader.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/IncomeExpensePage.dart';

class AddExpensePage extends StatefulWidget {
  const AddExpensePage({super.key});

  @override
  _AddExpensePageState createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage>
    with SingleTickerProviderStateMixin {
  String? selectedWallet;

  List<Map<String, dynamic>> categories = [];
  Map<String, dynamic>? selectedCategory;
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
  IconData? getIconData(String iconName) {
    return _flutterIcons[iconName];
  }

  List<String> wallets = [];
  double topContainerHeight = 420;
  double bottomContainerHeight = 380;
  double maxHeight = 650;
  double minHeight = 100;

  late AnimationController _controller;
  late Animation<double> _animation;

  final TextEditingController _editDescription = TextEditingController();

  final BudgetController _BudgetController = BudgetController();

  String _fromCurrency = '';
  String _toCurrency = '';
  double _originalAmount = 0;
  String _convertedAmount = '';

  // Method to handle conversion data and capture the conversion results
  void _handleConversionData(
      String fromCurrency, String toCurrency, double amount, String result) {
    setState(() {
      // Update the fields in the parent widget or page
      _fromCurrency = fromCurrency;
      _toCurrency = toCurrency;
      _originalAmount = amount;
      _convertedAmount = result;
    });
  }

  // Generate a random transaction ID
  String _generateTransactionID() {
    return Random().nextInt(999999999).toString();
  }

  String tId = "";

  // Method to handle storing transaction data when 'Continue' is clicked
  Future<void> _handleContinue() async {
    await CustomLoader.showLoaderForTask(
        context: context,
        task: () async {
          //Code
          try {
            // Check if amount is 0 or negative
            if (_originalAmount <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text("Amount must be greater than zero.")));
              return;
            }

            // Retrieve email from SharedPreferences
            final prefs = await SharedPreferences.getInstance();
            final email = prefs.getString('email') ?? '';

            // Check user type and transaction limit
            final authSnapshot = await FirebaseFirestore.instance
                .collection('authentication')
                .where('email', isEqualTo: email)
                .limit(1)
                .get();

            if (authSnapshot.docs.isNotEmpty) {
              final userType = authSnapshot.docs.first['user_type'];

              // Check if user type is "basic user" and limit transactions to 15 per day
              if (userType == "basic user") {
                final today = DateTime.now();
                final startOfDay = DateTime(today.year, today.month, today.day);

                // Count today's transactions for the user
                final transactionCount = await FirebaseFirestore.instance
                    .collection('transactions')
                    .where('email', isEqualTo: email)
                    .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
                    .get()
                    .then((snapshot) => snapshot.docs.length);
              }
            }

            // Check if wallet is selected
            if (selectedWallet == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please select a wallet.")));
              return;
            }

            // Proceed with the transaction if conditions are met
            if (selectedCategory != null && _editDescription.text != "") {
              // Call the TransactionController to process the transaction
              TransactionController transactionController =
                  TransactionController();
              final result = await transactionController.processTransaction(
                amount: _originalAmount, // Directly pass as double
                accountName: selectedWallet ?? 'Unknown Account',
                transactionType: "Expense",
              );

              if (result['success'] == true) {
                tId = _generateTransactionID();

                // Prepare transaction data
                final transactionData = {
                  'account_name': selectedWallet,
                  'amount': _originalAmount,
                  'category_name': selectedCategory!['name'],
                  'converted_amount': _convertedAmount,
                  'currency_type': '$_fromCurrency-$_toCurrency',
                  'description': _editDescription.text,
                  'email': email,
                  'timestamp': Timestamp.now(),
                  'transaction_id': tId,
                  'transaction_type': 'Expense',
                };

                // Save transaction data to Firestore
                await FirebaseFirestore.instance
                    .collection('transactions')
                    .add(transactionData);

                _BudgetController.updateSpendAmount(
                    _originalAmount, selectedCategory!['name']);

                // Display a success message
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Transaction added successfully.")));

                if (tId != "") {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              DetailTransactionPage(transactionId: tId)));
                }
              } else {
                // Abort if transaction failed and display the error message from controller
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(result['message'] ?? "Transaction failed.")));
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text("Please fill out all required fields.")));
              return;
            }
          } catch (e) {
            print("Error storing transaction: $e");
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Failed to add transaction.")));
          }
        });
  }

  @override
  void initState() {
    super.initState();
    fetchCategories();
    fetchAccounts();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150), // Faster response time
    );
    _animation =
        Tween<double>(begin: bottomContainerHeight, end: bottomContainerHeight)
            .animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    _editDescription.dispose();
    super.dispose();
  }

  void onVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      // Increase sensitivity to make scrolling faster
      bottomContainerHeight -=
          details.delta.dy * 1.7; // Increase scroll sensitivity
      if (bottomContainerHeight > maxHeight) bottomContainerHeight = maxHeight;
      if (bottomContainerHeight < minHeight) bottomContainerHeight = minHeight;
    });
  }

  void onVerticalDragEnd(DragEndDetails details) {
    // Adjust spring physics for a faster snap back and reaction
    final velocity = details.primaryVelocity ?? 0;
    const spring = SpringDescription(
      mass: 1,
      stiffness: 2000, // Increased stiffness for faster spring action
      damping: 7, // Further lowered damping for quicker response
    );

    final simulation = SpringSimulation(
        spring, bottomContainerHeight, bottomContainerHeight, velocity / 1000);

    _controller.animateWith(simulation);
  }

  Future<void> fetchCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email') ?? '';

    // Query Firestore for categories that match the user's email
    final snapshot = await FirebaseFirestore.instance
        .collection('categories')
        .where('email', isEqualTo: email)
        .get();

    setState(() {
      categories = snapshot.docs.map((doc) {
        return {
          "id": doc.id,
          "iconName": doc['iconName'],
          "name": doc['name'],
          "iconColor": doc['iconColor'],
        };
      }).toList();
    });
  }

  Future<void> fetchAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email') ?? '';

    final snapshot = await FirebaseFirestore.instance
        .collection('accounts')
        .where('email', isEqualTo: email)
        .get();

    setState(() {
      wallets =
          snapshot.docs.map((doc) => doc['account_name'] as String).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(253, 60, 74, 1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Expense",
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          GestureDetector(
            child: Container(
              color: const Color.fromRGBO(253, 60, 74, 1),
              height: MediaQuery.of(context).size.height,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    height: 50,
                  ),
                  const Text(
                    'How Much?',
                    style: TextStyle(
                      color: Color.fromRGBO(255, 255, 255, 0.64),
                      fontSize: 18,
                    ),
                  ),
                  Currency(
                    color: const Color.fromRGBO(253, 60, 74, 1),
                    onConvert: _handleConversionData,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            child: GestureDetector(
              onVerticalDragUpdate: onVerticalDragUpdate,
              onVerticalDragEnd: onVerticalDragEnd,
              child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Container(
                      width: MediaQuery.of(context).size.width,
                      height: bottomContainerHeight,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: Column(
                            children: [
                              Container(
                                width: 40,
                                height: 5,
                                margin: const EdgeInsets.only(top: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField2<Map<String, dynamic>>(
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16.0),
                                    borderSide: const BorderSide(
                                        color: Color(0xFFF1F1FA), width: 1),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16.0),
                                    borderSide: const BorderSide(
                                        color: Color(0xFFF1F1FA), width: 1),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16.0),
                                    borderSide: const BorderSide(
                                        color: Color.fromRGBO(127, 61, 255, 1),
                                        width: 1),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF1F1FA),
                                ),
                                buttonStyleData: ButtonStyleData(
                                  height: 60,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: const Color(0xFFF1F1FA),
                                  ),
                                ),
                                iconStyleData: const IconStyleData(
                                  icon: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: Colors.black54,
                                  ),
                                  iconSize: 24,
                                ),
                                dropdownStyleData: DropdownStyleData(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: Colors.white,
                                  ),
                                  offset: const Offset(0, -10),
                                  scrollbarTheme: ScrollbarThemeData(
                                    radius: const Radius.circular(40),
                                    thickness: WidgetStateProperty.all(6),
                                    thumbVisibility:
                                        WidgetStateProperty.all(true),
                                  ),
                                ),
                                menuItemStyleData: const MenuItemStyleData(
                                  height: 50,
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                ),
                                items: categories
                                    .map((Map<String, dynamic> category) {
                                  return DropdownMenuItem<Map<String, dynamic>>(
                                    value: category,
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: Color(int.parse(
                                                    category['iconColor']
                                                        .replaceFirst(
                                                            '#', '0xFF')))
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            getIconData(category['iconName']),
                                            color: Color(int.parse(
                                                category['iconColor']
                                                    .replaceFirst(
                                                        '#', '0xFF'))),
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          category['name'],
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                value: selectedCategory,
                                onChanged: (value) {
                                  setState(() {
                                    selectedCategory = value;
                                  });
                                },
                                hint: const Row(
                                  children: [
                                    SizedBox(width: 0),
                                    Text(
                                      'Select Category',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField2<String>(
                                // Same styling as above, just change categories to wallets and hint text
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16.0),
                                    borderSide: const BorderSide(
                                        color: Color(0xFFF1F1FA), width: 1),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16.0),
                                    borderSide: const BorderSide(
                                        color: Color(0xFFF1F1FA), width: 1),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16.0),
                                    borderSide: const BorderSide(
                                        color: Color.fromRGBO(127, 61, 255, 1),
                                        width: 1),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF1F1FA),
                                ),
                                buttonStyleData: ButtonStyleData(
                                  height: 60,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: const Color(0xFFF1F1FA),
                                  ),
                                ),
                                iconStyleData: const IconStyleData(
                                  icon: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: Colors.black54,
                                  ),
                                  iconSize: 24,
                                ),
                                dropdownStyleData: DropdownStyleData(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: Colors.white,
                                  ),
                                  offset: const Offset(0, -10),
                                  scrollbarTheme: ScrollbarThemeData(
                                    radius: const Radius.circular(40),
                                    thickness: WidgetStateProperty.all(6),
                                    thumbVisibility:
                                        WidgetStateProperty.all(true),
                                  ),
                                ),
                                menuItemStyleData: const MenuItemStyleData(
                                  height: 50,
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                ),
                                items: wallets.map((String item) {
                                  return DropdownMenuItem<String>(
                                    value: item,
                                    child: Text(
                                      item,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                value: selectedWallet,
                                onChanged: (value) {
                                  setState(() {
                                    selectedWallet = value;
                                  });
                                },
                                hint: const Text(
                                  'Wallet',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _editDescription,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  labelText: 'Description',
                                  labelStyle: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  alignLabelWithHint: true,
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16.0),
                                    borderSide: const BorderSide(
                                        color: Color(0xFFF1F1FA), width: 1),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16.0),
                                    borderSide: const BorderSide(
                                        color: Color(0xFFF1F1FA), width: 1),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16.0),
                                    borderSide: const BorderSide(
                                        color: Color.fromRGBO(127, 61, 255, 1),
                                        width: 1),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF1F1FA),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 16),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: () {
                                    _handleContinue();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color.fromRGBO(127, 61, 255, 1),
                                    minimumSize:
                                        const Size(double.infinity, 48),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text('Continue',
                                      style: TextStyle(
                                          fontSize: 18, color: Colors.white)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
            ),
          ),
        ],
      ),
    );
  }
}
