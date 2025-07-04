import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/physics.dart';
import 'package:ExpenseTracker/Services/AccountController.dart';
import 'package:ExpenseTracker/screens/AccountPage.dart';
import 'package:ExpenseTracker/widgets/custom_loader.dart';
import 'package:flutter/services.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid balance')),
      );
      return;
    }

    if (_selectedAccountType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an account type')),
      );
      return;
    }

    // Additional validation for Digital Account and Bank Account
    if (_selectedAccountType == 'Digital Account' &&
        _selectedUPIAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a digital account')),
      );
      return;
    }

    if (_selectedAccountType == 'Bank Account' &&
        _selectedBankAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a bank account')),
      );
      return;
    }

    // If validation passes, execute the task
    await CustomLoader.showLoaderForTask(
      context: context,
      task: () async {
        String selectedAccountType = _selectedAccountType ?? 'Wallet';
        String? accountName = _accountNameController.text.isNotEmpty
            ? _accountNameController.text
            : null;
        double balance = double.tryParse(_balanceController.text) ?? 0.0;

        try {
          // Attempt to add the new account
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
          // Handle specific error for duplicate accounts
          if (e.toString().contains("account with this name already exists")) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'An account with this name already exists. Please choose a different name.'),
                duration: Duration(seconds: 3),
              ),
            );
          } else {
            // Handle other errors
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Cannot add duplicate accounts: ${e.toString()}'),
                duration: const Duration(seconds: 3),
              ),
            );
          }
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color.fromRGBO(127, 61, 255, 1),
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
                      const Color.fromRGBO(127, 61, 255, 1),
                      const Color.fromRGBO(127, 61, 255, 0.8),
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
                            'Add New Account',
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
                    // Amount Input Card
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
                            'How Much?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _balanceController,
                            cursorColor: Colors.white,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              prefixIcon: Container(
                                margin: const EdgeInsets.only(right: 8),
                                child: const Icon(
                                  Icons.currency_exchange,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              hintText: '0',
                              hintStyle: const TextStyle(
                                color: Colors.white54,
                                fontSize: 32,
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
                      // Account Type Section
                      _buildSectionCard(
                        'Account Type',
                        Icons.account_balance,
                        [
                          DropdownButtonFormField2<String>(
                            value: _selectedAccountType,
                            decoration: InputDecoration(
                              labelText: 'Select Account Type',
                              labelStyle: const TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: Colors.grey.withOpacity(0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: Colors.grey.withOpacity(0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color.fromRGBO(127, 61, 255, 1),
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.grey.withOpacity(0.05),
                            ),
                            buttonStyleData: ButtonStyleData(
                              height: 60,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.grey.withOpacity(0.05),
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
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.white,
                              ),
                              offset: const Offset(0, -10),
                              scrollbarTheme: ScrollbarThemeData(
                                radius: const Radius.circular(40),
                                thickness: WidgetStateProperty.all(6),
                                thumbVisibility: WidgetStateProperty.all(true),
                              ),
                            ),
                            menuItemStyleData: const MenuItemStyleData(
                              height: 50,
                              padding: EdgeInsets.symmetric(horizontal: 16),
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
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Conditionally show Digital Account or Bank Account section
                      if (_selectedAccountType == 'Digital Account') ...[
                        _buildSectionCard(
                          'Digital Account',
                          Icons.account_balance_wallet,
                          [
                            DropdownButtonFormField2<String>(
                              value: _selectedUPIAccount,
                              decoration: InputDecoration(
                                labelText: 'Select Digital Account',
                                labelStyle: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: Colors.grey.withOpacity(0.3)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: Colors.grey.withOpacity(0.3)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color.fromRGBO(127, 61, 255, 1),
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.grey.withOpacity(0.05),
                              ),
                              buttonStyleData: ButtonStyleData(
                                height: 60,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.grey.withOpacity(0.05),
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
                                  borderRadius: BorderRadius.circular(12),
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
                                padding: EdgeInsets.symmetric(horizontal: 16),
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
                                          padding: const EdgeInsets.all(8.0),
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
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.account_balance_wallet,
                                      size: 20,
                                      color: Color.fromRGBO(127, 61, 255, 1),
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
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: Color(0xFFF1F1FA)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
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
                        ),
                      ] else if (_selectedAccountType == 'Bank Account') ...[
                        _buildSectionCard(
                          'Bank Account',
                          Icons.account_balance,
                          [
                            DropdownButtonFormField2<String>(
                              value: _selectedBankAccount,
                              decoration: InputDecoration(
                                labelText: 'Select Bank Account',
                                labelStyle: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: Colors.grey.withOpacity(0.3)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: Colors.grey.withOpacity(0.3)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color.fromRGBO(127, 61, 255, 1),
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.grey.withOpacity(0.05),
                              ),
                              buttonStyleData: ButtonStyleData(
                                height: 60,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.grey.withOpacity(0.05),
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
                                  borderRadius: BorderRadius.circular(12),
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
                                padding: EdgeInsets.symmetric(horizontal: 16),
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
                                          padding: const EdgeInsets.all(8.0),
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
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.account_balance,
                                      size: 20,
                                      color: Color.fromRGBO(127, 61, 255, 1),
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
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: Color(0xFFF1F1FA)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
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
                        ),
                      ],
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
                const Color.fromRGBO(127, 61, 255, 1),
                const Color.fromRGBO(127, 61, 255, 0.8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color.fromRGBO(127, 61, 255, 0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            onPressed: () {
              _onContinuePressed(context);
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            icon: const Icon(Icons.check, color: Colors.white, size: 24),
            label: const Text(
              'Continue',
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

// Helper method for section cards
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
                    color: const Color.fromRGBO(127, 61, 255, 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: const Color.fromRGBO(127, 61, 255, 1),
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
}
