import 'dart:math';

import 'package:ExpenseTracker/Services/BudgetService.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

import 'package:ExpenseTracker/Services/TransactionController.dart';
import 'package:ExpenseTracker/screens/DetailTransactionPage.dart';
import 'package:ExpenseTracker/widgets/custom_loader.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';

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

  // Remove BudgetController instance
  // final BudgetController _BudgetController = BudgetController();

  // Remove Currency widget usage and add currency converter state/logic
  String _fromCurrency = 'PKR';
  String _toCurrency = 'USD';
  double _originalAmount = 0;
  String _convertedAmount = '';
  final TextEditingController _amountController = TextEditingController();
  bool _isLoading = false;
  final TextEditingController _fromCurrencySearchController =
      TextEditingController();
  final TextEditingController _toCurrencySearchController =
      TextEditingController();

  final List<Map<String, String>> _currencies = [
    {'code': 'PKR', 'name': 'Pakistani Rupee (PKR)'},
    {'code': 'USD', 'name': 'US Dollar (USD)'},
    {'code': 'EUR', 'name': 'Euro (EUR)'},
    {'code': 'GBP', 'name': 'British Pound (GBP)'},
    {'code': 'JPY', 'name': 'Japanese Yen (JPY)'},
    {'code': 'CAD', 'name': 'Canadian Dollar (CAD)'},
    {'code': 'AUD', 'name': 'Australian Dollar (AUD)'},
    {'code': 'CHF', 'name': 'Swiss Franc (CHF)'},
    {'code': 'CNY', 'name': 'Chinese Yuan (CNY)'},
    {'code': 'INR', 'name': 'Indian Rupee (INR)'},
    {'code': 'KRW', 'name': 'South Korean Won (KRW)'},
    {'code': 'SGD', 'name': 'Singapore Dollar (SGD)'},
    {'code': 'HKD', 'name': 'Hong Kong Dollar (HKD)'},
    {'code': 'SEK', 'name': 'Swedish Krona (SEK)'},
    {'code': 'NOK', 'name': 'Norwegian Krone (NOK)'},
    {'code': 'MXN', 'name': 'Mexican Peso (MXN)'},
    {'code': 'BRL', 'name': 'Brazilian Real (BRL)'},
    {'code': 'ZAR', 'name': 'South African Rand (ZAR)'},
    {'code': 'NZD', 'name': 'New Zealand Dollar (NZD)'},
    {'code': 'AED', 'name': 'UAE Dirham (AED)'},
    {'code': 'SAR', 'name': 'Saudi Riyal (SAR)'},
    {'code': 'TRY', 'name': 'Turkish Lira (TRY)'},
    {'code': 'RUB', 'name': 'Russian Ruble (RUB)'},
    {'code': 'PLN', 'name': 'Polish Zloty (PLN)'},
    {'code': 'CZK', 'name': 'Czech Koruna (CZK)'},
    {'code': 'HUF', 'name': 'Hungarian Forint (HUF)'},
    {'code': 'DKK', 'name': 'Danish Krone (DKK)'},
    {'code': 'THB', 'name': 'Thai Baht (THB)'},
    {'code': 'MYR', 'name': 'Malaysian Ringgit (MYR)'},
    {'code': 'PHP', 'name': 'Philippine Peso (PHP)'},
  ];

  Future<void> _convertCurrency() async {
    final value = _amountController.text.trim();
    if (value.isEmpty) {
      setState(() {
        _convertedAmount = 'Amount?';
      });
      return;
    }
    if (value.startsWith('-')) {
      setState(() {
        _convertedAmount = 'Negative amounts not allowed';
      });
      return;
    }
    if (!RegExp(r'^\d*\.?\d{0,2}$').hasMatch(value)) {
      setState(() {
        _convertedAmount = 'Invalid amount format';
      });
      return;
    }
    double amount;
    try {
      amount = double.parse(value);
      if (amount <= 0) {
        setState(() {
          _convertedAmount = 'Amount must be greater than 0';
        });
        return;
      }
    } catch (e) {
      setState(() {
        _convertedAmount = 'Amount should be greater than 0';
      });
      return;
    }
    setState(() {
      _originalAmount = amount;
    });

    if (_fromCurrency == _toCurrency) {
      setState(() {
        _convertedAmount = amount.toStringAsFixed(2);
      });
      _handleConversionData(
          _fromCurrency, _toCurrency, amount, amount.toStringAsFixed(2));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
            'https://currency-conversion-and-exchange-rates.p.rapidapi.com/convert?from=$_fromCurrency&to=$_toCurrency&amount=$amount'),
        headers: {
          'X-Rapidapi-Key':
              '10c9117011msh3c078190ac01525p17ad91jsn085ab6bd036a',
          'X-Rapidapi-Host':
              'currency-conversion-and-exchange-rates.p.rapidapi.com',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        setState(() {
          _convertedAmount = double.parse(jsonResponse['result'].toString())
              .toStringAsFixed(2);
          _isLoading = false;
        });
        _handleConversionData(
            _fromCurrency, _toCurrency, amount, _convertedAmount);
      } else {
        setState(() {
          _convertedAmount = 'Failed to convert';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _convertedAmount = 'Connection error';
        _isLoading = false;
      });
    }
  }

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
                amount: _originalAmount,
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
                  // Add budget tracking fields
                  'budget_id': selectedBudget?['budget_id'],
                  'budget_name': selectedBudget?['name'],
                  'tracked_in_budget': selectedBudget != null,
                };

                // Save transaction data to Firestore
                await FirebaseFirestore.instance
                    .collection('transactions')
                    .add(transactionData);

                // Update budget spending if budget is selected
                if (selectedBudget != null) {
                  await BudgetService.updateBudgetSpending(
                    budgetId: selectedBudget!['budget_id'],
                    amount: _originalAmount,
                    isAdd: true,
                  );
                }

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

  List<Map<String, dynamic>> availableBudgets = [];
  Map<String, dynamic>? selectedBudget;
  bool _isBudgetLoading = false;

// Add this method to fetch budgets
  Future<void> fetchAvailableBudgets() async {
    setState(() {
      _isBudgetLoading = true;
    });

    try {
      final budgets = await BudgetService.getActiveBudgets();
      setState(() {
        availableBudgets = budgets;
        _isBudgetLoading = false;
      });
    } catch (e) {
      setState(() {
        _isBudgetLoading = false;
      });
      print('Error fetching budgets: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchCategories();
    fetchAccounts();
    fetchAvailableBudgets(); // Add this line
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _animation =
        Tween<double>(begin: bottomContainerHeight, end: bottomContainerHeight)
            .animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    _editDescription.dispose();
    _amountController.dispose();
    _fromCurrencySearchController.dispose();
    _toCurrencySearchController.dispose();
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

    // Fetch global categories
    final globalSnapshot =
        await FirebaseFirestore.instance.collection('global_categories').get();

    // Only use global categories
    setState(() {
      categories = [
        ...globalSnapshot.docs.map((doc) {
          return {
            "id": doc.id,
            "iconName": doc['iconName'],
            "name": doc['name'],
            "iconColor": doc['iconColor'],
            "is_global": true,
          };
        }),
      ];
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

  void _onCategoryChanged(Map<String, dynamic> category) {
    setState(() {
      selectedCategory = category;
    });
  }

  
