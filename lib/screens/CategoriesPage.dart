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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  // Initialize user data and fetch categories
  Future<void> _initializeData() async {
    final prefs = await SharedPreferences.getInstance();
    _userEmail = prefs.getString('email');
    fetchCategories();
  }

  // Function to fetch global categories for admin panel
  Future<void> fetchCategories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch only global categories since this is admin panel
      final globalCategoriesSnapshot = await FirebaseFirestore.instance
          .collection('global_categories')
          .orderBy('name')
          .get();

      List<Map<String, dynamic>> categories = [];
      for (var doc in globalCategoriesSnapshot.docs) {
        categories.add({
          'id': doc.id,
          'iconName': doc['iconName'],
          'iconColor': doc['iconColor'],
          'name': doc['name'],
          'is_default': doc['is_default'] ?? true,
          'is_global': true,
          'salesTaxApplicable': doc['salesTaxApplicable'] ?? true,
          'salesTaxPercentage': doc['salesTaxPercentage'] ?? 18.0,
          'created_at': doc['created_at'],
        });
      }

      setState(() {
        _categoryItems = categories;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching categories: $e");
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error loading categories'),
            backgroundColor: Color.fromRGBO(253, 60, 74, 1),
          ),
        );
      }
    }
  }

  // Function to delete global category and update all related transactions
  Future<void> deleteGlobalCategory(
      String categoryId, String categoryName) async {
    setState(() {
      _isLoading = true;
    });

    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();

      // Delete the global category
      DocumentReference categoryRef = FirebaseFirestore.instance
          .collection('global_categories')
          .doc(categoryId);
      batch.delete(categoryRef);

      // Find all transactions that use this category across all users
      QuerySnapshot transactionsSnapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('category_name', isEqualTo: categoryName)
          .get();

      // Delete all related transactions
      for (var doc in transactionsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Also check for transactions that might reference the category ID
      QuerySnapshot transactionsByIdSnapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('category_id', isEqualTo: categoryId)
          .get();

      for (var doc in transactionsByIdSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      // Update local state
      setState(() {
        _categoryItems.removeWhere((item) => item['id'] == categoryId);
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Global category "$categoryName" and ${transactionsSnapshot.docs.length + transactionsByIdSnapshot.docs.length} related transactions deleted successfully'),
            backgroundColor: Color.fromRGBO(0, 168, 107, 1),
          ),
        );
      }
    } catch (e) {
      print("Error deleting global category and transactions: $e");
      setState(() {
        _isLoading = false;
      });
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

  // Show admin category options dialog
  void _showCategoryOptionsDialog(Map<String, dynamic> category) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
              Container(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.admin_panel_settings,
                        size: 16, color: Colors.red),
                    const SizedBox(width: 8),
                    const Text(
                      'Global Category (Admin Panel)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
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
              const SizedBox(height: 8),
              Text(
                'Created: ${category['created_at'] != null ? _formatDate(category['created_at']) : 'Unknown'}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, size: 16, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Deleting this category will remove it for ALL users and delete ALL related transactions.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Edit'),
              onPressed: () {
                Navigator.of(context).pop();
                _editCategory(category);
              },
            ),
            TextButton(
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _showDeleteConfirmationDialog(
                  category['id'],
                  category['name'],
                );
              },
            ),
          ],
        );
      },
    );
  }

  // Helper method to format date
  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    try {
      if (timestamp is Timestamp) {
        DateTime date = timestamp.toDate();
        return '${date.day}/${date.month}/${date.year}';
      }
      return 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
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

  // Show delete confirmation dialog with warning
  void _showDeleteConfirmationDialog(String id, String categoryName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.red, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Delete Global Category',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete "$categoryName"?',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber, size: 16, color: Colors.red),
                        const SizedBox(width: 8),
                        const Text(
                          'This action will:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Remove this category for ALL users\n• Delete ALL transactions using this category\n• This action cannot be undone',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete Permanently'),
              onPressed: () {
                deleteGlobalCategory(id, categoryName);
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
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color.fromRGBO(127, 61, 255, 1),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading categories...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Admin Info Banner

                // Categories Count
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.category, color: Colors.blue, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        'Total Global Categories: ${_categoryItems.length}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),

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
                          'No Global Categories Found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add your first global category to get started',
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
                                color: Color(int.parse(item['iconColor']
                                        .replaceFirst('#', '0xFF')))
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                getIconData(item['iconName']),
                                color: Color(int.parse(item['iconColor']
                                    .replaceFirst('#', '0xFF'))),
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
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Global',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Text(
                              'Tax: ${item['salesTaxApplicable'] == true ? '${item['salesTaxPercentage']}%' : 'Exempt'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            trailing: const Icon(
                              Icons.admin_panel_settings,
                              color: Colors.red,
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
                      'Add Global Category',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color.fromRGBO(127, 61, 255, 1),
                      ),
                    ),
                    subtitle: const Text(
                      'Add a new category for all users',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
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
