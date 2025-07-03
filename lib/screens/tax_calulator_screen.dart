import 'package:ExpenseTracker/Services/SalesTaxController.dart';
import 'package:ExpenseTracker/widgets/CircularMenuWidget.dart';
import 'package:ExpenseTracker/widgets/CustomBottomNavigationBar.dart';
import 'package:flutter/material.dart';

// Income Type Enum
enum IncomeType {
  salary,
  business,
  property,
  capitalGains,
  dividends,
}

// Extension to get display names and descriptions
extension IncomeTypeExtension on IncomeType {
  String get displayName {
    switch (this) {
      case IncomeType.salary:
        return 'Salary Income';
      case IncomeType.business:
        return 'Business/Professional Income';
      case IncomeType.property:
        return 'Property Income (Rental)';
      case IncomeType.capitalGains:
        return 'Capital Gains';
      case IncomeType.dividends:
        return 'Dividends';
    }
  }

  String get description {
    switch (this) {
      case IncomeType.salary:
        return 'Monthly wages/salary from employment';
      case IncomeType.business:
        return 'Freelancing, consulting, business income';
      case IncomeType.property:
        return 'Rental income from property';
      case IncomeType.capitalGains:
        return 'Profit from sale of assets/stocks';
      case IncomeType.dividends:
        return 'Dividend income from investments';
    }
  }

  IconData get icon {
    switch (this) {
      case IncomeType.salary:
        return Icons.work;
      case IncomeType.business:
        return Icons.business;
      case IncomeType.property:
        return Icons.home;
      case IncomeType.capitalGains:
        return Icons.trending_up;
      case IncomeType.dividends:
        return Icons.account_balance;
    }
  }
}

class TaxCalculatorScreen extends StatefulWidget {
  @override
  _TaxCalculatorScreenState createState() => _TaxCalculatorScreenState();
}

class _TaxCalculatorScreenState extends State<TaxCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _monthlyIncomeController = TextEditingController();
  final _additionalDataController = TextEditingController();

  // Income Type Selection
  IncomeType _selectedIncomeType = IncomeType.salary;

  double _annualIncome = 0;
  double _calculatedTax = 0;
  double _monthlyTax = 0;
  double _finalTax = 0;
  bool _showResults = false;
  final int _activeIndex = 3;

  // Additional fields for specific income types
  String _holdingPeriod = '< 1 year'; // For capital gains
  String _companyType = 'Listed'; // For dividends
  double _maintenanceDeduction = 0; // For property income

  // Sales Tax related variables
  double _yearlySalesTax = 0;
  int _expenseTransactionCount = 0;
  double _averageTaxRate = 0;
  Map<String, double> _categoryWiseTax = {};
  bool _salesTaxLoading = false;
  bool _showSalesTaxResults = false;

  final SalesTaxController _salesTaxController = SalesTaxController();

  @override
  void initState() {
    super.initState();
  }

  // Load sales tax data
  Future<void> _loadSalesTaxData() async {
    setState(() {
      _salesTaxLoading = true;
    });

    try {
      final result = await _salesTaxController.calculateYearlySalesTax();

      if (result['success'] == true) {
        // Safely parse categoryWiseTax to Map<String, double>
        Map<String, double> parsedCategoryWiseTax = {};
        if (result['categoryWiseTax'] != null &&
            result['categoryWiseTax'] is Map) {
          (result['categoryWiseTax'] as Map).forEach((key, value) {
            if (key != null && value != null) {
              parsedCategoryWiseTax[key.toString()] = (value is num)
                  ? value.toDouble()
                  : double.tryParse(value.toString()) ?? 0.0;
            }
          });
        }
        setState(() {
          _yearlySalesTax = result['totalSalesTax'];
          _expenseTransactionCount = result['transactionCount'];
          _averageTaxRate = result['averageTaxRate'];
          _categoryWiseTax = parsedCategoryWiseTax;
          _showSalesTaxResults = true;
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

  // Salary Tax Calculation (Progressive Slabs)
  double calculateSalaryTax(double annualIncome) {
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
      return 1005000 + (annualIncome - 6000000) * 0.35;
    }
  }

  // Business/Professional Income Tax (Same as salary but no specific deductions)
  double calculateBusinessTax(double annualIncome) {
    return calculateSalaryTax(annualIncome);
  }

  // Property Income Tax (15% with 20% maintenance deduction)
  double calculatePropertyTax(double annualRent) {
    double netRent =
        annualRent - (annualRent * 0.20); // 20% maintenance deduction
    _maintenanceDeduction = annualRent * 0.20;
    return netRent * 0.15; // 15% tax on net rent
  }

  // Capital Gains Tax
  double calculateCapitalGainsTax(double gainAmount) {
    switch (_holdingPeriod) {
      case '< 1 year':
        return gainAmount * 0.15; // 15%
      case '1-2 years':
        return gainAmount * 0.125; // 12.5%
      case '2-3 years':
        return gainAmount * 0.075; // 7.5%
      case '> 3 years':
        return 0; // 0%
      default:
        return gainAmount * 0.15;
    }
  }

  // Dividend Tax
  double calculateDividendTax(double dividendAmount) {
    if (_companyType == 'Listed') {
      return dividendAmount * 0.15; // 15%
    } else {
      return dividendAmount * 0.25; // 25%
    }
  }

  // Main tax calculation based on selected income type
  double calculateTax(double income, IncomeType type) {
    switch (type) {
      case IncomeType.salary:
        return calculateSalaryTax(income);
      case IncomeType.business:
        return calculateBusinessTax(income);
      case IncomeType.property:
        return calculatePropertyTax(income);
      case IncomeType.capitalGains:
        return calculateCapitalGainsTax(income);
      case IncomeType.dividends:
        return calculateDividendTax(income);
    }
  }

  void _calculateTax() {
    if (_formKey.currentState!.validate()) {
      double inputAmount = double.tryParse(_monthlyIncomeController.text) ?? 0;

      setState(() {
        // For salary and business, multiply by 12 for annual calculation
        if (_selectedIncomeType == IncomeType.salary ||
            _selectedIncomeType == IncomeType.business) {
          _annualIncome = inputAmount * 12;
        } else {
          // For other types, treat as annual amount
          _annualIncome = inputAmount;
        }

        _calculatedTax = calculateTax(_annualIncome, _selectedIncomeType);
        _finalTax = _calculatedTax;
        _monthlyTax = _finalTax / 12;
        _showResults = true;
      });
    }
  }

  // Get input field label based on income type
  String get _inputFieldLabel {
    switch (_selectedIncomeType) {
      case IncomeType.salary:
        return 'Enter your monthly salary';
      case IncomeType.business:
        return 'Enter your monthly business income';
      case IncomeType.property:
        return 'Enter annual rental income';
      case IncomeType.capitalGains:
        return 'Enter capital gains amount';
      case IncomeType.dividends:
        return 'Enter annual dividend amount';
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
                        // Category-wise breakdown (optional, only if data exists)
                        if (_categoryWiseTax.isNotEmpty) ...[
                          const Divider(height: 24),
                          const Text(
                            'Category-wise Sales Tax:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._categoryWiseTax.entries
                              .map((entry) => _buildSalesTaxRow(
                                    entry.key,
                                    'PKR ${entry.value.toStringAsFixed(2)}',
                                  )),
                        ],
                      ],
                    ],
                  ),
                ),
              ),

              // Income Input Container
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
                              child: Icon(
                                _selectedIncomeType.icon,
                                color: const Color.fromRGBO(127, 61, 255, 1),
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

                        // Income Type Dropdown
                        DropdownButtonFormField<IncomeType>(
                          value: _selectedIncomeType,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Select Income Type',
                            fillColor: const Color.fromRGBO(127, 61, 255, 0.1),
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          dropdownColor: Colors.white,
                          menuMaxHeight: 300,
                          borderRadius: BorderRadius.circular(12),
                          items: IncomeType.values.map((IncomeType type) {
                            return DropdownMenuItem<IncomeType>(
                              value: type,
                              child: Container(
                                constraints:
                                    const BoxConstraints(maxWidth: 280),
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        type.displayName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        type.description,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (IncomeType? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedIncomeType = newValue;
                                _monthlyIncomeController.clear();
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // Income Input Field
                        TextFormField(
                          controller: _monthlyIncomeController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: _inputFieldLabel,
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
                              return 'Please enter the amount';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Additional Fields based on Income Type
                        if (_selectedIncomeType == IncomeType.capitalGains) ...[
                          DropdownButtonFormField<String>(
                            value: _holdingPeriod,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Holding Period',
                              fillColor:
                                  const Color.fromRGBO(127, 61, 255, 0.1),
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.all(16),
                            ),
                            dropdownColor: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            items: [
                              '< 1 year',
                              '1-2 years',
                              '2-3 years',
                              '> 3 years'
                            ].map((String period) {
                              return DropdownMenuItem<String>(
                                value: period,
                                child: Text(
                                  period,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _holdingPeriod = newValue;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                        ],

                        if (_selectedIncomeType == IncomeType.dividends) ...[
                          DropdownButtonFormField<String>(
                            value: _companyType,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Company Type',
                              fillColor:
                                  const Color.fromRGBO(127, 61, 255, 0.1),
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.all(16),
                            ),
                            dropdownColor: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            items: ['Listed', 'Unlisted'].map((String type) {
                              return DropdownMenuItem<String>(
                                value: type,
                                child: Text(
                                  type,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _companyType = newValue;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Calculate Button
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
                              'Calculate',
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
                            Text(
                              '${_selectedIncomeType.displayName} Tax ',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Income Type specific results
                        if (_selectedIncomeType == IncomeType.salary ||
                            _selectedIncomeType == IncomeType.business) ...[
                          _buildResultRow(
                            'Annual Income:',
                            'PKR ${_annualIncome.toStringAsFixed(2)}',
                          ),
                          const Divider(height: 24),
                          _buildResultRow(
                            'Annual Tax:',
                            'PKR ${_finalTax.toStringAsFixed(2)}',
                            isHighlighted: true,
                          ),
                          const Divider(height: 24),
                          _buildResultRow(
                            'Monthly Tax:',
                            'PKR ${_monthlyTax.toStringAsFixed(2)}',
                          ),
                        ] else if (_selectedIncomeType ==
                            IncomeType.property) ...[
                          _buildResultRow(
                            'Annual Rental Income:',
                            'PKR ${_annualIncome.toStringAsFixed(2)}',
                          ),
                          const Divider(height: 24),
                          _buildResultRow(
                            'Maintenance Deduction (20%):',
                            'PKR ${_maintenanceDeduction.toStringAsFixed(2)}',
                          ),
                          const Divider(height: 24),
                          _buildResultRow(
                            'Net Taxable Income:',
                            'PKR ${(_annualIncome - _maintenanceDeduction).toStringAsFixed(2)}',
                          ),
                          const Divider(height: 24),
                          _buildResultRow(
                            'Tax (15% of Net Income):',
                            'PKR ${_finalTax.toStringAsFixed(2)}',
                            isHighlighted: true,
                          ),
                        ] else if (_selectedIncomeType ==
                            IncomeType.capitalGains) ...[
                          _buildResultRow(
                            'Capital Gains Amount:',
                            'PKR ${_annualIncome.toStringAsFixed(2)}',
                          ),
                          const Divider(height: 24),
                          _buildResultRow(
                            'Holding Period:',
                            _holdingPeriod,
                          ),
                          const Divider(height: 24),
                          _buildResultRow(
                            'Tax Rate:',
                            '${_getTaxRateDisplay()}%',
                          ),
                          const Divider(height: 24),
                          _buildResultRow(
                            'Capital Gains Tax:',
                            'PKR ${_finalTax.toStringAsFixed(2)}',
                            isHighlighted: true,
                          ),
                        ] else if (_selectedIncomeType ==
                            IncomeType.dividends) ...[
                          _buildResultRow(
                            'Dividend Amount:',
                            'PKR ${_annualIncome.toStringAsFixed(2)}',
                          ),
                          const Divider(height: 24),
                          _buildResultRow(
                            'Company Type:',
                            _companyType,
                          ),
                          const Divider(height: 24),
                          _buildResultRow(
                            'Tax Rate:',
                            '${_companyType == "Listed" ? "15" : "25"}%',
                          ),
                          const Divider(height: 24),
                          _buildResultRow(
                            'Dividend Tax:',
                            'PKR ${_finalTax.toStringAsFixed(2)}',
                            isHighlighted: true,
                          ),
                        ],

                        const SizedBox(height: 16),
                        // Reset Button
                        Container(
                          height: 48,
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _showResults = false;
                                _monthlyIncomeController.clear();
                                _annualIncome = 0;
                                _calculatedTax = 0;
                                _finalTax = 0;
                                _monthlyTax = 0;
                                _maintenanceDeduction = 0;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[600],
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Calculate Another Tax',
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

  // Helper method to get tax rate display for capital gains
  String _getTaxRateDisplay() {
    switch (_holdingPeriod) {
      case '< 1 year':
        return '15';
      case '1-2 years':
        return '12.5';
      case '2-3 years':
        return '7.5';
      case '> 3 years':
        return '0';
      default:
        return '15';
    }
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
