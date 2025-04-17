import 'package:ExpenseTracker/screens/HomeScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ExpenseTracker/screens/AddAccountPage.dart';
import 'package:ExpenseTracker/widgets/custom_loader.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/CircularMenuWidget.dart';
import '../widgets/CustomBottomNavigationBar.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  List<Map<String, dynamic>> userAccounts = [];
  double totalBalance = 0.0;
  final int _activeIndex = 3;
  @override
  void initState() {
    super.initState();
    _fetchUserAccounts();
  }

  Future<void> _fetchUserAccounts() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? email = prefs.getString('email');

    if (email != null) {
      try {
        final QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection('accounts')
            .where('email', isEqualTo: email)
            .get();

        double calculatedTotalBalance = 0.0;

        final List<Map<String, dynamic>> fetchedAccounts =
            snapshot.docs.map((doc) {
          double accountBalance =
              double.tryParse(doc['balance'].toString()) ?? 0.0;
          calculatedTotalBalance += accountBalance;

          return {
            'id': doc.id,
            'text': doc['account_name'],
            'balance': doc['balance'].toString(),
          };
        }).toList();

        setState(() {
          userAccounts = fetchedAccounts;
          totalBalance = calculatedTotalBalance;
        });
      } catch (e) {
        print("Error fetching user accounts: $e");
      }
    }
  }

  Future<void> _deleteAccount(String accountId) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: const Text('Are you sure you want to delete this account?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () async {
                Navigator.of(context).pop();
                await _performDelete(accountId);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _performDelete(String accountId) async {
    await CustomLoader.showLoaderForTask(
      context: context,
      task: () async {
        try {
          await FirebaseFirestore.instance
              .collection('accounts')
              .doc(accountId)
              .delete();

          setState(() {
            userAccounts.removeWhere((account) => account['id'] == accountId);
            totalBalance = userAccounts.fold(0.0, (sum, account) {
              return sum + (double.tryParse(account['balance']) ?? 0.0);
            });
          });
        } catch (e) {
          print("Error deleting account: $e");
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          },
        ),
        title: const Text(
          "Accounts",
          style: TextStyle(
            color: Colors.black,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Total Balance Card with enhanced shadow
          Container(
            height: 150,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(127, 61, 255, 1),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2), // Lighter shadow color
                  spreadRadius: 3, // Increased spread radius
                  blurRadius: 12, // Increased blur radius
                  offset: const Offset(0, 6), // Slight offset for depth
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Total Balance',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Rs${totalBalance.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 32,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
// In your SettingsPage

          // Accounts List with enhanced shadow
          ...userAccounts
              .map((account) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.15), // Light shadow
                          spreadRadius: 2,
                          blurRadius: 10,
                          offset: const Offset(0, 4), // Slight offset for depth
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(127, 61, 255, 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet,
                          color: Color.fromRGBO(127, 61, 255, 1),
                        ),
                      ),
                      title: Text(
                        account['text'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        'Rs${account['balance']}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _deleteAccount(account['id']),
                      ),
                    ),
                  ))
              .toList(),

          // Add Account Tile with enhanced shadow
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.15), // Light shadow
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: const Offset(0, 4), // Slight offset for depth
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(127, 61, 255, 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.add,
                  color: Color.fromRGBO(127, 61, 255, 1),
                ),
              ),
              title: const Text(
                'Add Account',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color.fromRGBO(127, 61, 255, 1),
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AddAccountPage()),
                ).then((_) => _fetchUserAccounts());
              },
            ),
          ),
        ],
      ),
    );
  }
}
