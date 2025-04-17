import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore package
import 'package:ExpenseTracker/screens/AddCategoryPage.dart';
import 'package:ExpenseTracker/widgets/CircularMenuWidget.dart';
import 'package:ExpenseTracker/widgets/CustomBottomNavigationBar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  _CategoriesPageState createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final int _activeIndex = 1;
  List<Map<String, dynamic>> _categoryItems = [];

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  // Function to fetch categories from Firestore
  Future<void> fetchCategories() async {
    try {
      // Get email from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? email = prefs.getString('email');

      // Fetch data from Firestore filtered by email
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .where('email', isEqualTo: email) // Filter categories by email
          .get();

      List<Map<String, dynamic>> categories = snapshot.docs.map((doc) {
        return {
          "id": doc.id, // Store document ID for deletion
          "iconName":
              doc['iconName'], // The name of the icon stored in Firestore
          "name": doc['name'], // The name of the category
          "iconColor":
              doc['iconColor'], // Assuming the color is stored as a hex string
        };
      }).toList();

      setState(() {
        _categoryItems = categories;
      });
    } catch (e) {
      print("Error fetching categories: $e");
    }
  }

  // Function to delete category
  // Function to delete category and its related transactions
  Future<void> deleteCategory(String categoryId, String categoryName) async {
    try {
      // Get user email from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? email = prefs.getString('email');

      // Start a batch write
      WriteBatch batch = FirebaseFirestore.instance.batch();

      // Reference to the category document
      DocumentReference categoryRef =
          FirebaseFirestore.instance.collection('categories').doc(categoryId);

      // Delete the category
      batch.delete(categoryRef);

      // Get all related transactions
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
  void _showDeleteConfirmationDialog(String id, String categoryName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Category'),
          content: const Text(
            'Do you want to delete this category? All related transactions will also be deleted.',
            style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
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
                deleteCategory(id, categoryName);
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
                      title: Text(
                        item['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _showDeleteConfirmationDialog(
                            item['id'], item['name']),
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
      bottomNavigationBar: CustomBottomNavigationBar(
        activeIndex: _activeIndex,
      ),
      floatingActionButton: const CircularMenuWidget(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
