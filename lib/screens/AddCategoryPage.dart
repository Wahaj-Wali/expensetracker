import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:ExpenseTracker/widgets/custom_loader.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IconSearchMenu extends StatefulWidget {
  final Function(IconData, String) onIconSelected;
  final Color iconColor;

  const IconSearchMenu(
      {Key? key, required this.onIconSelected, required this.iconColor})
      : super(key: key);

  @override
  _IconSearchMenuState createState() => _IconSearchMenuState();
}

class _IconSearchMenuState extends State<IconSearchMenu> {
  // A map of Flutter icon names and their corresponding icon data.
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

  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredIcons = _flutterIcons.entries
        .where((entry) =>
            entry.key.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
            ),
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              title: const Text(
                'Choose Your Category',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            // Search TextField
            Container(
              margin: const EdgeInsets.all(16),
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
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search Categories...',
                  hintStyle: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey[600],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (query) {
                  setState(() {
                    _searchQuery = query;
                  });
                },
              ),
            ),

            // Icons Grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: filteredIcons.length,
                itemBuilder: (context, index) {
                  final iconName = filteredIcons[index].key;
                  final iconData = filteredIcons[index].value;
                  return GestureDetector(
                    onTap: () {
                      widget.onIconSelected(iconData, iconName);
                      Navigator.pop(context);
                    },
                    child: Container(
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: widget.iconColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              iconData,
                              color: widget.iconColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              iconName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddCategoryPage extends StatefulWidget {
  const AddCategoryPage({super.key});

  @override
  State<AddCategoryPage> createState() => _AddCategoryPageState();
}

class _AddCategoryPageState extends State<AddCategoryPage>
    with SingleTickerProviderStateMixin {
  double topContainerHeight = 550;
  double bottomContainerHeight = 250;
  double maxHeight = 650;
  double minHeight = 200;

  late AnimationController _controller;
  late Animation<double> _animation;
  String selectedIconName = "";

  IconData? selectedIcon;
  Color selectedIconColor = Colors.blue;
  TextEditingController categoryNameController = TextEditingController();

  // Sales Tax Controls
  bool isSalesTaxApplicable = true;
  double salesTaxPercentage = 18.0; // Default Pakistan GST rate
  TextEditingController salesTaxController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _animation =
        Tween<double>(begin: bottomContainerHeight, end: bottomContainerHeight)
            .animate(_controller);

    // Initialize sales tax controller with default value
    salesTaxController.text = salesTaxPercentage.toString();
  }

  @override
  void dispose() {
    _controller.dispose();
    categoryNameController.dispose();
    salesTaxController.dispose();
    super.dispose();
  }

  void onContinuePressed() async {
    await CustomLoader.showLoaderForTask(
        context: context,
        task: () async {
          if (selectedIcon != null && categoryNameController.text.isNotEmpty) {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            String? email = prefs.getString('email');

            // Validate sales tax percentage
            double finalSalesTaxPercentage = 0.0;
            if (isSalesTaxApplicable) {
              if (salesTaxController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Please enter sales tax percentage.')),
                );
                return;
              }

              finalSalesTaxPercentage =
                  double.tryParse(salesTaxController.text) ?? 0.0;
              if (finalSalesTaxPercentage < 0 ||
                  finalSalesTaxPercentage > 100) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Sales tax percentage must be between 0 and 100.')),
                );
                return;
              }
            }

            // Create category data with sales tax information
            final categoryData = {
              'iconName': selectedIconName,
              'iconColor': _colorToHex(selectedIconColor),
              'name': categoryNameController.text,
              'email': email,
              'salesTaxApplicable': isSalesTaxApplicable,
              'salesTaxPercentage': finalSalesTaxPercentage,
              'salesTaxRate': finalSalesTaxPercentage /
                  100, // Store as decimal for calculations
              'createdAt': FieldValue.serverTimestamp(),
              'isCustomCategory': true, // Mark as custom admin category
            };

            // Store in Firestore
            await FirebaseFirestore.instance
                .collection('categories')
                .add(categoryData);

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Category "${categoryNameController.text}" created successfully!',
                ),
                backgroundColor: Colors.green,
              ),
            );

            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content:
                      Text('Please select an icon and enter a category name.')),
            );
          }
        });
  }

  void onVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      bottomContainerHeight -= details.delta.dy * 1.7;
      if (bottomContainerHeight > maxHeight) bottomContainerHeight = maxHeight;
      if (bottomContainerHeight < minHeight) bottomContainerHeight = minHeight;
    });
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2, 8)}';
  }

  void onVerticalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    const spring = SpringDescription(
      mass: 1,
      stiffness: 2000,
      damping: 7,
    );

    final simulation = SpringSimulation(
        spring, bottomContainerHeight, bottomContainerHeight, velocity / 1000);

    _controller.animateWith(simulation);
  }

  Color pickerColor = const Color.fromRGBO(126, 61, 255, 1);

  void _showColorPicker() {
    showDialog(
      barrierColor: const Color.fromARGB(128, 0, 0, 0),
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'Choose Category Color',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(2.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
              ),
              child: ColorPicker(
                pickerAreaBorderRadius: BorderRadius.circular(16),
                pickerColor: pickerColor,
                onColorChanged: (Color color) {
                  setState(() => pickerColor = color);
                },
              ),
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('Done'),
              onPressed: () {
                setState(() {
                  selectedIconColor = pickerColor;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _openIconSearchMenu() {
    showDialog(
      context: context,
      builder: (context) {
        return IconSearchMenu(
          onIconSelected: (iconData, iconName) {
            setState(() {
              selectedIcon = iconData;
              selectedIconName = iconName;
            });
          },
          iconColor: selectedIconColor,
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
          'Create New Category',
          style: TextStyle(
            color: Colors.black,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 16),
          const Text(
            'How your category looks like?',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),

          // Icon Selection Container
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
                  color: selectedIconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  selectedIcon ?? Icons.category_rounded,
                  color: selectedIconColor,
                ),
              ),
              title: const Text(
                'Choose Icon',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              onTap: _openIconSearchMenu,
            ),
          ),

          // Color Selection Container
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
                  color: selectedIconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.color_lens,
                  color: selectedIconColor,
                ),
              ),
              title: const Text(
                'Choose Color',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              onTap: _showColorPicker,
            ),
          ),

          // Category Name Input
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
            child: TextField(
              controller: categoryNameController,
              decoration: InputDecoration(
                labelText: "Category Name",
                labelStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),

          // Sales Tax Section
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
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance,
                        color: selectedIconColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Sales Tax Configuration',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Sales Tax Applicable Switch
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Sales Tax Applicable',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Switch(
                        value: isSalesTaxApplicable,
                        onChanged: (value) {
                          setState(() {
                            isSalesTaxApplicable = value;
                            if (!value) {
                              salesTaxController.text = '0';
                              salesTaxPercentage = 0.0;
                            } else {
                              salesTaxController.text = '18.0';
                              salesTaxPercentage = 18.0;
                            }
                          });
                        },
                        activeColor: selectedIconColor,
                      ),
                    ],
                  ),

                  // Sales Tax Percentage Input (only if applicable)
                  if (isSalesTaxApplicable) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: salesTaxController,
                            keyboardType:
                                TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d*')),
                            ],
                            decoration: InputDecoration(
                              labelText: "Tax Percentage (%)",
                              labelStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: selectedIconColor),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                salesTaxPercentage =
                                    double.tryParse(value) ?? 0.0;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Quick preset buttons
                        Column(
                          children: [
                            _buildQuickTaxButton('0%', 0.0),
                            const SizedBox(height: 4),
                            _buildQuickTaxButton('18%', 18.0),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Standard Pakistan GST rate is 18%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Preview Section
          if (selectedIcon != null ||
              categoryNameController.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: selectedIconColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selectedIconColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Preview',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: selectedIconColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          selectedIcon ?? Icons.category_rounded,
                          color: selectedIconColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              categoryNameController.text.isEmpty
                                  ? 'Category Name'
                                  : categoryNameController.text,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isSalesTaxApplicable
                                  ? 'Tax: ${salesTaxPercentage.toStringAsFixed(1)}%'
                                  : 'Tax: Exempt',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // Continue Button
          Container(
            margin: const EdgeInsets.only(top: 24),
            height: 56,
            child: ElevatedButton(
              onPressed: onContinuePressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(127, 61, 255, 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Create Category',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTaxButton(String label, double percentage) {
    return SizedBox(
      width: 45,
      height: 32,
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            salesTaxPercentage = percentage;
            salesTaxController.text = percentage.toString();
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: salesTaxPercentage == percentage
              ? selectedIconColor
              : Colors.grey.shade200,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: salesTaxPercentage == percentage
                ? Colors.white
                : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}
