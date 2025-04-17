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
  double _totalDeductions = 0;
  double _finalTax = 0;
  bool _showResults = false;
  final int _activeIndex = 4;

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
      double zakatDeduction = double.tryParse(_zakatController.text) ?? 0;
      double charityDeduction = double.tryParse(_charityController.text) ?? 0;

      setState(() {
        _annualIncome = monthlyIncome * 12;
        _calculatedTax = calculateTax(_annualIncome);
        _totalDeductions = zakatDeduction + charityDeduction;
        _finalTax = _calculatedTax > _totalDeductions
            ? _calculatedTax - _totalDeductions
            : 0;
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
              // Income Input Container
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
                            'Monthly Income',
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
                    ],
                  ),
                ),
              ),

              // Deductions Container
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
              ),

              // Calculate Button
              Container(
                height: 48,
                margin: const EdgeInsets.only(bottom: 24),
                child: ElevatedButton(
                  onPressed: _calculateTax,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(127, 61, 255, 1),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Calculate Tax',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // Results Section
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
                              'Tax Calculation Results',
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

                // Tax Info Container

                // Tax Brackets Container
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
                                Icons.table_chart,
                                color: Color.fromRGBO(127, 61, 255, 1),
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              'Tax Brackets (2023-2024)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildTaxBracketInfo('Up to 600,000', '0%'),
                        _buildTaxBracketInfo('600,001 - 1,200,000', '2.5%'),
                        _buildTaxBracketInfo('1,200,001 - 2,400,000', '12.5%'),
                        _buildTaxBracketInfo('2,400,001 - 3,600,000', '20%'),
                        _buildTaxBracketInfo('3,600,001 - 6,000,000', '25%'),
                        _buildTaxBracketInfo('Above 6,000,000', '32.5%'),
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

// Updated Result Row Widget
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

// Updated Tax Bracket Info Widget
  Widget _buildTaxBracketInfo(String bracket, String rate) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            bracket,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          Text(
            rate,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color.fromRGBO(127, 61, 255, 1),
            ),
          ),
        ],
      ),
    );
  }
}
