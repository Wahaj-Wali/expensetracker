import 'package:ExpenseTracker/Services/BudgetService2.dart';
import 'package:ExpenseTracker/Services/CategoriesService.dart';
import 'package:flutter/material.dart';
// Update with your actual path

class BudgetManagementPage extends StatefulWidget {
  const BudgetManagementPage({super.key});

  @override
  _BudgetManagementPageState createState() => _BudgetManagementPageState();
}

class _BudgetManagementPageState extends State<BudgetManagementPage> {
  List<Map<String, dynamic>> budgets = [];
  List<Map<String, dynamic>> categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBudgets();
    _loadCategories();
  }

  Future<void> _loadBudgets() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final allBudgets = await BudgetService.getAllBudgets();
      setState(() {
        budgets = allBudgets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading budgets: $e')),
      );
    }
  }

  Future<void> _loadCategories() async {
    try {
      // You'll need to get email from SharedPreferences or pass it to this method
      final allCategories =
          await DefaultCategoriesService.getAllCategories('user@email.com');
      setState(() {
        categories = allCategories;
      });
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Management'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : budgets.isEmpty
              ? _buildEmptyState()
              : _buildBudgetList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBudgetDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No budgets created yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to create your first budget',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: budgets.length,
      itemBuilder: (context, index) {
        final budget = budgets[index];
        final progress = BudgetService.getBudgetProgress(budget);
        final remaining = BudgetService.getRemainingAmount(budget);
        final isExceeded = BudgetService.isBudgetExceeded(budget);
        final isActive = BudgetService.isBudgetActive(budget);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        budget['name'] ?? 'Unknown Budget',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        if (!isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Inactive',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showEditBudgetDialog(budget);
                            } else if (value == 'delete') {
                              _deleteBudget(budget['budget_id']);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 16),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete,
                                      size: 16, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete',
                                      style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Period: ${budget['period'].toString().toUpperCase()}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (budget['category_id'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _getCategoryName(budget['category_id']),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                  ],
                ),
                if (budget['description'] != null &&
                    budget['description'].isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      budget['description'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Budget: ₹${budget['amount'].toString()}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Spent: ₹${budget['spent_amount'].toString()}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isExceeded ? Colors.red : Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress > 100 ? 1.0 : progress / 100,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isExceeded ? Colors.red : Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Remaining: ₹${remaining.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: isExceeded ? Colors.red : Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${progress.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 14,
                        color: isExceeded ? Colors.red : Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'From: ${_formatDate(budget['start_date'])}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      'To: ${_formatDate(budget['end_date'])}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddBudgetDialog() {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedPeriod = 'monthly';
    String? selectedCategoryId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
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
                        value: null, child: Text('No Category')),
                    ...categories.map((category) => DropdownMenuItem(
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
                    const SnackBar(
                        content: Text('Please fill required fields')),
                  );
                  return;
                }

                final amount = double.tryParse(amountText);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please enter a valid amount')),
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
                  final result = await BudgetService.createBudget(
                    name: name,
                    amount: amount,
                    period: selectedPeriod,
                    categoryId: selectedCategoryId,
                    description: description.isEmpty ? null : description,
                  );

                  Navigator.pop(context); // Close loading dialog

                  if (result['success'] == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Budget created successfully!')),
                    );
                    _loadBudgets(); // Refresh the list
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              result['message'] ?? 'Failed to create budget')),
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
        ),
      ),
    );
  }

  void _showEditBudgetDialog(Map<String, dynamic> budget) {
    final nameController = TextEditingController(text: budget['name']);
    final amountController =
        TextEditingController(text: budget['amount'].toString());
    final descriptionController =
        TextEditingController(text: budget['description']);
    String selectedPeriod = budget['period'];
    String? selectedCategoryId = budget['category_id'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Budget'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Budget Name',
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
                        value: null, child: Text('No Category')),
                    ...categories.map((category) => DropdownMenuItem(
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
                    const SnackBar(
                        content: Text('Please fill required fields')),
                  );
                  return;
                }

                final amount = double.tryParse(amountText);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please enter a valid amount')),
                  );
                  return;
                }

                Navigator.pop(context);

                // Since there's no update method in BudgetService,
                // you'll need to add an updateBudget method to the service
                // For now, we'll show a message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Edit functionality needs to be implemented in BudgetService')),
                );
              },
              child: const Text('Update Budget'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteBudget(String budgetId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Budget'),
        content: const Text(
            'Are you sure you want to delete this budget? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await BudgetService.deleteBudget(budgetId);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Budget deleted successfully')),
          );
          _loadBudgets(); // Refresh the list
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete budget')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting budget: $e')),
        );
      }
    }
  }

  String _getCategoryName(String? categoryId) {
    if (categoryId == null) return 'No Category';

    final category = categories.firstWhere(
      (cat) => cat['id'] == categoryId,
      orElse: () => {'name': 'Unknown Category'},
    );
    return category['name'] ?? 'Unknown Category';
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';

    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Invalid Date';
    }
  }
}
