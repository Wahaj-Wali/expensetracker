import 'package:ExpenseTracker/Services/SalesTaxController.dart';
import 'package:ExpenseTracker/widgets/CircularMenuWidget.dart';
import 'package:ExpenseTracker/widgets/CustomBottomNavigationBar.dart';
import 'package:flutter/material.dart';

class TaxCalculatorScreen extends StatefulWidget {
  @override
  _TaxCalculatorScreenState createState() => _TaxCalculatorScreenState();
}

class _TaxCalculatorScreenState extends State<TaxCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _monthlyIncomeController = TextEditingController();
  final _zakatController = TextEditingController();
  final _charityController = TextEditingController();

  double _annualIncome = 0;
  double _calculatedTax = 0;
  double _monthlyTax = 0;

  double _finalTax = 0;
  bool _showResults = false;
  final int _activeIndex = 3;

  // Sales Tax related variables
  double _yearlySalesTax = 0;
  int _expenseTransactionCount = 0;
  double _averageTaxRate = 0;
  Map<String, double> _categoryWiseTax = {};
  bool _salesTaxLoading = false;
  bool _showSalesTaxResults =
      false; // New variable to control sales tax results display

  final SalesTaxController _salesTaxController = SalesTaxController();

  @override
  void initState() {
    super.initState();
    // Removed automatic loading of sales tax data
  }

  // Load sales tax data - now called manually via button
  Future<void> _loadSalesTaxData() async {
    setState(() {
      _salesTaxLoading = true;
    });

    try {
      final result = await _salesTaxController.calculateYearlySalesTax();

      if (result['success'] == true) {
        setState(() {
          _yearlySalesTax = result['totalSalesTax'];
          _expenseTransactionCount = result['transactionCount'];
          _averageTaxRate = result['averageTaxRate'];
          _categoryWiseTax = result['categoryWiseTax'];
          _showSalesTaxResults = true; // Show results after calculation
        });
      }
    } catch (e) {
      print("Error loading sales tax data: $e");
    } finally {
      setState(() {
        _salesTaxLoading = false;
      });
    }
  }

  // Tax brackets for Pakistan (2023-2024)
  double calculateTax(double annualIncome) {
    if (annualIncome <= 600000) {
      return 0;
    } else if (annualIncome <= 1200000) {
      return (annualIncome - 600000) * 0.025;
    } else if (annualIncome <= 2400000) {
      return 15000 + (annualIncome - 1200000) * 0.125;
    } else if (annualIncome <= 3600000) {
      return 165000 + (annualIncome - 2400000) * 0.20;
    } else if (annualIncome <= 6000000) {
      return 405000 + (annualIncome - 3600000) * 0.25;
    } else {
      return 1005000 + (annualIncome - 6000000) * 0.325;
    }
  }

  void _calculateTax() {
    if (_formKey.currentState!.validate()) {
      double monthlyIncome =
          double.tryParse(_monthlyIncomeController.text) ?? 0;

      setState(() {
        _annualIncome = monthlyIncome * 12;
        _calculatedTax = calculateTax(_annualIncome);
        _finalTax = _calculatedTax; // You might want to add deductions here
        _monthlyTax = _finalTax / 12;
        _showResults = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
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
          "Tax Calculator",
          style: TextStyle(
            color: Colors.black,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sales Tax Section
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 3,
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color.fromRGBO(127, 61, 255, 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.receipt_long,
                              color: Color.fromRGBO(127, 61, 255, 1),
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Text(
                            'Sales Tax Calculator',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Calculate Sales Tax Button (only show if results not calculated)
                      if (!_showSalesTaxResults)
                        Container(
                          height: 48,
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                _salesTaxLoading ? null : _loadSalesTaxData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromRGBO(127, 61, 255, 1),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _salesTaxLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Calculate Sales Tax',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),

                      // Sales Tax Results (only show after calculation)
                      if (_showSalesTaxResults) ...[
                        const SizedBox(height: 24),
                        const Text(
                          'Sales Tax Summary (Current Year)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSalesTaxRow(
                          'Total Sales Tax Paid:',
                          'PKR ${_yearlySalesTax.toStringAsFixed(2)}',
                          isHighlighted: true,
                        ),
                        const Divider(height: 24),
                        _buildSalesTaxRow(
                          'Number of Transactions:',
                          _expenseTransactionCount.toString(),
                        ),
                        const Divider(height: 24),
                        _buildSalesTaxRow(
                          'Average Tax Rate:',
                          '${_averageTaxRate.toStringAsFixed(2)}%',
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Income Input Container (only show if results not calculated)
              if (!_showResults)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 3,
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color.fromRGBO(127, 61, 255, 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.money,
                                color: Color.fromRGBO(127, 61, 255, 1),
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              'Income Tax Calculator',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _monthlyIncomeController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Enter your monthly income',
                            fillColor: const Color.fromRGBO(127, 61, 255, 0.1),
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your monthly income';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Calculate Income Tax Button
                        Container(
                          height: 48,
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _calculateTax,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromRGBO(127, 61, 255, 1),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Calculate Income Tax',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Income Tax Results Section
              if (_showResults) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 3,
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color.fromRGBO(127, 61, 255, 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.calculate,
                                color: Color.fromRGBO(127, 61, 255, 1),
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              'Income Tax Calculation Results',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildResultRow(
                          'Annual Income:',
                          'PKR ${_annualIncome.toStringAsFixed(2)}',
                        ),
                        const Divider(height: 24),
                        _buildResultRow(
                          'Gross Annual Tax:',
                          'PKR ${_calculatedTax.toStringAsFixed(2)}',
                        ),
                        const Divider(height: 24),
                        _buildResultRow(
                          'Net Annual Tax:',
                          'PKR ${_finalTax.toStringAsFixed(2)}',
                          isHighlighted: true,
                        ),
                        const Divider(height: 24),
                        _buildResultRow(
                          'Monthly Tax:',
                          'PKR ${_monthlyTax.toStringAsFixed(2)}',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
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

  // Sales Tax Result Row Widget
  Widget _buildSalesTaxRow(String label, String value,
      {bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isHighlighted
                ? const Color.fromRGBO(127, 61, 255, 1)
                : Colors.black87,
          ),
        ),
      ],
    );
  }

  // Income Tax Result Row Widget
  Widget _buildResultRow(String label, String value,
      {bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isHighlighted
                ? const Color.fromRGBO(127, 61, 255, 1)
                : Colors.black87,
          ),
        ),
      ],
    );
  }
}
