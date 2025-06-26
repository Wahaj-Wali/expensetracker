import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore package
import 'package:ExpenseTracker/screens/AddCategoryPage.dart';

import 'package:shared_preferences/shared_preferences.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  _CategoriesPageState createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  List<Map<String, dynamic>> _categoryItems = [];

  @override
  void initState() {
    super.initState();
    initializeDefaultCategories();
    fetchCategories();
  }

  // Function to create default categories for new users
  Future<void> initializeDefaultCategories() async {
    try {
      // Check if any default categories exist (not user-specific anymore)
      QuerySnapshot defaultCategories = await FirebaseFirestore.instance
          .collection('categories')
          .where('isDefault', isEqualTo: true)
          .get();

      // If no default categories exist, create them
      if (defaultCategories.docs.isEmpty) {
        await createDefaultCategories();
      }
    } catch (e) {
      print("Error initializing default categories: $e");
    }
  }

  // Function to create default categories
  // 1. Fix initializeDefaultCategories() method:

// 2. Fix createDefaultCategories() method:
  Future<void> createDefaultCategories() async {
    final defaultCategories = [
      {
        'iconName': 'Restaurant',
        'name': 'Food & Drinks',
        'iconColor': '#FF6B6B'
      },
      {'iconName': 'Car', 'name': 'Transportation', 'iconColor': '#4ECDC4'},
      {'iconName': 'Groceries', 'name': 'Shopping', 'iconColor': '#45B7D1'},
      {'iconName': 'Movie', 'name': 'Entertainment', 'iconColor': '#96CEB4'},
      {'iconName': 'Hospital', 'name': 'Health', 'iconColor': '#FFEAA7'},
      {'iconName': 'Rent', 'name': 'Housing', 'iconColor': '#DDA0DD'},
      {'iconName': 'Plumbing', 'name': 'Utilities', 'iconColor': '#98D8C8'},
      {'iconName': 'Gym', 'name': 'Fitness', 'iconColor': '#F7DC6F'},
    ];

    WriteBatch batch = FirebaseFirestore.instance.batch();

    for (var category in defaultCategories) {
      DocumentReference docRef =
          FirebaseFirestore.instance.collection('categories').doc();
      batch.set(docRef, {
        'iconName': category['iconName'],
        'name': category['name'],
        'iconColor': category['iconColor'],
        // 'email': email, // REMOVED - no longer user-specific
        'isDefault': true, // Mark as default category
        'salesTaxApplicable': true,
        'salesTaxPercentage': 18.0,
        'salesTaxRate': 0.18,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  // Function to fetch categories from Firestore
  Future<void> fetchCategories() async {
    try {
      // Fetch ALL categories from Firestore (no email filtering)
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .orderBy('createdAt',
              descending: false) // Optional: order by creation date
          .get();

      List<Map<String, dynamic>> categories = snapshot.docs.map((doc) {
        return {
          "id": doc.id, // Store document ID for deletion
          "iconName":
              doc['iconName'], // The name of the icon stored in Firestore
          "name": doc['name'], // The name of the category
          "iconColor":
              doc['iconColor'], // Assuming the color is stored as a hex string
          "isDefault": doc.data().toString().contains('isDefault')
              ? doc['isDefault']
              : false,
        };
      }).toList();

      setState(() {
        _categoryItems = categories;
      });
    } catch (e) {
      print("Error fetching categories: $e");
    }
  }

  // Function to delete category and its related transactions
  Future<void> deleteCategory(
      String categoryId, String categoryName, bool isDefault) async {
    try {
      // Get user email from SharedPreferences (still needed for transactions)
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? email = prefs.getString('email');

      // Start a batch write
      WriteBatch batch = FirebaseFirestore.instance.batch();

      // Reference to the category document
      DocumentReference categoryRef =
          FirebaseFirestore.instance.collection('categories').doc(categoryId);

      // Delete the category
      batch.delete(categoryRef);

      // Get all related transactions (transactions are still user-specific)
      QuerySnapshot transactionsSnapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('email', isEqualTo: email)
          .where('category_name', isEqualTo: categoryName)
          .get();

      // Add delete operations for all related transactions to the batch
      for (var doc in transactionsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Commit the batch
      await batch.commit();

      // Update the UI
      setState(() {
        _categoryItems.removeWhere((item) => item['id'] == categoryId);
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Category and related transactions deleted successfully'),
            backgroundColor: Color.fromRGBO(0, 168, 107, 1),
          ),
        );
      }
    } catch (e) {
      print("Error deleting category and transactions: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error deleting category and transactions'),
            backgroundColor: Color.fromRGBO(253, 60, 74, 1),
          ),
        );
      }
    }
  }

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

  // Icon mapping function to get IconData based on icon name
  IconData? getIconData(String iconName) {
    return _flutterIcons[iconName];
  }

  // Show delete confirmation dialog
  void _showDeleteConfirmationDialog(
      String id, String categoryName, bool isDefault) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Category'),
          content: Text(
            isDefault
                ? 'Do you want to delete this default category? All related transactions will also be deleted.'
                : 'Do you want to delete this category? All related transactions will also be deleted.',
            style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
          ),
          actions: [
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Yes',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                deleteCategory(id, categoryName, isDefault);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
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
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Categories",
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
          // Categories List
          ..._categoryItems
              .map((item) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey
                              .withOpacity(0.2), // Lighter shadow color
                          spreadRadius: 3, // Increased spread radius
                          blurRadius: 12, // Increased blur radius
                          offset: const Offset(0, 6), // Slight offset for depth
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Color(int.parse(
                                  item['iconColor'].replaceFirst('#', '0xFF')))
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          getIconData(item['iconName']),
                          color: Color(int.parse(
                              item['iconColor'].replaceFirst('#', '0xFF'))),
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(
                            item['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (item['isDefault'] == true)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color.fromRGBO(127, 61, 255, 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Default',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color.fromRGBO(127, 61, 255, 1),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          item['isDefault'] == true
                              ? Icons.lock_outline
                              : Icons.delete_outline,
                          color: item['isDefault'] == true ? Colors.grey : null,
                        ),
                        onPressed: () => _showDeleteConfirmationDialog(
                            item['id'],
                            item['name'],
                            item['isDefault'] ?? false),
                      ),
                    ),
                  ))
              .toList(),

          // Add Category Tile
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
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
                'Add Category',
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
                      builder: (context) => const AddCategoryPage()),
                ).then((_) => fetchCategories());
              },
            ),
          ),
        ],
      ),
    );
  }
}
