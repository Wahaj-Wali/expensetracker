import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/physics.dart';
import 'package:ExpenseTracker/Services/AccountController.dart';
import 'package:ExpenseTracker/screens/AccountPage.dart';
import 'package:ExpenseTracker/widgets/custom_loader.dart';

class AddAccountPage extends StatefulWidget {
  const AddAccountPage({super.key});

  @override
  _AddAccountPageState createState() => _AddAccountPageState();
}

class _AddAccountPageState extends State<AddAccountPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _balanceController = TextEditingController();
  final TextEditingController _accountNameController = TextEditingController();
  final AccountController _accountController = AccountController();

  // Define account types
  final List<String> _accountTypes = [
    'Wallet',
    'Digital Account',
    'Bank Account'
  ];
  String? _selectedAccountType;

// Define UPI accounts
  final List<Map<String, String>> _upiAccounts = [
    {'name': 'EasyPaisa', 'image': 'assets/images/easypaisa.png'},
    {'name': 'JazzCash', 'image': 'assets/images/jazzcash.png'},
    {'name': 'NayaPay', 'image': 'assets/images/nayapay.png'},
    {'name': 'SadaPay', 'image': 'assets/images/sadapay.png'},
    {'name': 'Zindagi', 'image': 'assets/images/zindagi.png'},
    {'name': 'Upaisa', 'image': 'assets/images/upaisa.png'},
  ];

// Define Bank accounts
  final List<Map<String, String>> _bankAccounts = [
    {'name': 'National Bank of Pakistan', 'image': 'assets/listBank/NBP.png'},
    {'name': 'Habib Bank Limited', 'image': 'assets/listBank/HBL.png'},
    {'name': 'United Bank Limited', 'image': 'assets/listBank/UBL.png'},
    {'name': 'MCB Bank Limited', 'image': 'assets/listBank/MCB.png'},
    {'name': 'Allied Bank Limited', 'image': 'assets/listBank/ABL.png'},
    {'name': 'Bank Alfalah', 'image': 'assets/listBank/BankAlfalah.png'},
    {'name': 'Askari Bank', 'image': 'assets/listBank/AskariBank.png'},
    {'name': 'Meezan Bank', 'image': 'assets/listBank/MeezanBank.png'},
    {'name': 'Faysal Bank', 'image': 'assets/listBank/FaysalBank.png'},
    {
      'name': 'Standard Chartered Pakistan',
      'image': 'assets/listBank/StandardCharteredPakistan.png'
    },
    {'name': 'The Bank of Punjab', 'image': 'assets/listBank/BankOfPunjab.png'},
    {'name': 'JS Bank', 'image': 'assets/listBank/JSBank.png'},
    {'name': 'BankIslami Pakistan', 'image': 'assets/listBank/BankIslami.png'},
    {'name': 'Summit Bank', 'image': 'assets/listBank/SummitBank.png'},
    {'name': 'Sindh Bank', 'image': 'assets/listBank/SindhBank.png'},
    {
      'name': 'Dubai Islamic Bank Pakistan',
      'image': 'assets/listBank/DubaiIslamicBankPakistan.png'
    },
    {
      'name': 'Habib Metropolitan Bank',
      'image': 'assets/listBank/HabibMetropolitanBank.png'
    },
    {'name': 'Silk Bank', 'image': 'assets/listBank/SilkBank.png'},
    {'name': 'First Women Bank', 'image': 'assets/listBank/FirstWomenBank.png'},
    {
      'name': 'Zarai Taraqiati Bank',
      'image': 'assets/listBank/ZaraiTaraqiatiBank.png'
    },
    {'name': 'Bank Al Habib', 'image': 'assets/listBank/BankAlHabib.png'},
  ];

  String? _selectedUPIAccount;
  String? _selectedBankAccount;

  // Example of form submission when the continue button is clicked
  void _onContinuePressed(BuildContext context) async {
    // Perform validation
    if (_balanceController.text.isEmpty ||
        double.tryParse(_balanceController.text) == null) {
      // Show error if balance is not valid
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid balance')),
      );
      return; // Stop execution if validation fails
    }

    if (_selectedAccountType == null) {
      // Show error if account type is not selected
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an account type')),
      );
      return; // Stop execution if validation fails
    }

    // If validation passes, execute the task
    await CustomLoader.showLoaderForTask(
      context: context,
      task: () async {
        String selectedAccountType = _selectedAccountType ?? 'Wallet';
        String? accountName = _accountNameController.text.isNotEmpty
            ? _accountNameController.text
            : null; // Account name is optional
        double balance = double.tryParse(_balanceController.text) ?? 0.0;

        try {
          // Insert the account into Firebase
          await _accountController.addNewAccount(
            accountType: selectedAccountType,
            accountName: accountName,
            balance: balance,
            selectedUPIAccount: _selectedUPIAccount,
            selectedBankAccount: _selectedBankAccount,
          );

          // Navigate to AccountPage after successful insertion
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AccountPage()),
          );
        } catch (e) {
          // Handle error
          print("Error adding account: $e");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Error adding account. Please try again.')),
          );
        }
      },
    );
  }

// This controller is used for search functionality
  final TextEditingController _searchController = TextEditingController();

  double topContainerHeight = 450;
  double bottomContainerHeight = 350;
  double maxHeight = 650;
  double minHeight = 200;

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150), // Faster response time
    );
    _animation =
        Tween<double>(begin: bottomContainerHeight, end: bottomContainerHeight)
            .animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void onVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      // Increase sensitivity to make scrolling faster
      bottomContainerHeight -=
          details.delta.dy * 1.7; // Increase scroll sensitivity
      if (bottomContainerHeight > maxHeight) bottomContainerHeight = maxHeight;
      if (bottomContainerHeight < minHeight) bottomContainerHeight = minHeight;
    });
  }

  void onVerticalDragEnd(DragEndDetails details) {
    // Adjust spring physics for a faster snap back and reaction
    final velocity = details.primaryVelocity ?? 0;
    const spring = SpringDescription(
      mass: 1,
      stiffness: 2000, // Increased stiffness for faster spring action
      damping: 7, // Further lowered damping for quicker response
    );

    final simulation = SpringSimulation(
        spring, bottomContainerHeight, bottomContainerHeight, velocity / 1000);

    _controller.animateWith(simulation);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color.fromRGBO(127, 61, 255, 1),
        centerTitle: true,
        title: const Text('Add new account',
            style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [
          GestureDetector(
            child: Container(
              color: const Color.fromRGBO(127, 61, 255, 1),
              height: MediaQuery.of(context).size.height,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    height: 50,
                  ),
                  const Text(
                    'How Much?',
                    style: TextStyle(
                      color: Color.fromRGBO(255, 255, 255, 0.64),
                      fontSize: 18,
                    ),
                  ),
                  TextField(
                    controller: _balanceController,
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
                        child: const Icon(
                          Icons.currency_exchange,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      hintText: '0',
                      hintStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 50,
                      ),
                      labelStyle: const TextStyle(color: Colors.white),
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ],
              ),
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
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: Column(
                            children: [
                              Container(
                                width: 40,
                                height: 5,
                                margin: const EdgeInsets.only(top: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _accountNameController,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  labelText: "Name",
                                  labelStyle: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black54,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 20,
                                  ),
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
                                      color: Color.fromRGBO(127, 61, 255, 1),
                                      width: 1,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF1F1FA),
                                ),
                              ),
                              const SizedBox(height: 12),
// Account Type Dropdown
                              SizedBox(
                                // Wrap dropdown in SizedBox to ensure consistent height
                                height: 60, // Match TextField height
                                child: DropdownButtonFormField2<String>(
                                  value: _selectedAccountType,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 20,
                                    ),
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
                                    filled: true,
                                    fillColor: const Color(0xFFF1F1FA),
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
                                      color: Colors.black54,
                                    ),
                                    iconSize: 24,
                                  ),
                                  dropdownStyleData: DropdownStyleData(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      color: Colors.white,
                                    ),
                                    offset: const Offset(0, -10),
                                    scrollbarTheme: ScrollbarThemeData(
                                      radius: const Radius.circular(40),
                                      thickness: WidgetStateProperty.all(6),
                                      thumbVisibility:
                                          WidgetStateProperty.all(true),
                                    ),
                                  ),
                                  menuItemStyleData: const MenuItemStyleData(
                                    height: 50,
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 16),
                                  ),
                                  items: _accountTypes.map((accountType) {
                                    return DropdownMenuItem<String>(
                                      value: accountType,
                                      child: Text(
                                        accountType,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _selectedAccountType = newValue;
                                      _selectedUPIAccount = null;
                                      _selectedBankAccount = null;
                                    });
                                  },
                                  hint: const Text(
                                    'Select Account Type',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

// Conditionally show Digital Account or Bank Account dropdown
                              if (_selectedAccountType ==
                                  'Digital Account') ...[
                                DropdownButtonFormField2<String>(
                                  value: _selectedUPIAccount,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
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
                                      color: Colors.black54,
                                    ),
                                    iconSize: 24,
                                  ),
                                  dropdownStyleData: DropdownStyleData(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      color: Colors.white,
                                    ),
                                    offset: const Offset(0, -10),
                                    scrollbarTheme: ScrollbarThemeData(
                                      radius: const Radius.circular(40),
                                      thickness: WidgetStateProperty.all(6),
                                      thumbVisibility:
                                          WidgetStateProperty.all(true),
                                    ),
                                  ),
                                  menuItemStyleData: const MenuItemStyleData(
                                    height: 50,
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 16),
                                  ),
                                  items: _upiAccounts.map((upiAccount) {
                                    return DropdownMenuItem<String>(
                                      value: upiAccount['name'],
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: const Color.fromRGBO(
                                                  127, 61, 255, 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Image.asset(
                                                upiAccount['image']!,
                                                width: 24,
                                                height: 24,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            upiAccount['name']!,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _selectedUPIAccount = newValue;
                                    });
                                  },
                                  hint: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: const Color.fromRGBO(
                                              127, 61, 255, 0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.account_balance_wallet,
                                          size: 20,
                                          color:
                                              Color.fromRGBO(127, 61, 255, 1),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Select Digital Account',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                  dropdownSearchData: DropdownSearchData(
                                    searchController: _searchController,
                                    searchInnerWidget: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: TextFormField(
                                        controller: _searchController,
                                        decoration: InputDecoration(
                                          isDense: true,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 10, vertical: 8),
                                          hintText: 'Search Account...',
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            borderSide: const BorderSide(
                                                color: Color(0xFFF1F1FA)),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            borderSide: const BorderSide(
                                                color: Color.fromRGBO(
                                                    127, 61, 255, 1)),
                                          ),
                                        ),
                                      ),
                                    ),
                                    searchInnerWidgetHeight: 60,
                                    searchMatchFn: (item, searchValue) {
                                      return (item.value as String)
                                          .toLowerCase()
                                          .contains(searchValue.toLowerCase());
                                    },
                                  ),
                                ),
                              ] else if (_selectedAccountType ==
                                  'Bank Account') ...[
                                DropdownButtonFormField2<String>(
                                  value: _selectedBankAccount,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
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
                                      color: Colors.black54,
                                    ),
                                    iconSize: 24,
                                  ),
                                  dropdownStyleData: DropdownStyleData(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      color: Colors.white,
                                    ),
                                    offset: const Offset(0, -10),
                                    scrollbarTheme: ScrollbarThemeData(
                                      radius: const Radius.circular(40),
                                      thickness: WidgetStateProperty.all(6),
                                      thumbVisibility:
                                          WidgetStateProperty.all(true),
                                    ),
                                  ),
                                  menuItemStyleData: const MenuItemStyleData(
                                    height: 50,
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 16),
                                  ),
                                  items: _bankAccounts.map((bankAccount) {
                                    return DropdownMenuItem<String>(
                                      value: bankAccount['name'],
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: const Color.fromRGBO(
                                                  127, 61, 255, 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Image.asset(
                                                bankAccount['image']!,
                                                width: 24,
                                                height: 24,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            bankAccount['name']!,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _selectedBankAccount = newValue;
                                    });
                                  },
                                  hint: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: const Color.fromRGBO(
                                              127, 61, 255, 0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.account_balance,
                                          size: 20,
                                          color:
                                              Color.fromRGBO(127, 61, 255, 1),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Select Bank Account',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                  dropdownSearchData: DropdownSearchData(
                                    searchController: _searchController,
                                    searchInnerWidget: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: TextFormField(
                                        controller: _searchController,
                                        decoration: InputDecoration(
                                          isDense: true,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 10, vertical: 8),
                                          hintText: 'Search Bank...',
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            borderSide: const BorderSide(
                                                color: Color(0xFFF1F1FA)),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            borderSide: const BorderSide(
                                                color: Color.fromRGBO(
                                                    127, 61, 255, 1)),
                                          ),
                                        ),
                                      ),
                                    ),
                                    searchInnerWidgetHeight: 60,
                                    searchMatchFn: (item, searchValue) {
                                      return (item.value as String)
                                          .toLowerCase()
                                          .contains(searchValue.toLowerCase());
                                    },
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: () {
                                    _onContinuePressed(
                                        context); // Pass the context here
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color.fromRGBO(127, 61, 255, 1),
                                    minimumSize:
                                        const Size(double.infinity, 48),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text('Continue',
                                      style: TextStyle(
                                          fontSize: 18, color: Colors.white)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
            ),
          ),
        ],
      ),
    );
  }
}
