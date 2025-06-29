import 'package:ExpenseTracker/screens/EditCategoryScreen.dart';
import 'package:ExpenseTracker/Services/CategoriesService.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ExpenseTracker/screens/AddCategoryPage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  _CategoriesPageState createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  List<Map<String, dynamic>> _categoryItems = [];
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  // Initialize user data and fetch categories
  Future<void> _initializeData() async {
    final prefs = await SharedPreferences.getInstance();
    _userEmail = prefs.getString('email');
    if (_userEmail != null) {
      fetchCategories();
    }
  }

  // Function to fetch categories using the new service method
  Future<void> fetchCategories() async {
    if (_userEmail == null) return;

    try {
      List<Map<String, dynamic>> categories =
          await DefaultCategoriesService.getAllCategories(_userEmail!);

      setState(() {
        _categoryItems = categories;
      });
    } catch (e) {
      print("Error fetching categories: $e");
    }
  }

  // Function to delete category and its related transactions
  Future<void> deleteCategory(String categoryId, String categoryName,
      bool isDefault, bool isGlobal) async {
    // Prevent deletion of global default categories
    if (isGlobal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Default categories cannot be deleted'),
          backgroundColor: Color.fromRGBO(253, 60, 74, 1),
        ),
      );
      return;
    }

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? email = prefs.getString('email');

      WriteBatch batch = FirebaseFirestore.instance.batch();

      DocumentReference categoryRef =
          FirebaseFirestore.instance.collection('categories').doc(categoryId);

      batch.delete(categoryRef);

      QuerySnapshot transactionsSnapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('email', isEqualTo: email)
          .where('category_name', isEqualTo: categoryName)
          .get();

      for (var doc in transactionsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      setState(() {
        _categoryItems.removeWhere((item) => item['id'] == categoryId);
      });

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
    'Car': Icons.directions_car,
    'Bus': Icons.directions_bus,
    'Bike': Icons.directions_bike,
    'Taxi': Icons.local_taxi,
    'Plumbing': Icons.plumbing,
    'Movie': Icons.movie,
    'M': Icons.music_note,
    'Games': Icons.sports_esports,
    'Ticket': Icons.local_movies,
    'Groceries': Icons.shopping_cart,
    'Clothing': Icons.local_mall,
    'Gym': Icons.fitness_center,
    'Hospital': Icons.local_hospital,
    'Pharmacy': Icons.local_pharmacy,
    'FirstAid': Icons.healing,
    'Rent': Icons.home,
    'Apartment': Icons.apartment,
    'Kitchen': Icons.kitchen,
    'Furniture': Icons.weekend,
  };

  IconData? getIconData(String iconName) {
    return _flutterIcons[iconName];
  }

  // Show edit/delete options dialog
  // Show edit/delete options dialog
  void _showCategoryOptionsDialog(Map<String, dynamic> category) {
    bool isGlobal = category['is_global'] ?? false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Color(int.parse(
                          category['iconColor'].replaceFirst('#', '0xFF')))
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  getIconData(category['iconName']),
                  color: Color(int.parse(
                      category['iconColor'].replaceFirst('#', '0xFF'))),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  category['name'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isGlobal)
                Container(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: const Row(
                    children: [
                      Icon(Icons.public, size: 16, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'This is a global default category',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              if (!isGlobal && (category['is_default'] == true))
                Container(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'This is a custom category',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              Text(
                'Tax: ${category['salesTaxApplicable'] == true ? '${category['salesTaxPercentage']}%' : 'Exempt'}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              // Styled "What would you like to do?" section matching delete dialog
              const Row(
                children: [
                  Icon(Icons.help_outline, color: Colors.red, size: 28),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'What would you like to do?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Choose an action for this category.',
                style: const TextStyle(fontSize: 16, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.black)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            if (!isGlobal) // Only show edit for custom categories
              ElevatedButton.icon(
                icon: const Icon(Icons.edit_outlined,
                    color: Colors.white, size: 18),
                label:
                    const Text('Edit', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(127, 61, 255, 1),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  _editCategory(category);
                },
              ),
            if (!isGlobal) // Only show delete for custom categories
              ElevatedButton.icon(
                icon: const Icon(Icons.delete_outline,
                    color: Colors.white, size: 18),
                label:
                    const Text('Delete', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  _showDeleteConfirmationDialog(
                    category['id'],
                    category['name'],
                    category['is_default'] ?? false,
                    isGlobal,
                  );
                },
              ),
          ],
        );
      },
    );
  }

// Navigate to edit category page
  void _editCategory(Map<String, dynamic> category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditCategoryPage(category: category),
      ),
    ).then((_) => fetchCategories());
  }

  // Show delete confirmation dialog
  void _showDeleteConfirmationDialog(
      String id, String categoryName, bool isDefault, bool isGlobal) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Delete Category',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Are you sure you want to delete the category "$categoryName"?',
                style: const TextStyle(fontSize: 16, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'All related transactions will also be deleted. This action cannot be undone.',
                style: TextStyle(fontSize: 13, color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.black)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete_outline,
                  color: Colors.white, size: 18),
              label:
                  const Text('Delete', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              onPressed: () {
                deleteCategory(id, categoryName, isDefault, isGlobal);
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
        automaticallyImplyLeading: false,
        title: const Text(
          'Manage Categories',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Show message if no categories exist
          if (_categoryItems.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading Categories...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please wait while we load your categories',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

          // Categories List
          ..._categoryItems
              .map((item) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 3,
                          blurRadius: 12,
                          offset: const Offset(0, 6),
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
                          Expanded(
                            child: Text(
                              item['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (item['is_global'] == true)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Global',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          if (item['is_global'] != true &&
                              item['is_default'] == true)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color.fromRGBO(127, 61, 255, 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Custom',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color.fromRGBO(127, 61, 255, 1),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: item['salesTaxApplicable'] == true
                                  ? const Color.fromRGBO(253, 60, 74, 0.12)
                                  : Colors.green.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              item['salesTaxApplicable'] == true
                                  ? 'Tax: ${item['salesTaxPercentage']}%'
                                  : 'Exempt',
                              style: TextStyle(
                                color: item['salesTaxApplicable'] == true
                                    ? const Color.fromRGBO(253, 60, 74, 1)
                                    : Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: const Icon(
                        Icons.more_vert,
                        color: Colors.grey,
                      ),
                      onTap: () => _showCategoryOptionsDialog(item),
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
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 3,
                  blurRadius: 12,
                  offset: const Offset(0, 6),
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
