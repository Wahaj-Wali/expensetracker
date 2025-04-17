import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DetailTransactionPage extends StatefulWidget {
  final String transactionId;

  const DetailTransactionPage({Key? key, required this.transactionId})
      : super(key: key);

  @override
  _DetailTransactionPageState createState() => _DetailTransactionPageState();
}

class _DetailTransactionPageState extends State<DetailTransactionPage> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  Map<String, dynamic>? transactionData;

  @override
  void initState() {
    super.initState();
    fetchTransactionDetails(widget.transactionId);
  }

  Future<void> fetchTransactionDetails(String id) async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email');

      if (email == null) {
        throw Exception('User not logged in');
      }

      final querySnapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('email', isEqualTo: email)
          .where('transaction_id', isEqualTo: id)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('Transaction not found');
      }

      setState(() {
        transactionData = querySnapshot.docs.first.data();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  Color _getTransactionColor(String transactionType) {
    switch (transactionType) {
      case 'Expense':
        return const Color.fromRGBO(253, 60, 74, 1);
      case 'Income':
        return const Color.fromRGBO(0, 168, 107, 1);
      case 'Transfer':
        return const Color.fromRGBO(0, 119, 255, 1);
      default:
        return Colors.grey;
    }
  }

  IconData _getTransactionIcon(String transactionType) {
    switch (transactionType) {
      case 'Expense':
        return Icons.arrow_upward;
      case 'Income':
        return Icons.arrow_downward;
      case 'Transfer':
        return Icons.swap_horiz;
      default:
        return Icons.help_outline;
    }
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    final dateFormatter = DateFormat('MMMM d, yyyy');
    final timeFormatter = DateFormat('h:mm a');
    return '${dateFormatter.format(date)} at ${timeFormatter.format(date)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_hasError) {
      return _buildErrorState();
    }

    final transactionType = transactionData!['transaction_type'] ?? 'Unknown';
    final color = _getTransactionColor(transactionType);
    final timestamp = transactionData!['timestamp'] as Timestamp?;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 250,
          backgroundColor: color,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.arrow_back),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            _buildDeleteButton(),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                color: color,
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getTransactionIcon(transactionType),
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      transactionData!['converted_amount'] ?? "N/A",
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      transactionData!['category_name'] ?? "N/A",
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (timestamp != null)
                      Text(
                        _formatDate(timestamp),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildListDelegate([
            _buildDetailsCard(),
            _buildNotesSection(),
            if (transactionData!['transaction_type'] == 'Transfer')
              _buildTransferDetailsCard(),
          ]),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load transaction',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(_errorMessage),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => fetchTransactionDetails(widget.transactionId),
            child: const Text('Try Again'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteButton() {
    return IconButton(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.delete),
      ),
      onPressed: () {
        // Show confirmation dialog before deleting
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Transaction'),
            content: const Text(
                'Are you sure you want to delete this transaction? This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () {
                  // Implement delete functionality
                  Navigator.pop(context); // Close dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Delete functionality to be implemented')),
                  );
                },
                child:
                    const Text('DELETE', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailsCard() {
    // Get the appropriate account field based on transaction type
    String accountFieldName = 'account';
    if (transactionData!['transaction_type'] == 'Transfer') {
      accountFieldName = 'from_account';
    } else if (transactionData!.containsKey('account_name')) {
      accountFieldName = 'account_name';
    }

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Transaction Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TransactionDetailItem(
              icon: Icons.category,
              label: "Category",
              value: transactionData!['category_name'] ?? "N/A",
            ),
            TransactionDetailItem(
              icon: Icons.swap_horiz,
              label: "Transaction Type",
              value: transactionData!['transaction_type'] ?? "N/A",
            ),
            TransactionDetailItem(
              icon: Icons.account_balance_wallet,
              label: "Account",
              value: transactionData![accountFieldName] ?? "N/A",
            ),
            TransactionDetailItem(
              icon: Icons.description,
              label: "Description",
              value: transactionData!['description'] ?? "No description",
              multiline: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransferDetailsCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Transfer Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TransactionDetailItem(
              icon: Icons.arrow_upward,
              label: "From Account",
              value: transactionData!['from_account'] ?? "N/A",
            ),
            TransactionDetailItem(
              icon: Icons.arrow_downward,
              label: "To Account",
              value: transactionData!['to_account'] ?? "N/A",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    // Display notes if available
    final notes = transactionData!['notes'] as String?;

    if (notes == null || notes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(notes),
          ],
        ),
      ),
    );
  }
}

class TransactionDetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool multiline;

  const TransactionDetailItem({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
    this.multiline = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment:
            multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Colors.grey.shade700),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
