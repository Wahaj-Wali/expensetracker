import 'package:ExpenseTracker/widgets/CircularMenuWidget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:ExpenseTracker/screens/DetailTransactionPage.dart';
import 'package:ExpenseTracker/widgets/CustomBottomNavigationBar.dart';
import 'package:ExpenseTracker/Services/SalesTaxController.dart'; // Import the SalesTaxController
import 'package:shared_preferences/shared_preferences.dart';

// Custom Filter Modal as a Widget
class CustomFilterModal extends StatefulWidget {
  final Function(Map<String, bool>) onApplyFilters;
  final Map<String, bool>? initialFilters;

  const CustomFilterModal({
    Key? key,
    required this.onApplyFilters,
    this.initialFilters,
  }) : super(key: key);

  @override
  State<CustomFilterModal> createState() => _CustomFilterModalState();
}

class _CustomFilterModalState extends State<CustomFilterModal> {
  late Map<String, bool> selectedFilters;
  List<String> categories = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // Initialize with base transaction types
    selectedFilters = {
      'Income': false,
      'Expense': false,
      'Split Bills': false,
    };

    // Apply initial filters if provided
    if (widget.initialFilters != null) {
      selectedFilters.addAll(widget.initialFilters!);
    }

    fetchCategories();
  }

  Future<void> fetchCategories() async {
    try {
      // Only fetch global categories
      final globalSnapshot = await FirebaseFirestore.instance
          .collection('global_categories')
          .orderBy('name')
          .get();

      List<String> globalCategories =
          globalSnapshot.docs.map((doc) => doc['name'] as String).toList();

      setState(() {
        categories = globalCategories;

        // Add dynamic categories to filter map if not present
        for (var category in categories) {
          if (!selectedFilters.containsKey(category)) {
            selectedFilters[category] =
                widget.initialFilters?[category] ?? false;
          }
        }
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching categories: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onFilterChipTapped(String filter) {
    setState(() {
      selectedFilters[filter] = !(selectedFilters[filter] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 50,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter Transactions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    selectedFilters.updateAll((key, value) => false);
                  });
                },
                child: Container(
                  width: 80,
                  height: 30,
                  decoration: BoxDecoration(
                      color: const Color.fromRGBO(126, 61, 255, 0.352),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Center(
                    child: Text(
                      'Reset',
                      style: TextStyle(
                        color: Color.fromRGBO(127, 61, 255, 1),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Transaction Type'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: [
                      _buildFilterChip('Income'),
                      _buildFilterChip('Expense'),
                      _buildFilterChip('Split Bills'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildSectionHeader('Categories'),
                  const SizedBox(height: 8),
                  if (isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (categories.isEmpty)
                    const Text(
                      'No categories available',
                      style: TextStyle(color: Colors.grey),
                    )
                  else
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: categories
                          .map((category) => _buildFilterChip(category))
                          .toList(),
                    ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filters Selected',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '${selectedFilters.values.where((isSelected) => isSelected).length} Selected',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Apply button
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(127, 61, 255, 1),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              onPressed: () {
                widget.onApplyFilters(Map<String, bool>.from(selectedFilters));
                Navigator.pop(context);
              },
              child: const Text(
                'Apply',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    bool isSelected = selectedFilters[label] ?? false;
    return GestureDetector(
      onTap: () => _onFilterChipTapped(label),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? const Color.fromRGBO(127, 61, 255, 1).withOpacity(0.1)
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(
                  color: const Color.fromRGBO(127, 61, 255, 1), width: 1.5)
              : Border.all(color: Colors.transparent),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? const Color.fromRGBO(127, 61, 255, 1)
                  : Colors.black54,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

// Enhanced Transaction model with sales tax
class Transaction {
  final String title;
  final String description;
  final String amount;
  final String time;
  final String transactionType;
  final IconData icon;
  final String id;
  final DateTime date;
  final double salesTax;
  final String categoryName;
  final bool isSplitBill; // New field
  final String? splitBillId; // New field
  final double? totalSplitAmount; // New field
  final int? participantCount; // New field

  Transaction({
    required this.title,
    required this.description,
    required this.amount,
    required this.time,
    required this.transactionType,
    required this.icon,
    required this.id,
    required this.date,
    required this.salesTax,
    required this.categoryName,
    this.isSplitBill = false,
    this.splitBillId,
    this.totalSplitAmount,
    this.participantCount,
  });
}

class Transactionpage extends StatefulWidget {
  final String? initialFilter;

  const Transactionpage({super.key, this.initialFilter});

  @override
  State<Transactionpage> createState() => _TransactionpageState();
}

class _TransactionpageState extends State<Transactionpage> {
  final int _activeIndex = 1;
  int selectedFiltersCount = 0;
  Map<String, bool> selectedFilters = {
    'Income': false,
    'Expense': false,
    'Split Bills': false,
  };

  final Map<String, IconData> _flutterIcons = {
    'Restaurant': Icons.restaurant,
    'Dining': Icons.local_dining,
    'Fastfood': Icons.fastfood,
    'Cafe': Icons.local_cafe,
    'Cake': Icons.cake,
    'Car': Icons.directions_car,
    'Bus': Icons.directions_bus,
    'Bike': Icons.directions_bike,
    'Taxi': Icons.local_taxi,
    'Plumbing': Icons.plumbing,
    'Movie': Icons.movie,
    'M': Icons.music_note,
    'Games': Icons.sports_esports,
    'Ticket': Icons.local_movies,
    'Groceries': Icons.shopping_cart,
    'Clothing': Icons.local_mall,
    'Gym': Icons.fitness_center,
    'Hospital': Icons.local_hospital,
    'Pharmacy': Icons.local_pharmacy,
    'FirstAid': Icons.healing,
    'Rent': Icons.home,
    'Apartment': Icons.apartment,
    'Kitchen': Icons.kitchen,
    'Furniture': Icons.weekend,
  };

  String id = "";
  late SalesTaxController _salesTaxController;
  late Future<List<Transaction>> _transactionListFuture;
  DateTime? selectedDate;

  final List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  String? selectedMonth;

  @override
  void initState() {
    super.initState();
    _salesTaxController = SalesTaxController();

    // Set selectedMonth to current month
    final now = DateTime.now();
    selectedMonth = months[now.month - 1];
    selectedDate = null;

    // Apply initial filter if provided
    if (widget.initialFilter != null) {
      selectedFilters[widget.initialFilter!] = true;
      selectedFiltersCount = 1;
    }

    _transactionListFuture =
        fetchTransactions(filters: selectedFilters, month: selectedMonth);
  }

  Future<List<Transaction>> fetchTransactions(
      {Map<String, bool>? filters, String? month, DateTime? date}) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? email = prefs.getString('email');

      if (email == null || email.isEmpty) {
        print("Error: User email not found in SharedPreferences");
        return [];
      }

      CollectionReference transactionsRef =
          FirebaseFirestore.instance.collection('transactions');
      CollectionReference splitBillsRef =
          FirebaseFirestore.instance.collection('split_bills');
      CollectionReference globalCategoriesRef =
          FirebaseFirestore.instance.collection('global_categories');
      // Remove userCategoriesRef, not needed for filtering
      // CollectionReference userCategoriesRef =
      //     FirebaseFirestore.instance.collection('user_categories');

      Query query = transactionsRef.where('email', isEqualTo: email);

      // Apply filter conditions - FIXED LOGIC
      if (filters != null && filters.containsValue(true)) {
        List<String> transactionTypes = [];
        List<String> categories = [];
        bool includeSplitBills = false;

        filters.forEach((key, value) {
          if (value) {
            if (key == 'Income' || key == 'Expense') {
              transactionTypes.add(key);
            } else if (key == 'Split Bills') {
              includeSplitBills = true;
            } else {
              categories.add(key);
            }
          }
        });

        // Build query conditions
        List<Query> queries = [];

        // If Split Bills is selected (even if it's the only filter)
        if (includeSplitBills) {
          Query splitQuery = transactionsRef
              .where('email', isEqualTo: email)
              .where('is_split_bill', isEqualTo: true);

          // Apply date/month filter to split query
          if (date != null) {
            DateTime startOfDay =
                DateTime(date.year, date.month, date.day, 0, 0, 0, 0);
            DateTime endOfDay =
                DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
            splitQuery = splitQuery
                .where('timestamp',
                    isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
                .where('timestamp',
                    isLessThanOrEqualTo: Timestamp.fromDate(endOfDay));
          } else if (month != null && month.isNotEmpty) {
            int monthIndex = _getMonthIndex(month);
            int currentYear = DateTime.now().year;
            DateTime startOfMonth = DateTime(currentYear, monthIndex, 1);
            DateTime endOfMonth =
                DateTime(currentYear, monthIndex + 1, 0, 23, 59, 59, 999);
            splitQuery = splitQuery
                .where('timestamp',
                    isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
                .where('timestamp',
                    isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth));
          }

          queries.add(splitQuery);
        }

        // If transaction types or categories are selected
        if (transactionTypes.isNotEmpty || categories.isNotEmpty) {
          Query regularQuery = transactionsRef
              .where('email', isEqualTo: email)
              .where('is_split_bill', isEqualTo: false);

          if (transactionTypes.isNotEmpty) {
            regularQuery = regularQuery.where('transaction_type',
                whereIn: transactionTypes);
          }

          // Only use global categories for filtering
          if (categories.isNotEmpty) {
            regularQuery =
                regularQuery.where('category_name', whereIn: categories);
          }

          // Apply date/month filter to regular query
          if (date != null) {
            DateTime startOfDay =
                DateTime(date.year, date.month, date.day, 0, 0, 0, 0);
            DateTime endOfDay =
                DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
            regularQuery = regularQuery
                .where('timestamp',
                    isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
                .where('timestamp',
                    isLessThanOrEqualTo: Timestamp.fromDate(endOfDay));
          } else if (month != null && month.isNotEmpty) {
            int monthIndex = _getMonthIndex(month);
            int currentYear = DateTime.now().year;
            DateTime startOfMonth = DateTime(currentYear, monthIndex, 1);
            DateTime endOfMonth =
                DateTime(currentYear, monthIndex + 1, 0, 23, 59, 59, 999);
            regularQuery = regularQuery
                .where('timestamp',
                    isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
                .where('timestamp',
                    isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth));
          }

          queries.add(regularQuery);
        }

        // If only Split Bills is selected, queries will only have splitQuery
        // If both are selected, both queries will be run

        // Execute queries and combine results
        List<QueryDocumentSnapshot> allDocs = [];
        for (Query q in queries) {
          QuerySnapshot snapshot =
              await q.orderBy('timestamp', descending: true).get();
          allDocs.addAll(snapshot.docs);
        }

        // Remove duplicates based on document ID
        Map<String, QueryDocumentSnapshot> uniqueDocs = {};
        for (var doc in allDocs) {
          uniqueDocs[doc.id] = doc;
        }

        allDocs = uniqueDocs.values.toList();

        // Sort by timestamp
        allDocs.sort((a, b) {
          Timestamp aTime = (a.data() as Map<String, dynamic>)['timestamp'] ??
              Timestamp.now();
          Timestamp bTime = (b.data() as Map<String, dynamic>)['timestamp'] ??
              Timestamp.now();
          return bTime.compareTo(aTime);
        });

        return await _processTransactionDocs(allDocs, splitBillsRef,
            globalCategoriesRef, null /* userCategoriesRef not needed */);
      } else {
        // No filters - get all transactions
        // Apply date/month filter
        if (date != null) {
          DateTime startOfDay =
              DateTime(date.year, date.month, date.day, 0, 0, 0, 0);
          DateTime endOfDay =
              DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
          query = query
              .where('timestamp',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
              .where('timestamp',
                  isLessThanOrEqualTo: Timestamp.fromDate(endOfDay));
        } else if (month != null && month.isNotEmpty) {
          int monthIndex = _getMonthIndex(month);
          int currentYear = DateTime.now().year;
          DateTime startOfMonth = DateTime(currentYear, monthIndex, 1);
          DateTime endOfMonth =
              DateTime(currentYear, monthIndex + 1, 0, 23, 59, 59, 999);
          query = query
              .where('timestamp',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
              .where('timestamp',
                  isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth));
        }

        QuerySnapshot querySnapshot =
            await query.orderBy('timestamp', descending: true).get();
        return await _processTransactionDocs(querySnapshot.docs, splitBillsRef,
            globalCategoriesRef, null /* userCategoriesRef not needed */);
      }
    } catch (e) {
      print("Error fetching transactions: $e");
      return [];
    }
  }

  Future<List<Transaction>> _processTransactionDocs(
    List<QueryDocumentSnapshot> docs,
    CollectionReference splitBillsRef,
    CollectionReference globalCategoriesRef,
    CollectionReference? userCategoriesRef, // now nullable
  ) async {
    // Collect all category names and split bill IDs
    Set<String> allCategoryNames = {};
    Set<String> allSplitBillIds = {};

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) continue;

      String? cat = data['category_name']?.toString();
      if (cat != null && cat.isNotEmpty) allCategoryNames.add(cat);

      if ((data['is_split_bill'] ?? false) && data['split_bill_id'] != null) {
        allSplitBillIds.add(data['split_bill_id'].toString());
      }
    }

    // Fetch categories in batches (only global)
    Map<String, Map<String, dynamic>> categoryMap = {};
    if (allCategoryNames.isNotEmpty) {
      List<String> categoryList = allCategoryNames.toList();

      // Fetch global categories only
      for (int i = 0; i < categoryList.length; i += 10) {
        List<String> batch = categoryList.sublist(
            i, (i + 10 < categoryList.length) ? i + 10 : categoryList.length);

        QuerySnapshot globalSnap =
            await globalCategoriesRef.where('name', whereIn: batch).get();

        for (var doc in globalSnap.docs) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data != null && data['name'] != null) {
            categoryMap[data['name'].toString()] = data;
          }
        }
      }
    }

    // Fetch split bills in batches
    Map<String, Map<String, dynamic>> splitBillMap = {};
    if (allSplitBillIds.isNotEmpty) {
      List<String> idsList = allSplitBillIds.toList();
      for (int i = 0; i < idsList.length; i += 10) {
        List<String> batch = idsList.sublist(
            i, (i + 10 < idsList.length) ? i + 10 : idsList.length);

        QuerySnapshot snap = await splitBillsRef
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (var doc in snap.docs) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data != null) {
            splitBillMap[doc.id] = data;
          }
        }
      }
    }

    // Process transactions
    List<Transaction> transactionList = [];

    for (var doc in docs) {
      try {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;

        // Validate required fields
        if (!data.containsKey('transaction_id') ||
            !data.containsKey('transaction_type') ||
            !data.containsKey('amount')) {
          continue;
        }

        // Skip transactions with no category
        String categoryName = data['category_name']?.toString() ?? '';
        if (categoryName.isEmpty) continue;

        String title = categoryName;
        String description = data['description']?.toString() ?? '';
        String id = data['transaction_id']?.toString() ?? doc.id;
        bool isSplitBill = data['is_split_bill'] ?? false;
        String? splitBillId = data['split_bill_id']?.toString();
        String transactionType =
            data['transaction_type']?.toString() ?? 'Expense';

        // Handle amount parsing
        double amountValue = 0.0;
        try {
          if (data['amount'] is String) {
            amountValue = double.tryParse(data['amount']) ?? 0.0;
          } else if (data['amount'] is num) {
            amountValue = data['amount'].toDouble();
          }
        } catch (e) {
          print("Error parsing amount for transaction $id: $e");
          continue;
        }

        // Format amount string
        String amount =
            '${transactionType == "Income" ? "+" : transactionType == "Expense" ? "-" : "±"} Rs${amountValue.toStringAsFixed(2)}';

        // Handle split bill details
        double? totalSplitAmount;
        int? participantCount;
        if (isSplitBill && splitBillId != null && splitBillId.isNotEmpty) {
          final splitBillData = splitBillMap[splitBillId];
          if (splitBillData != null) {
            totalSplitAmount = double.tryParse(
                    splitBillData['total_amount']?.toString() ?? '0') ??
                0.0;
            List<dynamic> participants = splitBillData['participants'] ?? [];
            participantCount = participants.length + 1;
            String splitDescription =
                splitBillData['description']?.toString() ?? 'Split Bill';
            description =
                'Split Bill: $splitDescription ($participantCount people)';
          }
        }

        // Handle sales tax and icon
        double salesTax = 0.0;
        String iconName = "";

        try {
          if (data.containsKey('sales_tax_amount')) {
            if (data['sales_tax_amount'] is String) {
              salesTax = double.tryParse(data['sales_tax_amount']) ?? 0.0;
            } else if (data['sales_tax_amount'] is num) {
              salesTax = data['sales_tax_amount'].toDouble();
            }
          } else if (transactionType == 'Expense' && categoryName.isNotEmpty) {
            final categoryData = categoryMap[categoryName];
            if (categoryData != null) {
              bool isTaxApplicable =
                  categoryData['salesTaxApplicable'] ?? false;
              if (isTaxApplicable) {
                double taxRate = double.tryParse(
                        categoryData['salesTaxPercentage']?.toString() ??
                            '0') ??
                    0.0;
                salesTax = (amountValue * taxRate) / 100;
              }
              iconName = categoryData['iconName']?.toString() ?? '';
            }
          }
        } catch (e) {
          print("Error calculating sales tax for transaction $id: $e");
        }

        // Get icon from category if not set
        if (iconName.isEmpty && categoryName.isNotEmpty) {
          final categoryData = categoryMap[categoryName];
          if (categoryData != null) {
            iconName = categoryData['iconName']?.toString() ?? '';
          }
        }

        // Handle date and time
        DateTime date = DateTime.now();
        String time = '';
        try {
          if (data['timestamp'] is Timestamp) {
            date = (data['timestamp'] as Timestamp).toDate();
            time = DateFormat('hh:mm a').format(date);
          } else if (data['timestamp'] is String) {
            date = DateTime.tryParse(data['timestamp']) ?? DateTime.now();
            time = DateFormat('hh:mm a').format(date);
          } else {
            time = DateFormat('hh:mm a').format(DateTime.now());
          }
        } catch (e) {
          print("Error parsing timestamp for transaction $id: $e");
          time = DateFormat('hh:mm a').format(DateTime.now());
        }

        IconData icon = _flutterIcons[iconName] ?? Icons.money;

        transactionList.add(Transaction(
          title: title,
          description: description,
          amount: amount,
          time: time,
          transactionType: transactionType,
          icon: icon,
          id: id,
          date: date,
          salesTax: salesTax,
          categoryName: categoryName,
          isSplitBill: isSplitBill,
          splitBillId: splitBillId,
          totalSplitAmount: totalSplitAmount,
          participantCount: participantCount,
        ));
      } catch (e) {
        print("Error processing transaction document ${doc.id}: $e");
        continue;
      }
    }

    print("Successfully processed ${transactionList.length} transactions");
    return transactionList;
  }

  int _getMonthIndex(String month) {
    try {
      const months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ];
      int index = months.indexOf(month);
      return index >= 0 ? index + 1 : 1;
    } catch (e) {
      print("Error getting month index for '$month': $e");
      return 1;
    }
  }
// (Removed duplicate initState)

// Method to handle filter application with error handling
  void _applyFilters(Map<String, bool> filters) {
    try {
      setState(() {
        selectedFilters = Map.from(filters);
        selectedFiltersCount =
            filters.values.where((isSelected) => isSelected).length;
        _transactionListFuture = fetchTransactions(
          filters: selectedFilters,
          month: selectedMonth,
        );
      });
    } catch (e) {
      print("Error applying filters: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error applying filters: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

// Helper method to format transaction date
  String _formatTransactionDate(DateTime date) {
    DateTime now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      return 'Yesterday';
    } else {
      return DateFormat('MMMM d, y').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: const Text(
            "Transactions",
            style: TextStyle(
              color: Colors.black,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: Stack(
          children: [
            Container(
              height: 200,
              color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.2),
            ),
            SafeArea(
              child: Column(
                children: [
                  // Month selector and filter section
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 6.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Month dropdown and calendar button together
                        Row(
                          children: [
                            // Month dropdown
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    spreadRadius: 0,
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton2<String>(
                                  isExpanded: true,
                                  hint: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          selectedMonth ?? 'Month',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  items: months
                                      .map((String item) =>
                                          DropdownMenuItem<String>(
                                            value: item,
                                            child: Text(
                                              item,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.black,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ))
                                      .toList(),
                                  value: selectedMonth,
                                  onChanged: (String? value) {
                                    setState(() {
                                      selectedMonth = value;
                                      selectedDate =
                                          null; // Clear date filter if month is changed
                                      _transactionListFuture =
                                          fetchTransactions(
                                              filters: selectedFilters,
                                              month: selectedMonth,
                                              date: null);
                                    });
                                  },
                                  buttonStyleData: ButtonStyleData(
                                    height: 40,
                                    width: 150,
                                    padding: const EdgeInsets.only(
                                        left: 14, right: 14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(
                                        color: const Color(0xFFE8E8E8),
                                        width: 1,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    elevation: 0,
                                  ),
                                  iconStyleData: const IconStyleData(
                                    icon:
                                        Icon(Icons.keyboard_arrow_down_rounded),
                                    iconSize: 22,
                                    iconEnabledColor:
                                        Color.fromRGBO(127, 61, 255, 1),
                                  ),
                                  dropdownStyleData: DropdownStyleData(
                                    elevation: 2,
                                    maxHeight: 200,
                                    width: 150,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      color: Colors.white,
                                    ),
                                    offset: const Offset(0, 0),
                                    scrollbarTheme: ScrollbarThemeData(
                                      radius: const Radius.circular(40),
                                      thickness:
                                          WidgetStateProperty.all<double>(6),
                                      thumbVisibility:
                                          WidgetStateProperty.all<bool>(true),
                                    ),
                                  ),
                                  menuItemStyleData: const MenuItemStyleData(
                                    height: 40,
                                    padding:
                                        EdgeInsets.only(left: 14, right: 14),
                                  ),
                                ),
                              ),
                            ),
                            // Calendar icon button (styled to match filter button)
                            Stack(
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    DateTime now = DateTime.now();
                                    final DateTime? picked =
                                        await showDatePicker(
                                      context: context,
                                      initialDate: selectedDate ?? now,
                                      firstDate: DateTime(now.year - 5),
                                      lastDate: DateTime(now.year + 5),
                                      builder: (context, child) {
                                        // Custom theme for better calendar UI
                                        return Theme(
                                          data: Theme.of(context).copyWith(
                                            colorScheme:
                                                const ColorScheme.light(
                                              primary: Color.fromRGBO(
                                                  127, 61, 255, 1), // header bg
                                              onPrimary:
                                                  Colors.white, // header text
                                              onSurface:
                                                  Colors.black, // body text
                                            ),
                                            textButtonTheme:
                                                TextButtonThemeData(
                                              style: TextButton.styleFrom(
                                                foregroundColor: Color.fromRGBO(
                                                    127,
                                                    61,
                                                    255,
                                                    1), // button text
                                              ),
                                            ),
                                            dialogBackgroundColor: Colors.white,
                                          ),
                                          child: child!,
                                        );
                                      },
                                    );
                                    if (picked != null) {
                                      setState(() {
                                        selectedDate = picked;
                                        selectedMonth =
                                            null; // Clear month filter if date is picked
                                        _transactionListFuture =
                                            fetchTransactions(
                                          filters: selectedFilters,
                                          date: selectedDate,
                                        );
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color(0xFFE8E8E8),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          spreadRadius: 0,
                                          blurRadius: 10,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                        Icons.calendar_today_rounded,
                                        color: Colors.black,
                                        size: 20),
                                  ),
                                ),
                                if (selectedDate != null)
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: Container(
                                      height: 10,
                                      width: 10,
                                      decoration: const BoxDecoration(
                                        color: Color.fromRGBO(127, 61, 255, 1),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            // Reset button for calendar (shows only if a date is selected)
                            if (selectedDate != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedDate = null;
                                      selectedMonth =
                                          months[DateTime.now().month - 1];
                                      _transactionListFuture =
                                          fetchTransactions(
                                        filters: selectedFilters,
                                        month: selectedMonth,
                                        date: null,
                                      );
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color(0xFFE8E8E8),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          spreadRadius: 0,
                                          blurRadius: 10,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.close_rounded,
                                        color: Color.fromRGBO(127, 61, 255, 1),
                                        size: 18),
                                  ),
                                ),
                              ),
                          ],
                        ),

                        // Filter button with badge
                        Stack(
                          children: [
                            GestureDetector(
                              onTap: () {
                                showMaterialModalBottomSheet(
                                  context: context,
                                  builder: (context) => CustomFilterModal(
                                    initialFilters: selectedFilters,
                                    onApplyFilters: (filters) {
                                      setState(() {
                                        selectedFilters = filters;
                                        _transactionListFuture =
                                            fetchTransactions(filters: filters);
                                        selectedFiltersCount = filters.values
                                            .where((isSelected) => isSelected)
                                            .length;
                                      });
                                    },
                                  ),
                                  backgroundColor: Colors.transparent,
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFFE8E8E8),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      spreadRadius: 0,
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.filter_list_rounded,
                                    size: 20),
                              ),
                            ),
                            if (selectedFiltersCount > 0)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  height: 20,
                                  width: 20,
                                  decoration: BoxDecoration(
                                    color:
                                        const Color.fromRGBO(127, 61, 255, 1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$selectedFiltersCount',
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 12),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Transactions list
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: FutureBuilder<List<Transaction>>(
                        future: _transactionListFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                'Error fetching transactions',
                                style: TextStyle(color: Colors.red[300]),
                              ),
                            );
                          } else if (!snapshot.hasData ||
                              snapshot.data!.isEmpty) {
                            return const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.receipt_long,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'No transactions found',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          final transactions = snapshot.data!;
                          transactions.sort((a, b) {
                            int dateComparison = b.date.compareTo(a.date);
                            return dateComparison == 0
                                ? b.time.compareTo(a.time)
                                : dateComparison;
                          });

                          return ListView.builder(
                            padding: const EdgeInsets.all(10),
                            itemCount: transactions.length,
                            itemBuilder: (context, index) {
                              final transaction = transactions[index];
                              final previousTransaction =
                                  index > 0 ? transactions[index - 1] : null;

                              String currentDate =
                                  _formatTransactionDate(transaction.date);
                              String? previousDate;
                              if (previousTransaction != null) {
                                previousDate = _formatTransactionDate(
                                    previousTransaction.date);
                              }

                              bool showDateHeader = currentDate != previousDate;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (showDateHeader)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 10,
                                        top: 15,
                                        bottom: 10,
                                      ),
                                      child: Text(
                                        currentDate,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  _buildTransactionItem(context, transaction),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: CustomBottomNavigationBar(
          activeIndex: _activeIndex,
        ),
        floatingActionButton: const CircularMenuWidget(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, Transaction transaction) {
    bool isTaxableExpense =
        transaction.transactionType == "Expense" && transaction.salesTax > 0;

    // Restore color logic for icon background and icon color
    Color iconBgColor;
    Color iconColor;
    if (transaction.isSplitBill) {
      iconBgColor = const Color.fromRGBO(127, 61, 255, 1).withOpacity(0.1);
      iconColor = const Color.fromRGBO(127, 61, 255, 1);
    } else if (transaction.transactionType == "Income") {
      iconBgColor = const Color.fromRGBO(0, 168, 107, 1).withOpacity(0.1);
      iconColor = const Color.fromRGBO(0, 168, 107, 1);
    } else {
      iconBgColor = const Color.fromRGBO(253, 60, 74, 1).withOpacity(0.1);
      iconColor = const Color.fromRGBO(253, 60, 74, 1);
    }

    return GestureDetector(
        onTap: () {
          if (transaction.id.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailTransactionPage(
                  transactionId: transaction.id,
                  isSplitBill: transaction.isSplitBill,
                  splitBillId: transaction.splitBillId,
                ),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 3,
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon section with badge below
                    Column(
                      children: [
                        Container(
                          height: 55,
                          width: 55,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: iconBgColor,
                          ),
                          child: Icon(
                            transaction.icon,
                            color: iconColor,
                            size: 30,
                          ),
                        ),
                        if (isTaxableExpense)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color.fromRGBO(253, 60, 74, 1)
                                    .withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color.fromRGBO(253, 60, 74, 1),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'Tax: Rs${transaction.salesTax.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Color.fromRGBO(253, 60, 74, 1),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                transaction.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                transaction.amount,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: transaction.transactionType == "Income"
                                      ? const Color.fromRGBO(0, 168, 107, 1)
                                      : const Color.fromRGBO(253, 60, 74, 1),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  transaction.description,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Move date to the right, show in place
                              Text(
                                DateFormat('MMM d, yyyy')
                                    .format(transaction.date),
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          // ...existing code...
                          if (transaction.isSplitBill &&
                              transaction.totalSplitAmount != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: Text(
                                'Total bill: Rs${transaction.totalSplitAmount!.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Color.fromRGBO(127, 61, 255, 1),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                // ...existing code...
              ],
            ),
          ),
        ));
  }
}
