import 'dart:math';
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

class AddIncomePage extends StatefulWidget {
  const AddIncomePage({super.key});

  @override
  _AddIncomePageState createState() => _AddIncomePageState();
}

class _AddIncomePageState extends State<AddIncomePage>
    with SingleTickerProviderStateMixin {
  String? selectedWallet;
  List<String> wallets = [];

  final TextEditingController _editDescription = TextEditingController();

  // Currency conversion variables
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

  // Animation variables
  double topContainerHeight = 420;
  double bottomContainerHeight = 380;
  double maxHeight = 650;
  double minHeight = 100;

  late AnimationController _controller;
  late Animation<double> _animation;

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
    // First validate the amount
    if (!validateAmount(_originalAmount.toString())) {
      return;
    }

    await CustomLoader.showLoaderForTask(
      context: context,
      task: () async {
        try {
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

          // Proceed with the transaction if conditions are met
          if (selectedWallet != null &&
              _editDescription.text != "" &&
              _originalAmount > 0) {
            // Call the TransactionController to process the transaction
            TransactionController transactionController =
                TransactionController();
            final result = await transactionController.processTransaction(
              amount: _originalAmount, // Directly pass as double
              accountName: selectedWallet ?? 'Unknown Account',
              transactionType: "Income",
            );

            if (result['success'] == true) {
              tId = _generateTransactionID();

              // Prepare transaction data
              final transactionData = {
                'account_name': selectedWallet,
                'amount': _originalAmount,
                'category_name': 'Income',
                'converted_amount': _convertedAmount,
                'currency_type': '$_fromCurrency-$_toCurrency',
                'description': _editDescription.text,
                'email': email,
                'timestamp': Timestamp.now(),
                'transaction_id': tId,
                'transaction_proof': '',
                'transaction_type': 'Income',
              };

              // Save transaction data to Firestore
              await FirebaseFirestore.instance
                  .collection('transactions')
                  .add(transactionData);

              // Display a success message
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text("Transaction added successfully.")));

              // Navigate to the DetailTransactionPage with transaction data
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                      "Please fill out all required fields with valid values.")),
            );
            return;
          }
        } catch (e) {
          print("Error storing transaction: $e");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to add transaction.")),
          );
        }
      },
    );
  }

  bool validateAmount(String amount) {
    // Remove any currency symbols and whitespace
    String cleanAmount = amount.trim().replaceAll(RegExp(r'[^0-9.]'), '');

    // Check if the amount is empty or contains only spaces
    if (cleanAmount.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Amount cannot be empty")),
      );
      return false;
    }

    // Try to parse the amount as a double
    try {
      double value = double.parse(cleanAmount);
      if (value <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Amount must be greater than 0")),
        );
        return false;
      }
      return true;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid amount")),
      );
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    fetchAccounts();
    // Remove animation controller, not needed for new layout
  }

  @override
  void dispose() {
    _editDescription.dispose();
    _amountController.dispose();
    _fromCurrencySearchController.dispose();
    _toCurrencySearchController.dispose();
    super.dispose();
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

  // Helper for section card styling (copied from AddExpensePage)
  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(0, 168, 107, 0.1), // green tint
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: const Color.fromRGBO(0, 168, 107, 1), // green
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  // Helper for styled dropdown (copied from AddExpensePage)
  Widget _buildStyledDropdown<T>({
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
    required String hint,
    String? Function(T?)? validator,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: const TextStyle(
          color: Colors.grey,
          fontSize: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
              color: Color.fromRGBO(0, 168, 107, 1), width: 2), // green
        ),
        filled: true,
        fillColor: Colors.grey.withOpacity(0.05),
      ),
    );
  }

  // Helper for styled text field (copied from AddExpensePage)
  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    String? prefixText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Function(String)? onChanged,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefixText,
        labelStyle: const TextStyle(
          color: Colors.grey,
          fontSize: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
              color: Color.fromRGBO(0, 168, 107, 1), width: 2), // green
        ),
        filled: true,
        fillColor: Colors.grey.withOpacity(0.05),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color.fromRGBO(0, 168, 107, 1), // green
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color.fromRGBO(0, 168, 107, 1), // green
                      const Color.fromRGBO(0, 168, 107, 0.8), // green tint
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'Add Income',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                    const SizedBox(height: 25),
                    // Amount & Currency Converter Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'How Much?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  cursorColor: Colors.white,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  controller: _amountController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d*\.?\d{0,2}')),
                                  ],
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    prefixIcon: Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      child: const Icon(
                                        Icons.arrow_upward,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                    ),
                                    hintText: '0',
                                    hintStyle: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 32,
                                    ),
                                    labelStyle:
                                        const TextStyle(color: Colors.white),
                                  ),
                                  onChanged: (value) {
                                    _convertCurrency();
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField2<String>(
                                  value: _fromCurrency,
                                  items: _currencies.map((currency) {
                                    return DropdownMenuItem<String>(
                                      value: currency['code'],
                                      child: Text(
                                          '${currency['code']} - ${currency['name']}'),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _fromCurrency = newValue!;
                                      if (_amountController.text.isNotEmpty)
                                        _convertCurrency();
                                    });
                                  },
                                  decoration: const InputDecoration(
                                    labelText: "From",
                                    labelStyle: TextStyle(color: Colors.white),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 15, vertical: 10),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(16)),
                                      borderSide:
                                          BorderSide(color: Colors.white),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(16)),
                                      borderSide:
                                          BorderSide(color: Colors.white),
                                    ),
                                  ),
                                  iconStyleData: const IconStyleData(
                                    icon:
                                        Icon(Icons.keyboard_arrow_down_rounded),
                                    iconSize: 36,
                                    iconEnabledColor: Colors.white,
                                  ),
                                  selectedItemBuilder: (BuildContext context) {
                                    return _currencies.map<Widget>((currency) {
                                      return Text(
                                        currency['code']!,
                                        style: const TextStyle(
                                            color: Colors.white),
                                      );
                                    }).toList();
                                  },
                                  dropdownStyleData: const DropdownStyleData(
                                    width: double.infinity,
                                    isFullScreen: true,
                                  ),
                                  dropdownSearchData: DropdownSearchData(
                                    searchController:
                                        _fromCurrencySearchController,
                                    searchInnerWidget: Container(
                                      margin: const EdgeInsets.all(16),
                                      child: TextField(
                                        controller:
                                            _fromCurrencySearchController,
                                        decoration: InputDecoration(
                                          hintText: 'Search currencies...',
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                    searchInnerWidgetHeight: 60,
                                    searchMatchFn: (item, searchValue) {
                                      return (item.value as String)
                                          .toLowerCase()
                                          .contains(searchValue.toLowerCase());
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.white),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: _isLoading
                                      ? const Center(
                                          child: CircularProgressIndicator(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        )
                                      : Text(
                                          _convertedAmount.isEmpty
                                              ? '0.00'
                                              : _convertedAmount,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField2<String>(
                                  value: _toCurrency,
                                  items: _currencies.map((currency) {
                                    return DropdownMenuItem<String>(
                                      value: currency['code'],
                                      child: Text(
                                          '${currency['code']} - ${currency['name']}'),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _toCurrency = newValue!;
                                      if (_amountController.text.isNotEmpty)
                                        _convertCurrency();
                                    });
                                  },
                                  decoration: const InputDecoration(
                                    labelText: "To",
                                    labelStyle: TextStyle(color: Colors.white),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 15, vertical: 10),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(16)),
                                      borderSide:
                                          BorderSide(color: Colors.white),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(16)),
                                      borderSide:
                                          BorderSide(color: Colors.white),
                                    ),
                                  ),
                                  iconStyleData: const IconStyleData(
                                    icon:
                                        Icon(Icons.keyboard_arrow_down_rounded),
                                    iconSize: 36,
                                    iconEnabledColor: Colors.white,
                                  ),
                                  selectedItemBuilder: (BuildContext context) {
                                    return _currencies.map<Widget>((currency) {
                                      return Text(
                                        currency['code']!,
                                        style: const TextStyle(
                                            color: Colors.white),
                                      );
                                    }).toList();
                                  },
                                  dropdownStyleData: const DropdownStyleData(
                                    width: double.infinity,
                                    isFullScreen: true,
                                  ),
                                  dropdownSearchData: DropdownSearchData(
                                    searchController:
                                        _toCurrencySearchController,
                                    searchInnerWidget: Container(
                                      margin: const EdgeInsets.all(16),
                                      child: TextField(
                                        controller: _toCurrencySearchController,
                                        decoration: InputDecoration(
                                          hintText: 'Search currencies...',
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                    searchInnerWidgetHeight: 60,
                                    searchMatchFn: (item, searchValue) {
                                      return (item.value as String)
                                          .toLowerCase()
                                          .contains(searchValue.toLowerCase());
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_convertedAmount.isNotEmpty &&
                              (_convertedAmount.contains('error') ||
                                  _convertedAmount.contains('Failed') ||
                                  _convertedAmount.contains('required') ||
                                  _convertedAmount.contains('Invalid') ||
                                  _convertedAmount.contains('greater')))
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                _convertedAmount,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Content Area
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25),
                    ),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Wallet Section
                      _buildSectionCard(
                        'Wallet',
                        Icons.account_balance_wallet,
                        [
                          _buildStyledDropdown<String>(
                            value: selectedWallet,
                            items: wallets.map((item) {
                              return DropdownMenuItem<String>(
                                value: item,
                                child: Text(item),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedWallet = value;
                              });
                            },
                            hint: 'Select Wallet',
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Description Section
                      _buildSectionCard(
                        'Description',
                        Icons.description,
                        [
                          _buildStyledTextField(
                            controller: _editDescription,
                            label: 'Description',
                            maxLines: 3,
                          ),
                        ],
                      ),
                      const SizedBox(height: 100), // Space for FAB
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                const Color.fromRGBO(0, 168, 107, 1), // green
                const Color.fromRGBO(0, 168, 107, 0.8), // green tint
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color.fromRGBO(0, 168, 107, 0.4), // green shadow
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            onPressed: _handleContinue,
            backgroundColor: Colors.transparent,
            elevation: 0,
            icon: const Icon(Icons.check, color: Colors.white, size: 24),
            label: const Text(
              'Continue',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }
}
