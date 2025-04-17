import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<Map<String, String>> _upiAccounts = [
    {'name': 'EasyPaisa', 'image': 'assets/images/easypaisa.png'},
    {'name': 'JazzCash', 'image': 'assets/images/jazzcash.png'},
    {'name': 'NayaPay', 'image': 'assets/images/nayapay.png'},
    {'name': 'SadaPay', 'image': 'assets/images/sadapay.png'},
    {'name': 'Zindagi', 'image': 'assets/images/zindagi.png'},
    {'name': 'Upaisa', 'image': 'assets/images/upaisa.png'},
  ];

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

  // Function to add account to Firebase
  Future<void> addNewAccount({
    required String accountType,
    required String? accountName,
    required double balance,
    String? selectedUPIAccount,
    String? selectedBankAccount,
  }) async {
    // Get the email from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('email');

    if (email == null) {
      throw Exception("No email found in SharedPreferences.");
    }

    // Generate a unique account ID
    var uuid = const Uuid();
    String accountId = uuid.v4();

    // Set the account image and name based on the selected account type
    String accountImage;
    String accountNameToInsert;

    if (accountType == 'Wallet') {
      accountImage = 'assets/images/wallet.png';
      accountNameToInsert =
          accountName?.isEmpty ?? true ? 'Wallet' : accountName!;
    } else if (accountType == 'UPI Account') {
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

    // Insert data into Firebase
    await _firestore.collection('accounts').doc(accountId).set({
      'account_id': accountId,
      'account_name': accountNameToInsert,
      'account_image': accountImage,
      'balance': balance.toString(),
      'email': email,
    });
  }
}
