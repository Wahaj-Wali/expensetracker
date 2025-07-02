import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:ExpenseTracker/Services/BudgetModificationController.dart';

class AddBudgetPage extends StatefulWidget {
  const AddBudgetPage({Key? key}) : super(key: key);

  @override
  State<AddBudgetPage> createState() => _AddBudgetPageState();
}

class _AddBudgetPageState extends State<AddBudgetPage>
    with TickerProviderStateMixin {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  final BudgetController _budgetController = BudgetController();

  late AnimationController _controller;
  double bottomContainerHeight = 400;
  String selectedPeriod = 'monthly';
  bool alert = true;
  double _currentSliderValue = 80;
  String customAlertMessage = '';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    amountController.dispose();
    nameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void onVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      bottomContainerHeight -= details.primaryDelta!;
      bottomContainerHeight = bottomContainerHeight.clamp(300.0, 600.0);
    });
  }

  void onVerticalDragEnd(DragEndDetails details) {
    // Optional: Add snap behavior here
  }

  Future<void> saveBudget() async {
    // Validate required fields
    if (nameController.text.trim().isEmpty) {
      _showErrorDialog('Budget Name is required');
      return;
    }

    if (amountController.text.trim().isEmpty) {
      _showErrorDialog('Budget amount is required');
      return;
    }

    double? budgetAmount;
    try {
      budgetAmount = double.parse(amountController.text.trim());
      if (budgetAmount <= 0) {
        _showErrorDialog('Budget amount must be greater than 0');
        return;
      }
    } catch (e) {
      _showErrorDialog('Please enter a valid budget amount');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      bool success = await _budgetController.createBudget(
        budgetName: nameController.text.trim(),
        budgetLimit: budgetAmount,
        period: selectedPeriod,
        description: descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),
        isAlert: alert,
        alertPercentage: _currentSliderValue,
        alertMessage: customAlertMessage.isEmpty ? null : customAlertMessage,
      );

      if (success) {
        _showSuccessDialog();
      } else {
        _showErrorDialog(
            'Failed to create budget. Budget name might already exist.');
      }
    } catch (e) {
      _showErrorDialog('An error occurred while creating the budget');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Color.fromRGBO(127, 61, 255, 1),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success'),
          content: const Text('Budget created successfully!'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to previous screen
              },
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Color.fromRGBO(127, 61, 255, 1),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(127, 61, 255, 1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Create Budget",
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: SizedBox(
          height: MediaQuery.of(context).size.height -
              AppBar().preferredSize.height -
              MediaQuery.of(context).padding.top,
          child: Stack(
            children: [
              Container(
                color: const Color.fromRGBO(127, 61, 255, 1),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      'How much do you want to spend?',
                      style: TextStyle(
                        color: Color.fromRGBO(255, 255, 255, 0.64),
                        fontSize: 18,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom * 0.5,
                      ),
                      child: TextField(
                        controller: amountController,
                        cursorColor: Colors.white,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 50,
                        ),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          prefixIcon: Container(
                            margin: const EdgeInsets.only(right: 8),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                'PKR',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          hintText: '0',
                          hintStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 50,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 0,
                child: GestureDetector(
                  onVerticalDragUpdate: onVerticalDragUpdate,
                  onVerticalDragEnd: onVerticalDragEnd,
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Container(
                        width: MediaQuery.of(context).size.width,
                        height: bottomContainerHeight,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(32),
                            topRight: Radius.circular(32),
                          ),
                        ),
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              children: [
                                const SizedBox(height: 16),
                                // Budget Name (Required)
                                TextField(
                                  controller: nameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Budget Name (Required)',
                                    hintText: 'e.g. Groceries, Rent, Utilities',
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(16.0)),
                                      borderSide: BorderSide(
                                          color: Color(0xFFF1F1FA), width: 1),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(16.0)),
                                      borderSide: BorderSide(
                                          color: Color(0xFFF1F1FA), width: 1),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(16.0)),
                                      borderSide: BorderSide(
                                          color:
                                              Color.fromRGBO(127, 61, 255, 1),
                                          width: 1),
                                    ),
                                    filled: true,
                                    fillColor: Color(0xFFF1F1FA),
                                  ),
                                  maxLines: 1,
                                ),
                                const SizedBox(height: 16),
                                // Optional Description Field
                                TextField(
                                  controller: descriptionController,
                                  decoration: const InputDecoration(
                                    labelText: 'Description (Optional)',
                                    hintText:
                                        'Add a description for this budget...',
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(16.0)),
                                      borderSide: BorderSide(
                                          color: Color(0xFFF1F1FA), width: 1),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(16.0)),
                                      borderSide: BorderSide(
                                          color: Color(0xFFF1F1FA), width: 1),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(16.0)),
                                      borderSide: BorderSide(
                                          color:
                                              Color.fromRGBO(127, 61, 255, 1),
                                          width: 1),
                                    ),
                                    filled: true,
                                    fillColor: Color(0xFFF1F1FA),
                                  ),
                                  maxLines: 2,
                                ),
                                const SizedBox(height: 16),
                                // Budget Period Selection
                                DropdownButtonFormField2<String>(
                                  decoration: InputDecoration(
                                    labelText: 'Budget Period',
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16.0),
                                      borderSide: const BorderSide(
                                          color: Color(0xFFF1F1FA), width: 1),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16.0),
                                      borderSide: const BorderSide(
                                          color: Color(0xFFF1F1FA), width: 1),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16.0),
                                      borderSide: const BorderSide(
                                          color:
                                              Color.fromRGBO(127, 61, 255, 1),
                                          width: 1),
                                    ),
                                  ),
                                  buttonStyleData: ButtonStyleData(
                                    height: 60,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      color: const Color(0xFFF1F1FA),
                                    ),
                                  ),
                                  iconStyleData: const IconStyleData(
                                    icon: Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: Colors.black54),
                                    iconSize: 24,
                                  ),
                                  dropdownStyleData: DropdownStyleData(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      color: Colors.white,
                                    ),
                                  ),
                                  items: _budgetController
                                      .getBudgetPeriods()
                                      .map((String period) {
                                    return DropdownMenuItem<String>(
                                      value: period,
                                      child: Text(
                                        period.toUpperCase(),
                                        style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.black87),
                                      ),
                                    );
                                  }).toList(),
                                  value: selectedPeriod,
                                  onChanged: (String? value) {
                                    setState(() {
                                      selectedPeriod = value ?? 'monthly';
                                    });
                                  },
                                ),
                                const SizedBox(height: 20),
                                // Alert Settings Section
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F1FA),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Receive Alert',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Switch(
                                            value: alert,
                                            onChanged: (value) {
                                              setState(() {
                                                alert = value;
                                              });
                                            },
                                            activeColor: const Color.fromRGBO(
                                                127, 61, 255, 1),
                                          ),
                                        ],
                                      ),
                                      if (alert) ...[
                                        const SizedBox(height: 16),
                                        Text(
                                          'Alert at ${_currentSliderValue.round()}% of budget',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black54,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        SliderTheme(
                                          data:
                                              SliderTheme.of(context).copyWith(
                                            activeTrackColor:
                                                const Color.fromRGBO(
                                                    127, 61, 255, 1),
                                            inactiveTrackColor:
                                                Colors.grey[300],
                                            thumbColor: const Color.fromRGBO(
                                                127, 61, 255, 1),
                                            overlayColor: const Color.fromRGBO(
                                                127, 61, 255, 0.2),
                                          ),
                                          child: Slider(
                                            value: _currentSliderValue,
                                            min: 50,
                                            max: 100,
                                            divisions: 10,
                                            onChanged: (value) {
                                              setState(() {
                                                _currentSliderValue = value;
                                              });
                                            },
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        TextField(
                                          onChanged: (value) {
                                            setState(() {
                                              customAlertMessage = value;
                                            });
                                          },
                                          decoration: InputDecoration(
                                            labelText: 'Custom Alert Message',
                                            hintText:
                                                "You've exceeded your budget limit!",
                                            isDense: true,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12.0),
                                              borderSide: const BorderSide(
                                                  color: Colors.grey, width: 1),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12.0),
                                              borderSide: const BorderSide(
                                                  color: Colors.grey, width: 1),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12.0),
                                              borderSide: const BorderSide(
                                                  color: Color.fromRGBO(
                                                      127, 61, 255, 1),
                                                  width: 1),
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: isLoading ? null : saveBudget,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          const Color.fromRGBO(127, 61, 255, 1),
                                      minimumSize:
                                          const Size(double.infinity, 48),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text(
                                            'Create Budget',
                                            style: TextStyle(
                                                fontSize: 18,
                                                color: Colors.white),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
