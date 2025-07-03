import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:ExpenseTracker/Services/BudgetModificationController.dart';
import 'package:flutter/services.dart';

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

  String selectedPeriod = 'monthly';
  bool alert = true;
  double _currentSliderValue = 80;
  String customAlertMessage = '';
  bool isLoading = false;

  @override
  void dispose() {
    amountController.dispose();
    nameController.dispose();
    descriptionController.dispose();
    super.dispose();
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

  // Helper for section card styling (adapted for purple)
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
                    color:
                        const Color.fromRGBO(127, 61, 255, 0.1), // purple tint
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: const Color.fromRGBO(127, 61, 255, 1), // purple
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

  // Helper for styled dropdown
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
              color: Color.fromRGBO(127, 61, 255, 1), width: 2), // purple
        ),
        filled: true,
        fillColor: Colors.grey.withOpacity(0.05),
      ),
    );
  }

  // Helper for styled text field
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
              color: Color.fromRGBO(127, 61, 255, 1), width: 2), // purple
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
        backgroundColor: const Color.fromRGBO(127, 61, 255, 1), // purple
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
                      const Color.fromRGBO(127, 61, 255, 1), // purple
                      const Color.fromRGBO(127, 61, 255, 0.8), // purple tint
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
                            'Create Budget',
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
                    // Amount Card
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
                            'How much do you want to spend?',
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
                                child: TextFormField(
                                  controller: amountController,
                                  cursorColor: Colors.white,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
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
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8.0),
                                        child: Text(
                                          'PKR',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
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
                                ),
                              ),
                            ],
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
                      // Budget Name Section
                      _buildSectionCard(
                        'Budget Name',
                        Icons.label,
                        [
                          _buildStyledTextField(
                            controller: nameController,
                            label: 'Budget Name (Required)',
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
                            controller: descriptionController,
                            label: 'Description (Optional)',
                            maxLines: 2,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Period Section
                      _buildSectionCard(
                        'Budget Period',
                        Icons.calendar_today,
                        [
                          _buildStyledDropdown<String>(
                            value: selectedPeriod,
                            items: _budgetController
                                .getBudgetPeriods()
                                .map((String period) {
                              return DropdownMenuItem<String>(
                                value: period,
                                child: Text(period.toUpperCase()),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedPeriod = value ?? 'monthly';
                              });
                            },
                            hint: 'Select Period',
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Alert Section
                      _buildSectionCard(
                        'Alert Settings',
                        Icons.notifications_active,
                        [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                activeColor:
                                    const Color.fromRGBO(127, 61, 255, 1),
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
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor:
                                    const Color.fromRGBO(127, 61, 255, 1),
                                inactiveTrackColor: Colors.grey[300],
                                thumbColor:
                                    const Color.fromRGBO(127, 61, 255, 1),
                                overlayColor:
                                    const Color.fromRGBO(127, 61, 255, 0.2),
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
                            _buildStyledTextField(
                              controller: TextEditingController(
                                  text: customAlertMessage),
                              label: 'Custom Alert Message',
                              onChanged: (value) {
                                setState(() {
                                  customAlertMessage = value;
                                });
                              },
                            ),
                          ],
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
                const Color.fromRGBO(127, 61, 255, 1), // purple
                const Color.fromRGBO(127, 61, 255, 0.8), // purple tint
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color.fromRGBO(127, 61, 255, 0.4), // purple shadow
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            onPressed: isLoading ? null : saveBudget,
            backgroundColor: Colors.transparent,
            elevation: 0,
            icon: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check, color: Colors.white, size: 24),
            label: const Text(
              'Create Budget',
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
