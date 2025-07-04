import 'package:flutter/material.dart';

class AddBudgetDialog extends StatefulWidget {
  final List<Map<String, dynamic>> categories;
  final Future<Map<String, dynamic>> Function({
    required String name,
    required double amount,
    required String period,
    String? categoryId,
    String? description,
  }) onCreateBudget;

  const AddBudgetDialog({
    Key? key,
    required this.categories,
    required this.onCreateBudget,
  }) : super(key: key);

  @override
  State<AddBudgetDialog> createState() => _AddBudgetDialogState();
}

class _AddBudgetDialogState extends State<AddBudgetDialog> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  String selectedPeriod = 'monthly';
  String? selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Budget'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Budget Name',
                hintText: 'e.g., Monthly Food Budget',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Budget Amount',
                hintText: 'e.g., 5000',
                border: OutlineInputBorder(),
                prefixText: '₹ ',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedPeriod,
              decoration: const InputDecoration(
                labelText: 'Period',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedPeriod = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedCategoryId,
              decoration: const InputDecoration(
                labelText: 'Category (Optional)',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('No Category'),
                ),
                ...widget.categories.map((category) => DropdownMenuItem(
                      value: category['id'],
                      child: Text(category['name']),
                    )),
              ],
              onChanged: (value) {
                setState(() {
                  selectedCategoryId = value;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Budget description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final name = nameController.text.trim();
            final amountText = amountController.text.trim();
            final description = descriptionController.text.trim();

            if (name.isEmpty || amountText.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please fill required fields')),
              );
              return;
            }

            final amount = double.tryParse(amountText);
            if (amount == null || amount <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter a valid amount')),
              );
              return;
            }

            Navigator.pop(context);

            // Show loading indicator
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(
                child: CircularProgressIndicator(),
              ),
            );

            try {
              final result = await widget.onCreateBudget(
                name: name,
                amount: amount,
                period: selectedPeriod,
                categoryId: selectedCategoryId,
                description: description.isEmpty ? null : description,
              );

              Navigator.pop(context); // Close loading dialog

              if (result['success'] == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Budget created successfully!')),
                );
                // You should call setState or a callback in parent to refresh list
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text(result['message'] ?? 'Failed to create budget'),
                  ),
                );
              }
            } catch (e) {
              Navigator.pop(context); // Close loading dialog
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $e')),
              );
            }
          },
          child: const Text('Create Budget'),
        ),
      ],
    );
  }
}
