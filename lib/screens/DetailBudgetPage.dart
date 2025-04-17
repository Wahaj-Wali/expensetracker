import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ExpenseTracker/screens/UpdateBudgetPage.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class DetailBudgetPage extends StatelessWidget {
  final Map<String, dynamic> budgetItem;

  const DetailBudgetPage({super.key, required this.budgetItem});

  // Method to delete the budget item from Firestore
  void deleteBudgetItem(BuildContext context) async {
    try {
      final budgetCollection =
          FirebaseFirestore.instance.collection('categories');
      final querySnapshot = await budgetCollection
          .where('email',
              isEqualTo: budgetItem[
                  'email']) // Assuming `email` is part of `budgetItem`
          .where('name', isEqualTo: budgetItem['category'])
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Update the document to delete specific fields
        await querySnapshot.docs.first.reference.update({
          'alert_msg': FieldValue.delete(),
          'alert_percentage': FieldValue.delete(),
          'balance': FieldValue.delete(),
          'current_month': FieldValue.delete(),
          'is_alert': FieldValue.delete(),
          'is_reached': FieldValue.delete(),
          'spend': FieldValue.delete(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Selected fields deleted successfully!')),
        );
        Navigator.pop(context); // Go back after deletion
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No matching budget found to delete fields.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting fields: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Detail Budget'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_rounded, color: Colors.black),
            onPressed: () async {
              bool confirmDelete = await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Confirm Deletion'),
                    content: const Text(
                        'Are you sure you want to delete this budget item?'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('No'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Yes'),
                      ),
                    ],
                  );
                },
              );

              if (confirmDelete) {
                // Replace this line with your deletion logic
                deleteBudgetItem(context); // Example delete function

                // Navigate back to BudgetPage
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.donut_large_rounded,
                      color: budgetItem['progressColor']),
                  const SizedBox(width: 8),
                  Text(
                    budgetItem['category'],
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'Remaining',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 5),
            Text(
              budgetItem['remaining'],
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: LinearPercentIndicator(
                width: MediaQuery.of(context).size.width * 0.87,
                lineHeight: 10.0,
                barRadius: const Radius.circular(10),
                percent: budgetItem['progress'],
                backgroundColor: Colors.grey[300],
                progressColor: budgetItem['progressColor'],
              ),
            ),
            const SizedBox(height: 20),
            if (budgetItem['alert'])
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(
                      budgetItem['alertMessage'],
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  ],
                ),
              ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 30.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => Updatebudgetpage(
                            categoryName: budgetItem['category'])),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(127, 61, 255, 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(
                      vertical: 15.0, horizontal: 80.0),
                ),
                child: const Text(
                  "Edit",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
