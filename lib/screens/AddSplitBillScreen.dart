import 'package:ExpenseTracker/Services/SplitBillController.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ExpenseTracker/Services/AccountController.dart';
import 'package:ExpenseTracker/Services/CategoriesService.dart';

class AddSplitBillScreen extends StatefulWidget {
  const AddSplitBillScreen({Key? key}) : super(key: key);

  @override
  _AddSplitBillScreenState createState() => _AddSplitBillScreenState();
}

class _AddSplitBillScreenState extends State<AddSplitBillScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final SplitBillService _splitBillService = SplitBillService();
  final AccountController _accountController = AccountController();
  final _participantControllers = <Map<String, TextEditingController>>[];
  List<Map<String, dynamic>> _accounts = [];
  List<Map<String, dynamic>> _categories = [];
  String? _selectedAccount;
  String? _selectedCategory;
  String _selectedSplitType = 'equal';
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    for (var controllers in _participantControllers) {
      controllers['name']?.dispose();
      controllers['email']?.dispose();
      controllers['amount']?.dispose();
      controllers['percentage']?.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final accounts = await _accountController.getAllAccounts();
      final categories = await DefaultCategoriesService.getAllCategories('');

      setState(() {
        _accounts = accounts;
        _categories = categories;
        if (_accounts.isNotEmpty) {
          _selectedAccount = _accounts.first['account_name'];
        }
        if (_categories.isNotEmpty) {
          _selectedCategory = _categories.first['name'];
        }
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading data: $e'),
          backgroundColor: const Color.fromRGBO(253, 60, 74, 1),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  void _addParticipant() {
    setState(() {
      _participantControllers.add({
        'name': TextEditingController(),
        'email': TextEditingController(),
        'amount': TextEditingController(),
        'percentage': TextEditingController(),
      });
    });
  }

  void _removeParticipant(int index) {
    setState(() {
      _participantControllers[index]['name']?.dispose();
      _participantControllers[index]['email']?.dispose();
      _participantControllers[index]['amount']?.dispose();
      _participantControllers[index]['percentage']?.dispose();
      _participantControllers.removeAt(index);
    });
  }

  void _onSplitTypeChanged(String splitType) {
    setState(() {
      _selectedSplitType = splitType;
    });
  }

  double _calculateUserShare() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount == 0) return 0.0;

    switch (_selectedSplitType) {
      case 'equal':
        return amount / (_participantControllers.length + 1);
      case 'percentage':
        double totalPercentage = 0.0;
        for (var controller in _participantControllers) {
          totalPercentage +=
              double.tryParse(controller['percentage']!.text) ?? 0.0;
        }
        return amount * (100 - totalPercentage) / 100;
      case 'custom':
        double totalCustom = 0.0;
        for (var controller in _participantControllers) {
          totalCustom += double.tryParse(controller['amount']!.text) ?? 0.0;
        }
        return amount - totalCustom;
      default:
        return 0.0;
    }
  }

  bool _validateSplitAmounts() {
    final totalAmount = double.tryParse(_amountController.text) ?? 0.0;
    if (totalAmount <= 0) return false;

    switch (_selectedSplitType) {
      case 'percentage':
        double totalPercentage = 0.0;
        for (var controller in _participantControllers) {
          totalPercentage +=
              double.tryParse(controller['percentage']!.text) ?? 0.0;
        }
        return totalPercentage <= 100;

      case 'custom':
        double totalCustom = 0.0;
        for (var controller in _participantControllers) {
          totalCustom += double.tryParse(controller['amount']!.text) ?? 0.0;
        }
        return totalCustom <= totalAmount;

      default:
        return true;
    }
  }

  Future<void> _saveSplitBill() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Color.fromRGBO(253, 60, 74, 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_participantControllers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one participant'),
          backgroundColor: Color.fromRGBO(253, 60, 74, 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!_validateSplitAmounts()) {
      String errorMessage = _selectedSplitType == 'percentage'
          ? 'Total percentage cannot exceed 100%'
          : 'Total custom amounts cannot exceed the bill amount';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: const Color.fromRGBO(253, 60, 74, 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final participants = _participantControllers.map((controllers) {
      return {
        'name': controllers['name']!.text,
        'email': controllers['email']!.text,
      };
    }).toList();

    Map<String, double>? customAmounts;
    Map<String, double>? percentages;

    if (_selectedSplitType == 'custom') {
      customAmounts = {};
      for (int i = 0; i < _participantControllers.length; i++) {
        final email = _participantControllers[i]['email']!.text;
        final customAmount =
            double.tryParse(_participantControllers[i]['amount']!.text) ?? 0.0;
        customAmounts[email] = customAmount;
      }
    } else if (_selectedSplitType == 'percentage') {
      percentages = {};
      for (int i = 0; i < _participantControllers.length; i++) {
        final email = _participantControllers[i]['email']!.text;
        final percentage =
            double.tryParse(_participantControllers[i]['percentage']!.text) ??
                0.0;
        percentages[email] = percentage;
      }
    }

    try {
      final result = await _splitBillService.addSplitBill(
        accountName: _selectedAccount!,
        totalAmount: amount,
        categoryName: _selectedCategory!,
        participants: participants,
        description: _descriptionController.text,
        splitType: _selectedSplitType,
        customAmounts: customAmounts,
        percentages: percentages,
      );

      if (result['success']) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: const Color.fromRGBO(253, 60, 74, 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating split bill: $e'),
          backgroundColor: const Color.fromRGBO(253, 60, 74, 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white, // changed from purple to white
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
                Color.fromRGBO(127, 61, 255, 1)), // changed to purple
          ),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color.fromRGBO(127, 61, 255, 1),
        body: SafeArea(
          child: Column(
            children: [
              // Custom Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color.fromRGBO(127, 61, 255, 1),
                      const Color.fromRGBO(127, 61, 255, 0.8),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    // App bar
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
                            'Create Split Bill',
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

                    // Amount Display
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Your Share',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Rs${_calculateUserShare().toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Split Type Tabs (custom, like SplitBill.dart)
              Container(
                color: const Color.fromRGBO(127, 61, 255, 1),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    children: [
                      _buildSplitTypeTab('equal', 'Equal'),
                      _buildSplitTypeTab('percentage', 'Percentage'),
                      _buildSplitTypeTab('custom', 'Custom'),
                    ],
                  ),
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
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        // Basic Info Section
                        _buildSectionCard(
                          'Basic Information',
                          Icons.info_outline,
                          [
                            _buildStyledDropdown(
                              value: _selectedAccount,
                              items: _accounts
                                  .map<DropdownMenuItem<String>>((account) {
                                return DropdownMenuItem<String>(
                                  value: account['account_name'] as String,
                                  child:
                                      Text(account['account_name'] as String),
                                );
                              }).toList(),
                              onChanged: (value) =>
                                  setState(() => _selectedAccount = value),
                              hint: 'Select Account',
                              validator: (value) => value == null
                                  ? 'Please select an account'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            _buildStyledTextField(
                              controller: _amountController,
                              label: 'Total Amount',
                              prefixText: 'Rs',
                              keyboardType: TextInputType.number,
                              validator: (value) => value?.isEmpty ?? true
                                  ? 'Please enter an amount'
                                  : null,
                              onChanged: (value) => setState(() {}),
                            ),
                            const SizedBox(height: 16),
                            _buildStyledDropdown(
                              value: _selectedCategory,
                              items: _categories
                                  .map<DropdownMenuItem<String>>((category) {
                                return DropdownMenuItem<String>(
                                  value: category['name'] as String,
                                  child: Text(category['name'] as String),
                                );
                              }).toList(),
                              onChanged: (value) =>
                                  setState(() => _selectedCategory = value),
                              hint: 'Select Category',
                              validator: (value) => value == null
                                  ? 'Please select a category'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            _buildStyledTextField(
                              controller: _descriptionController,
                              label: 'Description',
                              validator: (value) => value?.isEmpty ?? true
                                  ? 'Please enter a description'
                                  : null,
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Participants Section
                        _buildSectionCard(
                          'Participants',
                          Icons.group,
                          [
                            ..._participantControllers
                                .asMap()
                                .entries
                                .map((entry) {
                              final index = entry.key;
                              final controllers = entry.value;
                              return _buildParticipantCard(index, controllers);
                            }).toList(),
                            const SizedBox(height: 16),
                            _buildAddParticipantButton(),
                          ],
                        ),

                        const SizedBox(height: 100), // Space for FAB
                      ],
                    ),
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
                const Color.fromRGBO(127, 61, 255, 1),
                const Color.fromRGBO(127, 61, 255, 0.8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color.fromRGBO(127, 61, 255, 0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            onPressed: _saveSplitBill,
            backgroundColor: Colors.transparent,
            elevation: 0,
            icon: const Icon(Icons.check, color: Colors.white, size: 24),
            label: const Text(
              'Create Split Bill',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

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
                    color: const Color.fromRGBO(127, 61, 255, 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: const Color.fromRGBO(127, 61, 255, 1),
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

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    String? prefixText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
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
              color: Color.fromRGBO(127, 61, 255, 1), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.withOpacity(0.05),
      ),
    );
  }

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
              color: Color.fromRGBO(127, 61, 255, 1), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.withOpacity(0.05),
      ),
    );
  }

  Widget _buildParticipantCard(
      int index, Map<String, TextEditingController> controllers) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(127, 61, 255, 0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Color.fromRGBO(127, 61, 255, 1),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Participant',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _removeParticipant(index),
                icon: const Icon(
                  Icons.remove_circle,
                  color: Color.fromRGBO(253, 60, 74, 1),
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Name Field
          TextFormField(
            controller: controllers['name']!,
            validator: (value) =>
                value?.isEmpty ?? true ? 'Please enter name' : null,
            decoration: InputDecoration(
              labelText: 'Name',
              labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: Color.fromRGBO(127, 61, 255, 1)),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          const SizedBox(height: 12),

          // Email Field
          TextFormField(
            controller: controllers['email']!,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Please enter email';
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                  .hasMatch(value!)) {
                return 'Please enter valid email';
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: 'Email',
              labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: Color.fromRGBO(127, 61, 255, 1)),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),

          // Split-specific fields
          if (_selectedSplitType == 'percentage') ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: controllers['percentage']!,
              keyboardType: TextInputType.number,
              onChanged: (value) => setState(() {}),
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Please enter percentage';
                final percentage = double.tryParse(value!);
                if (percentage == null || percentage < 0 || percentage > 100) {
                  return 'Enter valid percentage (0-100)';
                }
                return null;
              },
              decoration: InputDecoration(
                labelText: 'Percentage',
                suffixText: '%',
                labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: Color.fromRGBO(127, 61, 255, 1)),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],

          if (_selectedSplitType == 'custom') ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: controllers['amount']!,
              keyboardType: TextInputType.number,
              onChanged: (value) => setState(() {}),
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Please enter amount';
                final amount = double.tryParse(value!);
                if (amount == null || amount < 0) {
                  return 'Enter valid amount';
                }
                return null;
              },
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: 'Rs',
                labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: Color.fromRGBO(127, 61, 255, 1)),
                ),
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddParticipantButton() {
    return GestureDetector(
      onTap: _addParticipant,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(127, 61, 255, 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color.fromRGBO(127, 61, 255, 0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Color.fromRGBO(127, 61, 255, 1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Add Participant',
              style: TextStyle(
                color: Color.fromRGBO(127, 61, 255, 1),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Add this helper for custom split type tabs
  Widget _buildSplitTypeTab(String type, String label) {
    bool isSelected = _selectedSplitType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onSplitTypeChanged(type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected
                  ? const Color.fromRGBO(127, 61, 255, 1)
                  : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
