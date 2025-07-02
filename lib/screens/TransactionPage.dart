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

  @override
  void initState() {
    super.initState();
    selectedFilters =
        widget.initialFilters?.map((key, value) => MapEntry(key, value)) ??
            {
              'Income': false,
              'Expense': false,
              'Split Bills': false, // Add Split Bills option
            };
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email') ?? '';

    // Query Firestore for categories that match the user's email
    final snapshot = await FirebaseFirestore.instance
        .collection('categories')
        .where('email', isEqualTo: email)
        .get();

    setState(() {
      categories = snapshot.docs.map((doc) => doc['name'] as String).toList();
      // Initialize dynamic category filters
      for (var category in categories) {
        selectedFilters[category] = false;
      }
    });
  }

  void _onFilterChipTapped(String filter) {
    setState(() {
      selectedFilters[filter] = !selectedFilters[filter]!; // Toggle selection
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
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
                _buildSectionHeader('Filter By'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: [
                    _buildFilterChip('Income'),
                    _buildFilterChip('Expense'),
                  ],
                ),
                const SizedBox(height: 40),
                _buildSectionHeader('Category'),
                const SizedBox(height: 8),
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
                      'Choose Category',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '${selectedFilters.values.where((isSelected) => isSelected).length} Selected',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(
                    height: 100), // Add spacing to avoid button overlap
              ],
            ),
          ),
          Positioned(
            bottom: 35,
            left: 0,
            right: 0,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(127, 61, 255, 1),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              onPressed: () {
                widget.onApplyFilters(
                    selectedFilters); // Pass selectedFilters here
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
  };
  final Map<String, IconData> _flutterIcons = {
    'Restaurant': Icons.restaurant,
    'Dining': Icons.local_dining,
    'Fastfood': Icons.fastfood,
    'Cafe': Icons.local_cafe,
    'Cake': Icons.cake,

    // Transportation
    'Car': Icons.directions_car,
    'Bus': Icons.directions_bus,
    'Bike': Icons.directions_bike,
    'Taxi': Icons.local_taxi,

    // Utilities
    'Plumbing': Icons.plumbing,

    // Entertainment
    'Movie': Icons.movie,
    'M': Icons.music_note,
    'Games': Icons.sports_esports,
    'Ticket': Icons.local_movies,

    // Shopping
    'Groceries': Icons.shopping_cart,
    'Clothing': Icons.local_mall,

    // Health and Fitness
    'Gym': Icons.fitness_center,
    'Hospital': Icons.local_hospital,
    'Pharmacy': Icons.local_pharmacy,
    'FirstAid': Icons.healing,

    // Home and Rent
    'Rent': Icons.home,
    'Apartment': Icons.apartment,
    'Kitchen': Icons.kitchen,
    'Furniture': Icons.weekend,
    // Add more icons as needed
  };

  String id = "";
  late SalesTaxController
      _salesTaxController; // Add SalesTaxController instance

  late Future<List<Transaction>> _transactionListFuture;

  DateTime? selectedDate; // Add this for calendar support

  @override
  void initState() {
    super.initState();
    _salesTaxController = SalesTaxController(); // Initialize the controller

    // Apply initial filter if provided
    if (widget.initialFilter != null) {
      selectedFilters[widget.initialFilter!] = true;
      selectedFiltersCount = 1;
    }

    _transactionListFuture = fetchTransactions(filters: selectedFilters);
  }

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

  Future<List<Transaction>> fetchTransactions(
      {Map<String, bool>? filters, String? month}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('email');

    CollectionReference transactionsRef =
        FirebaseFirestore.instance.collection('transactions');
    CollectionReference categoriesRef =
        FirebaseFirestore.instance.collection('categories');
    CollectionReference splitBillsRef =
        FirebaseFirestore.instance.collection('split_bills');

    Query query = transactionsRef.where('email', isEqualTo: email);

    // Apply filter conditions based on the selected filters
    if (filters != null && filters.containsValue(true)) {
      List<String> transactionTypes = [];
      List<String> categories = [];

      filters.forEach((key, value) {
        if (value) {
          if (key == 'Income' || key == 'Expense') {
            transactionTypes.add(key);
          } else if (key == 'Split Bills') {
            query = query.where('is_split_bill', isEqualTo: true);
          } else {
            categories.add(key);
          }
        }
      });

      if (transactionTypes.isNotEmpty) {
        query = query.where('transaction_type', whereIn: transactionTypes);
      }

      if (categories.isNotEmpty) {
        query = query.where('category_name', whereIn: categories);
      }
    }

    // Add month-based filtering
    if (month != null) {
      int monthIndex = _getMonthIndex(month);
      int currentYear = DateTime.now().year;

      DateTime startOfMonth = DateTime(currentYear, monthIndex, 1);
      DateTime endOfMonth = (monthIndex < 12)
          ? DateTime(currentYear, monthIndex + 1, 0)
          : DateTime(currentYear, 12, 31);

      query = query
          .where('timestamp', isGreaterThanOrEqualTo: startOfMonth)
          .where('timestamp', isLessThanOrEqualTo: endOfMonth);
    }

    QuerySnapshot querySnapshot = await query.get();
    List<Transaction> transactionList = [];

    for (var doc in querySnapshot.docs) {
      Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

      if (data == null) continue;

      // Get basic transaction data
      String title = data.containsKey('category_name')
          ? data['category_name']
          : 'No Category';
      String description = data['description'] ?? '';
      String id = data['transaction_id'];
      String categoryName = data['category_name'] ?? 'No Category';
      bool isSplitBill = data['is_split_bill'] ?? false;
      String? splitBillId = data['split_bill_id'];
      String transactionType = data['transaction_type'];

      // Handle amount parsing
      double amountValue = data['amount'] is String
          ? double.tryParse(data['amount']) ?? 0.0
          : data['amount'].toDouble();

      // Format amount string with currency symbol
      String amount =
          '${transactionType == "Income" ? "+" : transactionType == "Expense" ? "-" : "±"} Rs${amountValue.toStringAsFixed(2)}';

      // Get split bill details if applicable
      double? totalSplitAmount;
      int? participantCount;
      if (isSplitBill && splitBillId != null) {
        try {
          DocumentSnapshot splitBillDoc =
              await splitBillsRef.doc(splitBillId).get();
          if (splitBillDoc.exists) {
            Map<String, dynamic> splitBillData =
                splitBillDoc.data() as Map<String, dynamic>;
            totalSplitAmount =
                double.tryParse(splitBillData['total_amount'].toString()) ??
                    0.0;
            participantCount =
                (splitBillData['participants'] as List?)?.length ?? 0 + 1;
            description =
                'Split Bill: ${splitBillData['description']} (${participantCount} people)';
          }
        } catch (e) {
          print("Error fetching split bill details: $e");
        }
      }

      // Calculate sales tax
      double salesTax = 0.0;
      if (data.containsKey('sales_tax_amount')) {
        salesTax = data['sales_tax_amount'] is String
            ? double.tryParse(data['sales_tax_amount']) ?? 0.0
            : (data['sales_tax_amount'] ?? 0.0).toDouble();
      } else if (transactionType == 'Expense') {
        try {
          // Try global categories first
          QuerySnapshot categorySnapshot = await categoriesRef
              .where('name', isEqualTo: categoryName)
              .limit(1)
              .get();

          if (categorySnapshot.docs.isEmpty) {
            // Try user-specific categories
            categorySnapshot = await categoriesRef
                .where('email', isEqualTo: email)
                .where('name', isEqualTo: categoryName)
                .limit(1)
                .get();
          }

          if (categorySnapshot.docs.isNotEmpty) {
            var categoryData =
                categorySnapshot.docs.first.data() as Map<String, dynamic>;
            bool isTaxApplicable = categoryData['salesTaxApplicable'] ?? false;
            if (isTaxApplicable) {
              double taxRate =
                  (categoryData['salesTaxPercentage'] ?? 0.0).toDouble();
              salesTax = (amountValue * taxRate) / 100;
            }
          }
        } catch (e) {
          print("Error calculating fallback sales tax: $e");
        }
      }

      // Handle date and time
      DateTime date = (data['timestamp'] as Timestamp).toDate();
      String time = DateFormat('hh:mm a').format(date);

      // Get category icon and color
      String iconName = "";
      Color iconColor = Colors.grey;
      IconData icon;

      if (isSplitBill) {
        icon = Icons.group;
      } else {
        if (data.containsKey('category_name')) {
          try {
            QuerySnapshot categorySnapshot = await categoriesRef
                .where('name', isEqualTo: data['category_name'])
                .limit(1)
                .get();

            if (categorySnapshot.docs.isEmpty) {
              categorySnapshot = await categoriesRef
                  .where('email', isEqualTo: email)
                  .where('name', isEqualTo: data['category_name'])
                  .limit(1)
                  .get();
            }

            if (categorySnapshot.docs.isNotEmpty) {
              var categoryData =
                  categorySnapshot.docs.first.data() as Map<String, dynamic>;
              iconName = categoryData['iconName'] ?? '';
              String colorString = categoryData['iconColor'] ?? '#757575';

              try {
                if (colorString.startsWith('#')) {
                  iconColor =
                      Color(int.parse(colorString.replaceFirst('#', '0xff')));
                }
              } catch (colorError) {
                print("Error parsing color: $colorError");
              }
            }
          } catch (e) {
            print("Error fetching category data: $e");
          }
        }
        icon = _flutterIcons[iconName] ?? Icons.money;
      }

      // Create and add transaction object
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
    }

    return transactionList;
  }

  // Helper method to get the index of the month
  int _getMonthIndex(String month) {
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
    return months.indexOf(month) + 1; // Convert to 1-based index
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
                              hint: const Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Month',
                                      style: TextStyle(
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
                                  .map(
                                      (String item) => DropdownMenuItem<String>(
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
                                  _transactionListFuture =
                                      fetchTransactions(month: selectedMonth);
                                });
                              },
                              buttonStyleData: ButtonStyleData(
                                height: 40,
                                width: 150,
                                padding:
                                    const EdgeInsets.only(left: 14, right: 14),
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
                                icon: Icon(Icons.keyboard_arrow_down_rounded),
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
                                  thickness: WidgetStateProperty.all<double>(6),
                                  thumbVisibility:
                                      WidgetStateProperty.all<bool>(true),
                                ),
                              ),
                              menuItemStyleData: const MenuItemStyleData(
                                height: 40,
                                padding: EdgeInsets.only(left: 14, right: 14),
                              ),
                            ),
                          ),
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
                children: [
                  // Icon section with split bill indicator
                  Container(
                    height: 55,
                    width: 55,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: transaction.isSplitBill
                          ? const Color.fromRGBO(127, 61, 255, 1)
                              .withOpacity(0.1)
                          : transaction.transactionType == "Income"
                              ? const Color.fromRGBO(0, 168, 107, 1)
                                  .withOpacity(0.1)
                              : const Color.fromRGBO(253, 60, 74, 1)
                                  .withOpacity(0.1),
                    ),
                    child: Icon(
                      transaction.isSplitBill ? Icons.group : transaction.icon,
                      color: transaction.isSplitBill
                          ? const Color.fromRGBO(127, 61, 255, 1)
                          : transaction.transactionType == "Income"
                              ? const Color.fromRGBO(0, 168, 107, 1)
                              : const Color.fromRGBO(253, 60, 74, 1),
                      size: 30,
                    ),
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
                            Text(
                              transaction.time,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
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
              if (isTaxableExpense)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Sales Tax: Rs${transaction.salesTax.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
