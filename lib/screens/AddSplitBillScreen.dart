import 'package:ExpenseTracker/Services/SplitBillController.dart';
import 'package:flutter/material.dart';

import 'package:ExpenseTracker/Services/AccountController.dart';
import 'package:ExpenseTracker/Services/CategoriesService.dart';

class AddSplitBillScreen extends StatefulWidget {
  const AddSplitBillScreen({Key? key}) : super(key: key);

  @override
  _AddSplitBillScreenState createState() => _AddSplitBillScreenState();
}

class _AddSplitBillScreenState extends State<AddSplitBillScreen> {
  final _formKey = GlobalKey<FormState>();
  final SplitBillService _splitBillService = SplitBillService();
  final AccountController _accountController = AccountController();
  final _participantControllers = <Map<String, TextEditingController>>[];
  List<Map<String, dynamic>> _accounts = [];
  List<Map<String, dynamic>> _categories = [];
  String? _selectedAccount;
  String? _selectedCategory;
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load accounts
      final accounts = await _accountController.getAllAccounts();
      // Load global categories
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
        SnackBar(content: Text('Error loading data: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  void _addParticipant() {
    setState(() {
      _participantControllers.add({
        'name': TextEditingController(),
        'email': TextEditingController(),
      });
    });
  }

  void _removeParticipant(int index) {
    setState(() {
      _participantControllers[index]['name']?.dispose();
      _participantControllers[index]['email']?.dispose();
      _participantControllers.removeAt(index);
    });
  }

  Future<void> _saveSplitBill() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text);
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    final participants = _participantControllers.map((controllers) {
      return {
        'name': controllers['name']!.text,
        'email': controllers['email']!.text,
      };
    }).toList();

    try {
      final result = await _splitBillService.addSplitBill(
        accountName: _selectedAccount!,
        totalAmount: amount,
        categoryName: _selectedCategory!,
        participants: participants,
        description: _descriptionController.text,
        notes: _notesController.text,
      );

      if (result['success']) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating split bill: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Split Bill'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Account dropdown
            DropdownButtonFormField<String>(
              value: _selectedAccount,
              decoration: const InputDecoration(labelText: 'Account'),
              items: _accounts.map<DropdownMenuItem<String>>((account) {
                return DropdownMenuItem<String>(
                  value: account['account_name'] as String,
                  child: Text(account['account_name'] as String),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedAccount = value),
              validator: (value) =>
                  value == null ? 'Please select an account' : null,
            ),
            const SizedBox(height: 16),

            // Amount field
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Total Amount',
                prefixText: '\$',
              ),
              keyboardType: TextInputType.number,
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter an amount' : null,
            ),
            const SizedBox(height: 16),

            // Category dropdown
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Category'),
              items: _categories.map<DropdownMenuItem<String>>((category) {
                return DropdownMenuItem<String>(
                  value: category['name'] as String,
                  child: Text(category['name'] as String),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedCategory = value),
              validator: (value) =>
                  value == null ? 'Please select a category' : null,
            ),
            const SizedBox(height: 16),

            // Description field
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter a description' : null,
            ),
            const SizedBox(height: 16),

            // Notes field
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes (Optional)'),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Participants section
            Text('Participants',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),

            ..._participantControllers.asMap().entries.map((entry) {
              final index = entry.key;
              final controllers = entry.value;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: controllers['name'],
                              decoration:
                                  const InputDecoration(labelText: 'Name'),
                              validator: (value) => value?.isEmpty ?? true
                                  ? 'Please enter a name'
                                  : null,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => _removeParticipant(index),
                          ),
                        ],
                      ),
                      TextFormField(
                        controller: controllers['email'],
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Please enter an email'
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),

            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: _addParticipant,
              icon: const Icon(Icons.person_add),
              label: const Text('Add Participant'),
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _saveSplitBill,
              child: const Text('Create Split Bill'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    for (var controllers in _participantControllers) {
      controllers['name']?.dispose();
      controllers['email']?.dispose();
    }
    super.dispose();
  }
}
