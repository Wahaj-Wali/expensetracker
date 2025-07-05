import 'package:ExpenseTracker/Services/SplitBillController.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:ExpenseTracker/screens/AddSplitBillScreen.dart';

class SplitBillOverviewScreen extends StatefulWidget {
  const SplitBillOverviewScreen({Key? key}) : super(key: key);

  @override
  _SplitBillOverviewScreenState createState() =>
      _SplitBillOverviewScreenState();
}

class _SplitBillOverviewScreenState extends State<SplitBillOverviewScreen>
    with TickerProviderStateMixin {
  final SplitBillService _splitBillService = SplitBillService();
  List<Map<String, dynamic>> _splitBills = [];
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _selectedFilter = 'All';

  static const Color kPrimaryPurple = Color.fromRGBO(127, 61, 255, 1);
  static const Color kPrimaryPurple80 = Color.fromRGBO(127, 61, 255, 0.8);
  static const Color kGreen = Color.fromRGBO(0, 168, 107, 1);
  static const Color kOrange = Color.fromRGBO(255, 149, 0, 1);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadSplitBills();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSplitBills() async {
    setState(() => _isLoading = true);
    try {
      final splitBills = await _splitBillService.getAllSplitBills();
      setState(() {
        _splitBills = splitBills;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading split bills: $e'),
          backgroundColor: const Color.fromRGBO(253, 60, 74, 1),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredSplitBills {
    if (_selectedFilter == 'All') return _splitBills;
    return _splitBills
        .where((bill) =>
            bill['status'].toString().toLowerCase() ==
            _selectedFilter.toLowerCase())
        .toList();
  }

  double get _totalPendingAmount {
    return _splitBills.where((bill) => bill['status'] == 'pending').fold(
        0.0,
        (sum, bill) =>
            sum + (double.tryParse(bill['user_share'].toString()) ?? 0.0));
  }

  int get _pendingCount {
    return _splitBills.where((bill) => bill['status'] == 'pending').length;
  }

  int get _settledCount {
    return _splitBills.where((bill) => bill['status'] == 'settled').length;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: kPrimaryPurple,
        body: SafeArea(
          child: Column(
            children: [
              // Custom Header with gradient
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      kPrimaryPurple,
                      kPrimaryPurple80,
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
                            'Split Bills',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 40), // Balance the back button
                      ],
                    ),
                    const SizedBox(height: 25),

                    // Custom Filter Cards Row
                    Row(
                      children: [
                        // All Tab (1/4 width - half of Pending/Settled)
                        Expanded(
                          flex: 1,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedFilter = 'All';
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: 110, // Fixed height for all cards
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: _selectedFilter == 'All'
                                    ? kPrimaryPurple.withOpacity(
                                        0.8) // Deeper purple when selected
                                    : Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _selectedFilter == 'All'
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.list_alt_rounded,
                                        color: Colors.white, size: 24),
                                    SizedBox(height: 5),
                                    Text(
                                      'All',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Pending Tab (2/4 width - same as Settled)
                        Expanded(
                          flex: 2,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedFilter = 'Pending';
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: 110, // Fixed height for all cards
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: _selectedFilter == 'Pending'
                                    ? kOrange.withOpacity(
                                        0.8) // Deeper orange when selected
                                    : kOrange.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _selectedFilter == 'Pending'
                                      ? kOrange
                                      : kOrange.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.pending_actions,
                                      color: _selectedFilter == 'Pending'
                                          ? Colors.white
                                          : kOrange,
                                      size: 24),
                                  const SizedBox(height: 5),
                                  Text(
                                    'Pending',
                                    style: TextStyle(
                                      color: _selectedFilter == 'Pending'
                                          ? Colors.white
                                          : kOrange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _pendingCount.toString(),
                                    style: TextStyle(
                                      color: _selectedFilter == 'Pending'
                                          ? Colors.white
                                          : kOrange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Settled Tab (2/4 width - same as Pending)
                        Expanded(
                          flex: 2,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedFilter = 'Settled';
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: 110, // Fixed height for all cards
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: _selectedFilter == 'Settled'
                                    ? kGreen.withOpacity(
                                        0.8) // Deeper green when selected
                                    : kGreen.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _selectedFilter == 'Settled'
                                      ? Colors.white
                                      : kGreen.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle,
                                      color: _selectedFilter == 'Settled'
                                          ? Colors.white
                                          : kGreen,
                                      size: 24),
                                  const SizedBox(height: 5),
                                  Text(
                                    'Settled',
                                    style: TextStyle(
                                      color: _selectedFilter == 'Settled'
                                          ? Colors.white
                                          : kGreen,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _settledCount.toString(),
                                    style: TextStyle(
                                      color: _selectedFilter == 'Settled'
                                          ? Colors.white
                                          : kGreen,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
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
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(kPrimaryPurple),
                          ),
                        )
                      : FadeTransition(
                          opacity: _fadeAnimation,
                          child: _filteredSplitBills.isEmpty
                              ? _buildEmptyState()
                              : RefreshIndicator(
                                  onRefresh: _loadSplitBills,
                                  color: kPrimaryPurple,
                                  child: ListView.builder(
                                    padding: const EdgeInsets.all(20),
                                    itemCount: _filteredSplitBills.length,
                                    itemBuilder: (context, index) {
                                      final bill = _filteredSplitBills[index];
                                      return AnimatedContainer(
                                        duration: Duration(
                                          milliseconds: 300 + (index * 100),
                                        ),
                                        curve: Curves.easeOutBack,
                                        child: _buildSplitBillCard(bill, index),
                                      );
                                    },
                                  ),
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
            gradient: const LinearGradient(
              colors: [
                kPrimaryPurple,
                kPrimaryPurple80,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: kPrimaryPurple.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddSplitBillScreen(),
                ),
              );
              _loadSplitBills();
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            icon: const Icon(Icons.group_add, color: Colors.white, size: 24),
            label: const Text(
              'Split Bill',
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: kPrimaryPurple.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.group_outlined,
              size: 64,
              color: kPrimaryPurple,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Split Bills Yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFilter == 'All'
                ? 'Start splitting expenses with friends!'
                : 'No ${_selectedFilter.toLowerCase()} bills found',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 32),
          if (_selectedFilter == 'All')
            ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddSplitBillScreen(),
                  ),
                );
                _loadSplitBills();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryPurple,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Create Split Bill'),
            ),
        ],
      ),
    );
  }

  Widget _buildSplitBillCard(Map<String, dynamic> bill, int index) {
    bool isPending = bill['status'] == 'pending';
    double userShare = double.tryParse(bill['user_share'].toString()) ?? 0.0;
    double totalAmount =
        double.tryParse(bill['total_amount'].toString()) ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        border: Border.all(
          color: isPending ? kOrange.withOpacity(0.3) : kGreen.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            if (isPending) {
              bool? shouldSettle = await _showSettleDialog();
              if (shouldSettle == true) {
                await _splitBillService.markSplitBillAsSettled(
                  bill['split_bill_id'],
                );
                _loadSplitBills();
              }
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kPrimaryPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.group,
                        color: kPrimaryPurple,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bill['description'] ?? 'No description',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Created ${_formatDate(bill['created_at'])}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isPending
                            ? kOrange.withOpacity(0.1)
                            : kGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isPending ? kOrange : kGreen,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        bill['status'].toString().toUpperCase(),
                        style: TextStyle(
                          color: isPending ? kOrange : kGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Amount',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Rs${totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey.withOpacity(0.3),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Your Share',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Rs${userShare.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isPending ? kOrange : kGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isPending) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: kOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: kOrange.withOpacity(0.3),
                      ),
                    ),
                    child: const Text(
                      '💰 Tap to mark as settled',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: kOrange,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    try {
      DateTime date;
      if (timestamp is String) {
        date = DateTime.parse(timestamp);
      } else {
        date = timestamp.toDate();
      }
      return DateFormat('MMM d, yyyy').format(date);
    } catch (e) {
      return 'Unknown date';
    }
  }

  Future<bool?> _showSettleDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check_circle,
                color: kGreen,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Mark as Settled?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'Has everyone paid their share of this bill?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: kGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Yes, Mark Settled',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
