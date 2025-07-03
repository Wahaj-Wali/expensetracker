import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dropdown_button2/dropdown_button2.dart';

class IncomeExpensePage extends StatefulWidget {
  const IncomeExpensePage({Key? key}) : super(key: key);

  @override
  _IncomeExpensePageState createState() => _IncomeExpensePageState();
}

class _IncomeExpensePageState extends State<IncomeExpensePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Transaction data
  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _addTransaction(String type, String fromCurrency, String toCurrency,
      double amount, String convertedAmount, String description) {
    setState(() {
      _transactions.insert(0, {
        'type': type,
        'fromCurrency': fromCurrency,
        'toCurrency': toCurrency,
        'amount': amount,
        'convertedAmount': convertedAmount,
        'description': description,
        'date': DateTime.now(),
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Income & Expense Manager'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            const Tab(text: 'Income'),
            const Tab(text: 'Expense'),
            const Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildIncomeTab(),
          _buildExpenseTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildIncomeTab() {
    return Container(
      color: Colors.green,
      child: Column(
        children: [
          Expanded(
            child: CurrencyConverterWidget(
              color: Colors.green,
              transactionType: 'Income',
              onTransactionAdd: _addTransaction,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseTab() {
    return Container(
      color: Colors.red,
      child: Column(
        children: [
          Expanded(
            child: CurrencyConverterWidget(
              color: Colors.red,
              transactionType: 'Expense',
              onTransactionAdd: _addTransaction,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (_transactions.isEmpty)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No transactions yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _transactions.length,
                itemBuilder: (context, index) {
                  final transaction = _transactions[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: transaction['type'] == 'Income'
                            ? Colors.green
                            : Colors.red,
                        child: Icon(
                          transaction['type'] == 'Income'
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        '${transaction['fromCurrency']} ${transaction['amount'].toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Converted: ${transaction['toCurrency']} ${transaction['convertedAmount']}'),
                          Text('${transaction['description']}'),
                          Text(
                              '${transaction['date'].toString().substring(0, 16)}'),
                        ],
                      ),
                      trailing: Text(
                        transaction['type'],
                        style: TextStyle(
                          color: transaction['type'] == 'Income'
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class CurrencyConverterWidget extends StatefulWidget {
  final Color color;
  final String transactionType;
  final Function(String, String, String, double, String, String)
      onTransactionAdd;

  const CurrencyConverterWidget({
    Key? key,
    required this.color,
    required this.transactionType,
    required this.onTransactionAdd,
  }) : super(key: key);

  @override
  _CurrencyConverterWidgetState createState() =>
      _CurrencyConverterWidgetState();
}

class _CurrencyConverterWidgetState extends State<CurrencyConverterWidget> {
  String _fromCurrency = 'PKR';
  String _toCurrency = 'USD';
  double _amount = 0;
  String _result = '';
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fromCurrencySearchController =
      TextEditingController();
  final TextEditingController _toCurrencySearchController =
      TextEditingController();

  bool _isLoading = false;

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
    if (_amountController.text.isEmpty) {
      setState(() {
        _result = 'Amount?';
      });
      return;
    }

    if (_fromCurrency == _toCurrency) {
      setState(() {
        _result = _amount.toStringAsFixed(2);
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
            'https://currency-conversion-and-exchange-rates.p.rapidapi.com/convert?from=$_fromCurrency&to=$_toCurrency&amount=$_amount'),
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
          _result = double.parse(jsonResponse['result'].toString())
              .toStringAsFixed(2);
          _isLoading = false;
        });
      } else {
        setState(() {
          _result = 'Failed to convert';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _result = 'Connection error';
        _isLoading = false;
      });
    }
  }

  bool _validateAmount(String value) {
    if (value.isEmpty) {
      setState(() {
        _result = 'Amount required';
      });
      return false;
    }

    String cleanValue = value.trim();

    if (cleanValue.startsWith('-')) {
      setState(() {
        _result = 'Negative amounts not allowed';
      });
      return false;
    }

    if (!RegExp(r'^\d*\.?\d{0,2}$').hasMatch(cleanValue)) {
      setState(() {
        _result = 'Invalid amount format';
      });
      return false;
    }

    try {
      double amount = double.parse(cleanValue);
      if (amount <= 0) {
        setState(() {
          _result = 'Amount must be greater than 0';
        });
        return false;
      }
      setState(() {
        _result = '';
      });
      return true;
    } catch (e) {
      setState(() {
        _result = 'Amount should be greater than 0';
      });
      return false;
    }
  }

  void _addTransaction() {
    if (_amountController.text.isEmpty ||
        _result.isEmpty ||
        _result == 'Amount?' ||
        _result.contains('error') ||
        _result.contains('Failed')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount and wait for conversion'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String description = _descriptionController.text.trim();
    if (description.isEmpty) {
      description = '${widget.transactionType} transaction';
    }

    widget.onTransactionAdd(
      widget.transactionType,
      _fromCurrency,
      _toCurrency,
      _amount,
      _result,
      description,
    );

    // Clear form
    _amountController.clear();
    _descriptionController.clear();
    setState(() {
      _amount = 0;
      _result = '';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.transactionType} added successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _fromCurrencySearchController.dispose();
    _toCurrencySearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Form(
        key: _formKey,
        child: Container(
          decoration: BoxDecoration(
            color: widget.color,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Add ${widget.transactionType}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // Amount input with currency selection
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        cursorColor: Colors.white,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                        ),
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}')),
                        ],
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          prefixIcon: Container(
                            margin: const EdgeInsets.only(right: 8),
                            child: Icon(
                              widget.transactionType == 'Income'
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                          hintText: '0',
                          hintStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                          ),
                          labelStyle: const TextStyle(color: Colors.white),
                        ),
                        onChanged: (value) {
                          if (_validateAmount(value)) {
                            setState(() {
                              _amount = double.parse(value);
                              _convertCurrency();
                            });
                          }
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
                            if (_amount > 0) _convertCurrency();
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: "From",
                          labelStyle: TextStyle(color: Colors.white),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 15, vertical: 10),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                            borderSide: BorderSide(color: Colors.white),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                            borderSide: BorderSide(color: Colors.white),
                          ),
                        ),
                        iconStyleData: const IconStyleData(
                          icon: Icon(Icons.keyboard_arrow_down_rounded),
                          iconSize: 36,
                          iconEnabledColor: Colors.white,
                        ),
                        selectedItemBuilder: (BuildContext context) {
                          return _currencies.map<Widget>((currency) {
                            return Text(
                              currency['code']!,
                              style: const TextStyle(color: Colors.white),
                            );
                          }).toList();
                        },
                        dropdownStyleData: const DropdownStyleData(
                          width: double.infinity,
                          isFullScreen: true,
                        ),
                        dropdownSearchData: DropdownSearchData(
                          searchController: _fromCurrencySearchController,
                          searchInnerWidget: Container(
                            margin: const EdgeInsets.all(16),
                            child: TextField(
                              controller: _fromCurrencySearchController,
                              decoration: InputDecoration(
                                hintText: 'Search currencies...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
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

                const SizedBox(height: 20),

                // Converted amount display
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
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Text(
                                _result.isEmpty ? '0.00' : _result,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
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
                            if (_amount > 0) _convertCurrency();
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: "To",
                          labelStyle: TextStyle(color: Colors.white),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 15, vertical: 10),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                            borderSide: BorderSide(color: Colors.white),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                            borderSide: BorderSide(color: Colors.white),
                          ),
                        ),
                        iconStyleData: const IconStyleData(
                          icon: Icon(Icons.keyboard_arrow_down_rounded),
                          iconSize: 36,
                          iconEnabledColor: Colors.white,
                        ),
                        selectedItemBuilder: (BuildContext context) {
                          return _currencies.map<Widget>((currency) {
                            return Text(
                              currency['code']!,
                              style: const TextStyle(color: Colors.white),
                            );
                          }).toList();
                        },
                        dropdownStyleData: const DropdownStyleData(
                          width: double.infinity,
                          isFullScreen: true,
                        ),
                        dropdownSearchData: DropdownSearchData(
                          searchController: _toCurrencySearchController,
                          searchInnerWidget: Container(
                            margin: const EdgeInsets.all(16),
                            child: TextField(
                              controller: _toCurrencySearchController,
                              decoration: InputDecoration(
                                hintText: 'Search currencies...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
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

                // Error message display
                if (_result.isNotEmpty &&
                    (_result.contains('error') ||
                        _result.contains('Failed') ||
                        _result.contains('required') ||
                        _result.contains('Invalid') ||
                        _result.contains('greater')))
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _result,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                // Description input
                TextFormField(
                  controller: _descriptionController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    labelStyle: TextStyle(color: Colors.white),
                    hintText: 'Enter transaction description',
                    hintStyle: TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Add transaction button
                ElevatedButton(
                  onPressed: _addTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: widget.color,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Add ${widget.transactionType}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
