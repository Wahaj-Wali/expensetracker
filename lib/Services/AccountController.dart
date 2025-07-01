import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Digital account types with their images
  final List<Map<String, String>> _upiAccounts = [
    {'name': 'EasyPaisa', 'image': 'assets/images/easypaisa.png'},
    {'name': 'JazzCash', 'image': 'assets/images/jazzcash.png'},
    {'name': 'NayaPay', 'image': 'assets/images/nayapay.png'},
    {'name': 'SadaPay', 'image': 'assets/images/sadapay.png'},
    {'name': 'Zindagi', 'image': 'assets/images/zindagi.png'},
    {'name': 'Upaisa', 'image': 'assets/images/upaisa.png'},
  ];

  // Bank account types with their images
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

  // Check for duplicate accounts
  Future<bool> isDuplicateAccount({
    required String accountType,
    String? accountName,
    String? selectedUPIAccount,
    String? selectedBankAccount,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('email');

    if (email == null) {
      throw Exception("No email found in SharedPreferences.");
    }

    QuerySnapshot querySnapshot = await _firestore
        .collection('accounts')
        .where('email', isEqualTo: email)
        .get();

    List<Map<String, dynamic>> existingAccounts = querySnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();

    String nameToCheck = '';
    if (accountType == 'Wallet') {
      nameToCheck = accountName?.isEmpty ?? true ? 'Wallet' : accountName!;
    } else if (accountType == 'Digital Account' && selectedUPIAccount != null) {
      nameToCheck =
          accountName?.isEmpty ?? true ? selectedUPIAccount : accountName!;
    } else if (accountType == 'Bank Account' && selectedBankAccount != null) {
      nameToCheck =
          accountName?.isEmpty ?? true ? selectedBankAccount : accountName!;
    }

    return existingAccounts.any((account) =>
        account['account_name'].toString().toLowerCase() ==
        nameToCheck.toLowerCase());
  }

  // Add a new account
  Future<void> addNewAccount({
    required String accountType,
    required String? accountName,
    required double balance,
    String? selectedUPIAccount,
    String? selectedBankAccount,
  }) async {
    // Check for duplicates first
    bool isDuplicate = await isDuplicateAccount(
      accountType: accountType,
      accountName: accountName,
      selectedUPIAccount: selectedUPIAccount,
      selectedBankAccount: selectedBankAccount,
    );

    if (isDuplicate) {
      throw Exception("An account with this name already exists.");
    }

    final prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('email');

    if (email == null) {
      throw Exception("No email found in SharedPreferences.");
    }

    var uuid = const Uuid();
    String accountId = uuid.v4();

    String accountImage;
    String accountNameToInsert;

    if (accountType == 'Wallet') {
      accountImage = 'assets/images/wallet.png';
      accountNameToInsert =
          accountName?.isEmpty ?? true ? 'Wallet' : accountName!;
    } else if (accountType == 'Digital Account') {
      var selectedAccount = _upiAccounts.firstWhere(
          (account) => account['name'] == selectedUPIAccount,
          orElse: () =>
              {'name': 'Unknown', 'image': 'assets/images/wallet.png'});
      accountImage = selectedAccount['image']!;
      accountNameToInsert = accountName?.isEmpty ?? true
          ? selectedAccount['name']!
          : accountName!;
    } else if (accountType == 'Bank Account') {
      var selectedBank = _bankAccounts.firstWhere(
          (bank) => bank['name'] == selectedBankAccount,
          orElse: () =>
              {'name': 'Unknown', 'image': 'assets/images/wallet.png'});
      accountImage = selectedBank['image']!;
      accountNameToInsert =
          accountName?.isEmpty ?? true ? selectedBank['name']! : accountName!;
    } else {
      throw Exception("Invalid account type selected.");
    }

    await _firestore.collection('accounts').doc(accountId).set({
      'account_id': accountId,
      'account_name': accountNameToInsert,
      'account_type': accountType,
      'account_image': accountImage,
      'balance': balance.toString(),
      'email': email,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'is_active': true
    });
  }

  // Get all accounts for current user
  Future<List<Map<String, dynamic>>> getAllAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('email');

    if (email == null) {
      throw Exception("No email found in SharedPreferences.");
    }

    QuerySnapshot querySnapshot = await _firestore
        .collection('accounts')
        .where('email', isEqualTo: email)
        .where('is_active', isEqualTo: true)
        .get();

    return querySnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  // Get account by ID
  Future<Map<String, dynamic>> getAccountById(String accountId) async {
    final prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('email');

    if (email == null) {
      throw Exception("No email found in SharedPreferences.");
    }

    DocumentSnapshot doc =
        await _firestore.collection('accounts').doc(accountId).get();

    if (!doc.exists) {
      throw Exception("Account not found.");
    }

    Map<String, dynamic> accountData = doc.data() as Map<String, dynamic>;
    if (accountData['email'] != email) {
      throw Exception("Unauthorized access to account.");
    }

    return accountData;
  }

  // Update account
  Future<void> updateAccount({
    required String accountId,
    String? accountName,
    double? balance,
    bool? isActive,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('email');

    if (email == null) {
      throw Exception("No email found in SharedPreferences.");
    }

    // Get current account data
    DocumentSnapshot doc =
        await _firestore.collection('accounts').doc(accountId).get();

    if (!doc.exists) {
      throw Exception("Account not found.");
    }

    Map<String, dynamic> accountData = doc.data() as Map<String, dynamic>;
    if (accountData['email'] != email) {
      throw Exception("Unauthorized access to account.");
    }

    // Check for duplicate name if name is being updated
    if (accountName != null && accountName != accountData['account_name']) {
      bool isDuplicate = await isDuplicateAccount(
        accountType: accountData['account_type'],
        accountName: accountName,
      );

      if (isDuplicate) {
        throw Exception("An account with this name already exists.");
      }
    }

    // Prepare update data
    Map<String, dynamic> updateData = {
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    if (accountName != null) updateData['account_name'] = accountName;
    if (balance != null) updateData['balance'] = balance.toString();
    if (isActive != null) updateData['is_active'] = isActive;

    // Update the account
    await _firestore.collection('accounts').doc(accountId).update(updateData);
  }

  // Delete account (soft delete)
  Future<void> deleteAccount(String accountId) async {
    await updateAccount(accountId: accountId, isActive: false);
  }

  // Get account balance
  Future<double> getAccountBalance(String accountId) async {
    Map<String, dynamic> accountData = await getAccountById(accountId);
    return double.parse(accountData['balance']);
  }

  // Update account balance
  Future<void> updateAccountBalance(String accountId, double newBalance) async {
    await updateAccount(accountId: accountId, balance: newBalance);
  }

  // Get account types
  List<String> getAccountTypes() {
    return ['Wallet', 'Digital Account', 'Bank Account'];
  }

  // Get digital account options
  List<Map<String, String>> getDigitalAccountOptions() {
    return _upiAccounts;
  }

  // Get bank account options
  List<Map<String, String>> getBankAccountOptions() {
    return _bankAccounts;
  }
}
