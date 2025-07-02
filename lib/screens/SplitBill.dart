import 'package:ExpenseTracker/Services/SplitBillController.dart';
import 'package:flutter/material.dart';

import 'package:ExpenseTracker/screens/AddSplitBillScreen.dart';

class SplitBillOverviewScreen extends StatefulWidget {
  const SplitBillOverviewScreen({Key? key}) : super(key: key);

  @override
  _SplitBillOverviewScreenState createState() =>
      _SplitBillOverviewScreenState();
}

class _SplitBillOverviewScreenState extends State<SplitBillOverviewScreen> {
  final SplitBillService _splitBillService = SplitBillService();
  List<Map<String, dynamic>> _splitBills = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSplitBills();
  }

  Future<void> _loadSplitBills() async {
    setState(() => _isLoading = true);
    try {
      final splitBills = await _splitBillService.getAllSplitBills();
      setState(() {
        _splitBills = splitBills;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading split bills: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Split Bills'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSplitBills,
              child: _splitBills.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.group_outlined,
                              size: 48, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No split bills yet',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _splitBills.length,
                      itemBuilder: (context, index) {
                        final bill = _splitBills[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: ListTile(
                            title:
                                Text(bill['description'] ?? 'No description'),
                            subtitle: Text(
                                'Total: \$${bill['total_amount']}\nYour share: \$${bill['user_share']}'),
                            trailing: Chip(
                              label: Text(bill['status']),
                              backgroundColor: bill['status'] == 'settled'
                                  ? Colors.green[100]
                                  : Colors.orange[100],
                            ),
                            onTap: () async {
                              if (bill['status'] == 'pending') {
                                bool? shouldSettle = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Mark as Settled?'),
                                    content: const Text(
                                        'Has everyone paid their share?'),
                                    actions: [
                                      TextButton(
                                        child: const Text('Cancel'),
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                      ),
                                      TextButton(
                                        child: const Text('Yes, Mark Settled'),
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                      ),
                                    ],
                                  ),
                                );

                                if (shouldSettle == true) {
                                  await _splitBillService
                                      .markSplitBillAsSettled(
                                          bill['split_bill_id']);
                                  _loadSplitBills();
                                }
                              }
                            },
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddSplitBillScreen()),
          );
          _loadSplitBills(); // Refresh the list after returning
        },
        icon: const Icon(Icons.group_add),
        label: const Text('Split Bill'),
      ),
    );
  }
}
