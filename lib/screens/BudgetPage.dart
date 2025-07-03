// lib/Pages/BudgetPage.dart
import 'package:flutter/material.dart';
import 'package:ExpenseTracker/Services/BudgetService.dart';
import 'dart:developer';

import 'package:flutter/services.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({Key? key}) : super(key: key);

  @override
  _BudgetPageState createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  final BudgetService _budgetService = BudgetService();
  List<Map<String, dynamic>> _budgets = [];
  List<Map<String, dynamic>> _budgetAlerts = [];
  Map<String, dynamic> _budgetSummary = {};
  bool _isLoading = true;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadBudgetData();
  }

  Future<void> _loadBudgetData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final budgets = await _budgetService.getAllBudgetsWithTracking();
      final alerts = await _budgetService.getBudgetAlerts();
      final summary = await _budgetService.getBudgetSummary();

      setState(() {
        _budgets = budgets;
        _budgetAlerts = alerts;
        _budgetSummary = summary;
        _isLoading = false;
      });
    } catch (e) {
      log("Error loading budget data: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredBudgets {
    if (_selectedFilter == 'All') {
      return _budgets;
    } else if (_selectedFilter == 'Active') {
      return _budgets.where((budget) => budget['isActive'] == true).toList();
    } else if (_selectedFilter == 'Inactive') {
      return _budgets.where((budget) => budget['isActive'] == false).toList();
    } else if (_selectedFilter == 'Over Budget') {
      return _budgets.where((budget) {
        double spentPercentage =
            (budget['spentAmount'] ?? 0) / (budget['budgetAmount'] ?? 1) * 100;
        return spentPercentage >= 100;
      }).toList();
    }
    return _budgets;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Budget Overview',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[700],
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadBudgetData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadBudgetData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildBudgetSummaryCard(),
                    _buildBudgetAlertsCard(),
                    _buildFilterRow(),
                    _buildBudgetsList(),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddBudgetPage(),
            ),
          );
          if (result == true) {
            _loadBudgetData();
          }
        },
        backgroundColor: Colors.blue[700],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBudgetSummaryCard() {
    if (_budgetSummary.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[700]!, Colors.blue[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Budget Summary',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem(
                'Total Budgets',
                _budgetSummary['totalBudgets']?.toString() ?? '0',
                Icons.account_balance_wallet,
              ),
              _buildSummaryItem(
                'Active Budgets',
                _budgetSummary['activeBudgets']?.toString() ?? '0',
                Icons.trending_up,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem(
                'Total Allocated',
                _budgetService
                    .formatCurrency(_budgetSummary['totalAllocated'] ?? 0),
                Icons.attach_money,
              ),
              _buildSummaryItem(
                'Total Spent',
                _budgetService
                    .formatCurrency(_budgetSummary['totalSpent'] ?? 0),
                Icons.money_off,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetAlertsCard() {
    if (_budgetAlerts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: Colors.orange[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Budget Alerts (${_budgetAlerts.length})',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...(_budgetAlerts.take(3).map((alert) => _buildAlertItem(alert))),
          if (_budgetAlerts.length > 3)
            TextButton(
              onPressed: _showAllAlerts,
              child: Text('View all ${_budgetAlerts.length} alerts'),
            ),
        ],
      ),
    );
  }

  Widget _buildAlertItem(Map<String, dynamic> alert) {
    double spentPercentage =
        (alert['spentAmount'] ?? 0) / (alert['budgetAmount'] ?? 1) * 100;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            _budgetService.getBudgetStatusIcon(spentPercentage),
            color: _budgetService.getBudgetStatusColor(spentPercentage),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${alert['budgetName']} - ${_budgetService.formatPercentage(spentPercentage)} used',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    final filters = ['All', 'Active', 'Inactive', 'Over Budget'];

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;

          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              selectedColor: Colors.blue[100],
              checkmarkColor: Colors.blue[700],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBudgetsList() {
    if (_filteredBudgets.isEmpty) {
      return Container(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No budgets found',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create your first budget to get started',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _filteredBudgets.length,
      itemBuilder: (context, index) {
        final budget = _filteredBudgets[index];
        return _buildBudgetCard(budget);
      },
    );
  }

  Widget _buildBudgetCard(Map<String, dynamic> budget) {
    double spentAmount = budget['spentAmount']?.toDouble() ?? 0.0;
    double budgetAmount = budget['budgetAmount']?.toDouble() ?? 0.0;
    double spentPercentage =
        budgetAmount > 0 ? (spentAmount / budgetAmount) * 100 : 0;

    DateTime? endDate =
        budget['endDate'] != null ? DateTime.tryParse(budget['endDate']) : null;
    String timeRemaining = endDate != null
        ? _budgetService.formatTimeRemaining(endDate)
        : 'No end date';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.white,
              Colors.grey[50]!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      budget['budgetName'] ?? 'Unnamed Budget',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _budgetService
                          .getBudgetStatusColor(spentPercentage)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _budgetService
                            .getBudgetStatusColor(spentPercentage)
                            .withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _budgetService.getBudgetStatusIcon(spentPercentage),
                          size: 14,
                          color: _budgetService
                              .getBudgetStatusColor(spentPercentage),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _budgetService.getBudgetStatusText(spentPercentage),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _budgetService
                                .getBudgetStatusColor(spentPercentage),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _budgetService.formatCurrency(spentAmount),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'of ${_budgetService.formatCurrency(budgetAmount)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: spentPercentage / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _budgetService.getBudgetStatusColor(spentPercentage),
                    ),
                    minHeight: 8,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_budgetService.formatPercentage(spentPercentage)} used',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildBudgetDetail(
                      'Period',
                      budget['budgetPeriod'] ?? 'N/A',
                      Icons.calendar_today,
                    ),
                  ),
                  Expanded(
                    child: _buildBudgetDetail(
                      'Remaining',
                      _budgetService.formatCurrency(budgetAmount - spentAmount),
                      Icons.account_balance_wallet,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildBudgetDetail(
                      'Time Left',
                      timeRemaining,
                      Icons.access_time,
                    ),
                  ),
                  Expanded(
                    child: _buildBudgetDetail(
                      'Categories',
                      '${budget['categoryCount'] ?? 0} selected',
                      Icons.category,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _viewBudgetDetails(budget),
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('View Details'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue[700],
                        side: BorderSide(color: Colors.blue[700]!),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _editBudget(budget),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetDetail(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showAllAlerts() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('All Budget Alerts'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _budgetAlerts.length,
            itemBuilder: (context, index) {
              return _buildAlertItem(_budgetAlerts[index]);
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _viewBudgetDetails(Map<String, dynamic> budget) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(budget['budgetName'] ?? 'Budget Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Amount: ${_budgetService.formatCurrency(budget['budgetAmount'] ?? 0)}'),
            Text(
                'Spent: ${_budgetService.formatCurrency(budget['spentAmount'] ?? 0)}'),
            Text('Period: ${budget['budgetPeriod'] ?? 'N/A'}'),
            if (budget['description'] != null)
              Text('Description: ${budget['description']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _editBudget(Map<String, dynamic> budget) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddBudgetPage(budget: budget),
      ),
    ).then((result) {
      if (result == true) {
        _loadBudgetData();
      }
    });
  }

  @override
  void dispose() {
    _budgetService.dispose();
    super.dispose();
  }
}

// lib/Pages/AddBudgetPage.dart

class AddBudgetPage extends StatefulWidget {
  final Map<String, dynamic>? budget;
  final String? userEmail;

  const AddBudgetPage({Key? key, this.budget, this.userEmail})
      : super(key: key);

  @override
  _AddBudgetPageState createState() => _AddBudgetPageState();
}

class _AddBudgetPageState extends State<AddBudgetPage> {
  final _formKey = GlobalKey<FormState>();
  final _budgetService = BudgetService();

  // Form controllers
  final _budgetNameController = TextEditingController();
  final _budgetAmountController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Form variables
  String _selectedPeriod = 'Monthly';
  List<String> _selectedCategories = [];
  DateTime? _startDate;
  DateTime? _endDate;

  // Available data
  List<Map<String, dynamic>> _availableCategories = [];
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadAvailableCategories();
    if (widget.budget != null) {
      _populateFormWithExistingBudget();
    }
  }

  void _populateFormWithExistingBudget() {
    final budget = widget.budget!;
    _budgetNameController.text = budget['budgetName'] ?? '';
    _budgetAmountController.text = budget['budgetAmount']?.toString() ?? '';
    _descriptionController.text = budget['description'] ?? '';
    _selectedPeriod = budget['budgetPeriod'] ?? 'Monthly';
    _selectedCategories = List<String>.from(budget['categoryIds'] ?? []);

    if (budget['startDate'] != null) {
      _startDate = DateTime.tryParse(budget['startDate']);
    }
    if (budget['endDate'] != null) {
      _endDate = DateTime.tryParse(budget['endDate']);
    }
  }

  Future<void> _loadAvailableCategories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final categories = await _budgetService.getAvailableCategories(
        widget.userEmail ?? '',
      );
      setState(() {
        _availableCategories = categories;
        _isLoading = false;
      });
    } catch (e) {
      log("Error loading categories: $e");
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading categories: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _updateDatesBasedOnPeriod() {
    DateTime now = DateTime.now();
    setState(() {
      switch (_selectedPeriod) {
        case 'Weekly':
          _startDate = now;
          _endDate = now.add(const Duration(days: 7));
          break;
        case 'Monthly':
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = DateTime(now.year, now.month + 1, 0);
          break;
        case 'Yearly':
          _startDate = DateTime(now.year, 1, 1);
          _endDate = DateTime(now.year, 12, 31);
          break;
      }
    });
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.budget != null ? 'Edit Budget' : 'Add Budget',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[700],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBudgetNameField(),
                      const SizedBox(height: 20),
                      _buildBudgetAmountField(),
                      const SizedBox(height: 20),
                      _buildBudgetPeriodField(),
                      const SizedBox(height: 20),
                      _buildDateRangeField(),
                      const SizedBox(height: 20),
                      _buildCategoriesField(),
                      const SizedBox(height: 20),
                      _buildDescriptionField(),
                      const SizedBox(height: 32),
                      _buildSaveButton(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildBudgetNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Budget Name',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _budgetNameController,
          decoration: InputDecoration(
            hintText: 'Enter budget name',
            prefixIcon: const Icon(Icons.label),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a budget name';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildBudgetAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Budget Amount',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _budgetAmountController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          decoration: InputDecoration(
            hintText: 'Enter amount',
            prefixIcon: const Icon(Icons.attach_money),
            prefixText: 'PKR ',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a budget amount';
            }
            final amount = double.tryParse(value);
            if (amount == null || amount <= 0) {
              return 'Please enter a valid amount greater than 0';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildBudgetPeriodField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Budget Period',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedPeriod,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down),
              items: _budgetService.getBudgetPeriods().map((period) {
                return DropdownMenuItem<String>(
                  value: period,
                  child: Text(period),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPeriod = value!;
                  _updateDatesBasedOnPeriod();
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateRangeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Budget Period Dates',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _selectStartDate(),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 20),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Start Date',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            _startDate != null
                                ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                                : 'Select date',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => _selectEndDate(),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 20),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'End Date',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            _endDate != null
                                ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                                : 'Select date',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoriesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Categories',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Selected Categories (${_selectedCategories.length})',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextButton(
                    onPressed: _showCategoriesDialog,
                    child: const Text('Select Categories'),
                  ),
                ],
              ),
              if (_selectedCategories.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _selectedCategories.map((categoryId) {
                    final category = _availableCategories.firstWhere(
                      (cat) => cat['id'] == categoryId,
                      orElse: () => {'name': 'Unknown', 'id': categoryId},
                    );
                    return Chip(
                      label: Text(category['name']),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setState(() {
                          _selectedCategories.remove(categoryId);
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description (Optional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Enter description for this budget',
            prefixIcon: const Icon(Icons.description),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveBudget,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                widget.budget != null ? 'Update Budget' : 'Create Budget',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  void _showCategoriesDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select Categories'),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: ListView.builder(
                  itemCount: _availableCategories.length,
                  itemBuilder: (context, index) {
                    final category = _availableCategories[index];
                    final isSelected =
                        _selectedCategories.contains(category['id']);
                    return CheckboxListTile(
                      title: Text(category['name']),
                      subtitle: category['description'] != null
                          ? Text(category['description'])
                          : null,
                      value: isSelected,
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            _selectedCategories.add(category['id']);
                          } else {
                            _selectedCategories.remove(category['id']);
                          }
                        });
                        setState(() {});
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one category'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select start and end dates'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate dates
    final dateValidation = _budgetService.validateBudgetDates(
      startDate: _startDate!,
      endDate: _endDate!,
      budgetPeriod: _selectedPeriod,
    );

    if (!dateValidation['isValid']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(dateValidation['message']),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      Map<String, dynamic> result;

      if (widget.budget != null) {
        // Update existing budget
        result = await _budgetService.updateBudget(
          budgetId: widget.budget!['id'],
          budgetName: _budgetNameController.text.trim(),
          budgetAmount: double.parse(_budgetAmountController.text),
          budgetPeriod: _selectedPeriod,
          categoryIds: _selectedCategories,
          startDate: _startDate,
          endDate: _endDate,
          description: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
        );
      } else {
        // Create new budget
        result = await _budgetService.createBudget(
          budgetName: _budgetNameController.text.trim(),
          budgetAmount: double.parse(_budgetAmountController.text),
          budgetPeriod: _selectedPeriod,
          categoryIds: _selectedCategories,
          startDate: _startDate,
          endDate: _endDate,
          description: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
        );
      }

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.budget != null
                  ? 'Budget updated successfully!'
                  : 'Budget created successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to save budget'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      log("Error saving budget: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving budget: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  void dispose() {
    _budgetNameController.dispose();
    _budgetAmountController.dispose();
    _descriptionController.dispose();
    _budgetService.dispose();
    super.dispose();
  }
}
