import 'package:ExpenseTracker/screens/AccountPage.dart';
import 'package:ExpenseTracker/screens/BudgetPage.dart';
import 'package:ExpenseTracker/screens/CategoriesPage.dart';
import 'package:ExpenseTracker/screens/NotificationSettingsPage.dart';
import 'package:ExpenseTracker/screens/AddSplitBillScreen.dart';
import 'package:ExpenseTracker/screens/SplitBill.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.black,
            fontSize: 32, // Adjusted font size to match BudgetPage
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false, // Aligned title to the left like BudgetPage
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const NotificationSettingsPage()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(
              12.0), // Reduced padding to match BudgetPage's horizontal padding
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Budget Tile
              _buildProfileTile(
                context,
                'Budget',
                'Manage your income and expenses from here',
                Icons.account_box,
                const Color.fromRGBO(126, 61, 255, 0.297),
                const Color.fromRGBO(127, 61, 255, 1),
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const BudgetPage()),
                  );
                },
              ),

              // Accounts Tile
              _buildProfileTile(
                context,
                'Accounts',
                'Manage your expense and income categories',
                Icons.category,
                const Color.fromRGBO(126, 61, 255, 0.297),
                const Color.fromRGBO(127, 61, 255, 1),
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AccountPage()),
                  );
                },
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData iconData,
    Color backgroundColor,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(
            bottom: 20.0), // Added bottom padding like the budget items
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2), // Adjusted shadow opacity
                spreadRadius: 3,
                blurRadius: 12,
                offset: const Offset(0, 6), // Matching the offset
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(
                10.0), // Reduced padding inside the container
            child: Row(
              children: [
                Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: backgroundColor,
                  ),
                  child: Center(
                    child: Icon(
                      iconData,
                      size: 30,
                      color: iconColor,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 25, // Matching category title size
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
