import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:ExpenseTracker/widgets/custom_loader.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class AddBudgetPage extends StatefulWidget {
  const AddBudgetPage({super.key});

  @override
  State<AddBudgetPage> createState() => _AddBudgetPageState();
}

class _AddBudgetPageState extends State<AddBudgetPage>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? selectedCategory;
  List<Map<String, dynamic>> categories = [];

  // Add the icon map (copy from CategoriesPage)
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

  // Add the icon mapping function
  IconData? getIconData(String iconName) {
    return _flutterIcons[iconName];
  }

  bool alert = true;
  double _currentSliderValue = 70;
  TextEditingController amountController = TextEditingController();

  double topContainerHeight = 420;
  double bottomContainerHeight = 380;
  double maxHeight = 650;
  double minHeight = 200;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    fetchCategories();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _animation =
        Tween<double>(begin: bottomContainerHeight, end: bottomContainerHeight)
            .animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    amountController.dispose();
    super.dispose();
  }

  void onVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      bottomContainerHeight -= details.delta.dy * 1.7;
      if (bottomContainerHeight > maxHeight) bottomContainerHeight = maxHeight;
      if (bottomContainerHeight < minHeight) bottomContainerHeight = minHeight;
    });
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

  Future<void> fetchCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email') ?? '';

    final snapshot = await FirebaseFirestore.instance
        .collection('categories')
        .where('email', isEqualTo: email)
        .get();

    setState(() {
      categories = snapshot.docs.map((doc) {
        return {
          "id": doc.id,
          "iconName": doc['iconName'],
          "name": doc['name'],
          "iconColor": doc['iconColor'],
        };
      }).toList();
    });
  }

  Future<void> saveBudget() async {
    await CustomLoader.showLoaderForTask(
      context: context,
      task: () async {
        if (selectedCategory != null && amountController.text.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          final email = prefs.getString('email') ?? '';
          final currentMonth = DateFormat('MMMM yyyy').format(DateTime.now());
          final amount = double.tryParse(amountController.text) ?? 0;

          final budgetData = {
            'email': email,
            'name': selectedCategory!['name'],
            'balance': amount,
            'current_month': currentMonth,
            'is_alert': alert,
            'is_reached': false,
            'spend': 0,
            'alert_msg': "You've exceeded the limit!",
            'alert_percentage': alert ? _currentSliderValue : null,
          };

          try {
            final snapshot = await FirebaseFirestore.instance
                .collection('categories')
                .where('email', isEqualTo: email)
                .where('name', isEqualTo: selectedCategory!['name'])
                .get();

            if (snapshot.docs.isNotEmpty) {
              final docId = snapshot.docs.first.id;
              await FirebaseFirestore.instance
                  .collection('categories')
                  .doc(docId)
                  .update(budgetData);

              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Budget updated successfully!')));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Category not found')));
            }
          } catch (e) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('Error: $e')));
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please fill in all fields')));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(127, 61, 255, 1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Create Budget",
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: SizedBox(
          height: MediaQuery.of(context).size.height -
              AppBar().preferredSize.height -
              MediaQuery.of(context).padding.top,
          child: Stack(
            children: [
              Container(
                color: const Color.fromRGBO(127, 61, 255, 1),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      'How much do you want to spend?',
                      style: TextStyle(
                        color: Color.fromRGBO(255, 255, 255, 0.64),
                        fontSize: 18,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom * 0.5,
                      ),
                      child: TextField(
                        controller: amountController,
                        cursorColor: Colors.white,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 50,
                        ),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          prefixIcon: Container(
                            margin: const EdgeInsets.only(right: 8),
                            child: const Icon(
                              Icons.currency_exchange,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                          hintText: '0',
                          hintStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 50,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 0,
                child: GestureDetector(
                  onVerticalDragUpdate: onVerticalDragUpdate,
                  onVerticalDragEnd: onVerticalDragEnd,
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Container(
                        width: MediaQuery.of(context).size.width,
                        height: bottomContainerHeight,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(32),
                            topRight: Radius.circular(32),
                          ),
                        ),
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              children: [
                                const SizedBox(height: 16),
                                DropdownButtonFormField2<Map<String, dynamic>>(
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16.0),
                                      borderSide: const BorderSide(
                                          color: Color(0xFFF1F1FA), width: 1),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16.0),
                                      borderSide: const BorderSide(
                                          color: Color(0xFFF1F1FA), width: 1),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16.0),
                                      borderSide: const BorderSide(
                                          color:
                                              Color.fromRGBO(127, 61, 255, 1),
                                          width: 1),
                                    ),
                                  ),
                                  buttonStyleData: ButtonStyleData(
                                    height: 60,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      color: const Color(0xFFF1F1FA),
                                    ),
                                  ),
                                  iconStyleData: const IconStyleData(
                                    icon: Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: Colors.black54,
                                    ),
                                    iconSize: 24,
                                  ),
                                  dropdownStyleData: DropdownStyleData(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      color: Colors.white,
                                    ),
                                    offset: const Offset(0, -10),
                                    scrollbarTheme: ScrollbarThemeData(
                                      radius: const Radius.circular(40),
                                      thickness: WidgetStateProperty.all(6),
                                      thumbVisibility:
                                          WidgetStateProperty.all(true),
                                    ),
                                  ),
                                  menuItemStyleData: const MenuItemStyleData(
                                    height: 50,
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 16),
                                  ),
                                  items: categories
                                      .map((Map<String, dynamic> category) {
                                    return DropdownMenuItem<
                                        Map<String, dynamic>>(
                                      value: category,
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: Color(int.parse(
                                                      category['iconColor']
                                                          .replaceFirst(
                                                              '#', '0xFF')))
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              getIconData(category['iconName']),
                                              color: Color(int.parse(
                                                  category['iconColor']
                                                      .replaceFirst(
                                                          '#', '0xFF'))),
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            category['name'],
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  value: selectedCategory,
                                  onChanged: (Map<String, dynamic>? value) {
                                    setState(() {
                                      selectedCategory = value;
                                    });
                                  },
                                  hint: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: const Color.fromRGBO(
                                              127, 61, 255, 0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.category,
                                          size: 20,
                                          color:
                                              Color.fromRGBO(127, 61, 255, 1),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Select Category',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                ///
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Receive Alert',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 16,
                                          ),
                                        ),
                                        SizedBox(height: 5),
                                        Text(
                                          'Receive alert when it reaches some point.',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Switch(
                                      value: alert,
                                      activeColor:
                                          const Color.fromRGBO(127, 61, 255, 1),
                                      onChanged: (bool value) {
                                        setState(() {
                                          alert = value;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                if (alert) ...[
                                  Slider(
                                    value: _currentSliderValue,
                                    max: 100,
                                    divisions: 10,
                                    activeColor:
                                        const Color.fromRGBO(127, 61, 255, 1),
                                    label: "${_currentSliderValue.round()}%",
                                    onChanged: (double value) {
                                      setState(() {
                                        _currentSliderValue = value;
                                      });
                                    },
                                  ),
                                ],
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: saveBudget,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          const Color.fromRGBO(127, 61, 255, 1),
                                      minimumSize:
                                          const Size(double.infinity, 48),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      'Continue',
                                      style: TextStyle(
                                          fontSize: 18, color: Colors.white),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
