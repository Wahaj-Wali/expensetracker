import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Services/CategoriesService.dart';

class SplitBillScreen extends StatefulWidget {
  const SplitBillScreen({Key? key}) : super(key: key);

  @override
  State<SplitBillScreen> createState() => _SplitBillScreenState();
}

class _SplitBillScreenState extends State<SplitBillScreen> {
  final _formKey = GlobalKey<FormState>();
  final _totalAmountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _participantController = TextEditingController();

  String _selectedSplitType = 'equal';
  List<String> _participants = [];
  Map<String, double> _customAmounts = {};
  Map<String, double> _percentages = {};
  Map<String, TextEditingController> _customControllers = {};
  Map<String, TextEditingController> _percentageControllers = {};

  bool _isLoading = false;

  List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email') ?? '';
    final categories = await DefaultCategoriesService.getAllCategories(email);
    setState(() {
      _categories = categories;
    });
  }

  @override
  void dispose() {
    _totalAmountController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _participantController.dispose();
    for (var controller in _customControllers.values) {
      controller.dispose();
    }
    for (var controller in _percentageControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addParticipant() {
    final name = _participantController.text.trim();
    if (name.isNotEmpty && !_participants.contains(name)) {
      setState(() {
        _participants.add(name);
        _customControllers[name] = TextEditingController();
        _percentageControllers[name] = TextEditingController();
        _participantController.clear();
      });
    }
  }

  void _removeParticipant(String name) {
    setState(() {
      _participants.remove(name);
      _customAmounts.remove(name);
      _percentages.remove(name);
      _customControllers[name]?.dispose();
      _customControllers.remove(name);
      _percentageControllers[name]?.dispose();
      _percentageControllers.remove(name);
    });
  }

  void _updateCustomAmount(String name, String value) {
    final amount = double.tryParse(value) ?? 0.0;
    setState(() {
      _customAmounts[name] = amount;
    });
  }

  void _updatePercentage(String name, String value) {
    final percentage = double.tryParse(value) ?? 0.0;
    setState(() {
      _percentages[name] = percentage;
    });
  }

  double _getTotalCustomAmount() {
    return _customAmounts.values.fold(0.0, (sum, amount) => sum + amount);
  }

  double _getTotalPercentage() {
    return _percentages.values.fold(0.0, (sum, percentage) => sum + percentage);
  }

  Future<void> _createSplitBill() async {
    if (!_formKey.currentState!.validate()) return;
    if (_participants.isEmpty) {
      _showSnackBar('Please add at least one participant');
      return;
    }

    final totalAmount = double.tryParse(_totalAmountController.text) ?? 0.0;

    // Validate split amounts
    if (_selectedSplitType == 'custom') {
      final totalCustom = _getTotalCustomAmount();
      if ((totalCustom - totalAmount).abs() > 0.01) {
        _showSnackBar('Custom amounts must equal the total amount');
        return;
      }
    } else if (_selectedSplitType == 'percentage') {
      final totalPercentage = _getTotalPercentage();
      if ((totalPercentage - 100.0).abs() > 0.01) {
        _showSnackBar('Percentages must add up to 100%');
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Here you would call your SplitBillController
      // final result = await SplitBillController().createSplitBill(
      //   totalAmount: totalAmount,
      //   description: _descriptionController.text,
      //   categoryName: _categoryController.text,
      //   accountName: '', // Not needed as per requirement
      //   participants: _participants,
      //   splitType: _selectedSplitType,
      //   customAmounts: _selectedSplitType == 'custom' ? _customAmounts : null,
      //   percentages: _selectedSplitType == 'percentage' ? _percentages : null,
      // );

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      _showSnackBar('Split bill created successfully!');
      Navigator.pop(context);
    } catch (e) {
      _showSnackBar('Failed to create split bill: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
          "Split Bill",
          style: TextStyle(
            color: Colors.black,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildBillDetailsSection(),
              const SizedBox(height: 16),
              _buildParticipantsSection(),
              const SizedBox(height: 16),
              _buildSplitTypeSection(),
              const SizedBox(height: 16),
              _buildSplitDetailsSection(),
              const SizedBox(height: 24),
              _buildCreateButton(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBillDetailsSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
                    Icons.receipt,
                    color: Color.fromRGBO(127, 61, 255, 1),
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Bill Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _totalAmountController,
              decoration: InputDecoration(
                labelText: 'Total Amount',
                prefixText: '\$ ',
                fillColor: const Color.fromRGBO(127, 61, 255, 0.1),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Please enter total amount';
                final amount = double.tryParse(value!);
                if (amount == null || amount <= 0)
                  return 'Please enter a valid amount';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                fillColor: const Color.fromRGBO(127, 61, 255, 0.1),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Please enter a description';
                return null;
              },
            ),
            const SizedBox(height: 16),
            Theme(
              data: Theme.of(context).copyWith(
                canvasColor: Colors.white,
                cardTheme: CardTheme(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        24), // Increased for more roundness
                  ),
                ),
              ),
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Category',
                  fillColor: const Color.fromRGBO(127, 61, 255, 0.1),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(16), // Match popup roundness
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                value: _categoryController.text.isEmpty
                    ? null
                    : _categoryController.text,
                items: _categories.map<DropdownMenuItem<String>>((category) {
                  return DropdownMenuItem<String>(
                    value: category['name'],
                    child: Text(category['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _categoryController.text = value ?? '';
                  });
                },
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Please select a category';
                  return null;
                },
                dropdownColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantsSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
                    Icons.group,
                    color: Color.fromRGBO(127, 61, 255, 1),
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Participants',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _participantController,
                    decoration: InputDecoration(
                      labelText: 'Participant Name',
                      fillColor: const Color.fromRGBO(127, 61, 255, 0.1),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    keyboardType: TextInputType.text,
                    onFieldSubmitted: (_) => _addParticipant(),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _addParticipant,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(127, 61, 255, 1),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Add',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_participants.isNotEmpty) ...[
              const Text('Added Participants:'),
              const SizedBox(height: 8),
              ..._participants.map((name) => Card(
                    color: Colors.grey[50],
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(name),
                      trailing: IconButton(
                        icon:
                            const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () => _removeParticipant(name),
                      ),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSplitTypeSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
                    Icons.call_split,
                    color: Color.fromRGBO(127, 61, 255, 1),
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Split Type',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            RadioListTile<String>(
              title: const Text('Equal Split'),
              subtitle: const Text('Split equally among all participants'),
              value: 'equal',
              groupValue: _selectedSplitType,
              onChanged: (value) {
                setState(() {
                  _selectedSplitType = value!;
                });
              },
              activeColor: const Color.fromRGBO(127, 61, 255, 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            RadioListTile<String>(
              title: const Text('Custom Amount'),
              subtitle: const Text('Set custom amount for each participant'),
              value: 'custom',
              groupValue: _selectedSplitType,
              onChanged: (value) {
                setState(() {
                  _selectedSplitType = value!;
                });
              },
              activeColor: const Color.fromRGBO(127, 61, 255, 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            RadioListTile<String>(
              title: const Text('Percentage'),
              subtitle: const Text('Split by percentage'),
              value: 'percentage',
              groupValue: _selectedSplitType,
              onChanged: (value) {
                setState(() {
                  _selectedSplitType = value!;
                });
              },
              activeColor: const Color.fromRGBO(127, 61, 255, 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSplitDetailsSection() {
    if (_participants.isEmpty) return const SizedBox.shrink();

    final totalAmount = double.tryParse(_totalAmountController.text) ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
                    Icons.pie_chart,
                    color: Color.fromRGBO(127, 61, 255, 1),
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Split Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_selectedSplitType == 'equal') ...[
              Text(
                'Each person pays: \$${totalAmount > 0 ? (totalAmount / (_participants.length + 1)).toStringAsFixed(2) : '0.00'}',
                style: const TextStyle(
                  color: Color.fromRGBO(127, 61, 255, 1),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              ..._participants.map((name) => ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(name),
                    trailing: Text(
                      '\$${totalAmount > 0 ? (totalAmount / (_participants.length + 1)).toStringAsFixed(2) : '0.00'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  )),
            ] else if (_selectedSplitType == 'custom') ...[
              Text(
                'Total: \$${_getTotalCustomAmount().toStringAsFixed(2)} / \$${totalAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  color: (_getTotalCustomAmount() - totalAmount).abs() > 0.01
                      ? Colors.red
                      : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ..._participants.map((name) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(name),
                        ),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _customControllers[name],
                            decoration: InputDecoration(
                              prefixText: '\$ ',
                              fillColor:
                                  const Color.fromRGBO(127, 61, 255, 0.1),
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.all(12),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}')),
                            ],
                            onChanged: (value) =>
                                _updateCustomAmount(name, value),
                          ),
                        ),
                      ],
                    ),
                  )),
            ] else if (_selectedSplitType == 'percentage') ...[
              Text(
                'Total: ${_getTotalPercentage().toStringAsFixed(1)}% / 100%',
                style: TextStyle(
                  color: (_getTotalPercentage() - 100.0).abs() > 0.01
                      ? Colors.red
                      : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ..._participants.map((name) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(name),
                            ),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _percentageControllers[name],
                                decoration: InputDecoration(
                                  suffixText: '%',
                                  fillColor:
                                      const Color.fromRGBO(127, 61, 255, 0.1),
                                  filled: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.all(12),
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d+\.?\d{0,2}')),
                                ],
                                onChanged: (value) =>
                                    _updatePercentage(name, value),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'Amount: \$${totalAmount > 0 && _percentages[name] != null ? (totalAmount * (_percentages[name]! / 100)).toStringAsFixed(2) : '0.00'}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _createSplitBill,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromRGBO(127, 61, 255, 1),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Create Split Bill',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
      ),
    );
  }
}
