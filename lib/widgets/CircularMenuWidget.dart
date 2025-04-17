import 'package:flutter/material.dart';
import 'package:ExpenseTracker/screens/AddExpensePage.dart';
import 'package:ExpenseTracker/screens/AddIncomePage.dart';

class CircularMenuWidget extends StatefulWidget {
  const CircularMenuWidget({super.key});

  @override
  State<CircularMenuWidget> createState() => _CircularMenuWidgetState();
}

class _CircularMenuWidgetState extends State<CircularMenuWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  bool isOpened = false;
  final double _buttonSize = 56.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.125,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic,
      ),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
        reverseCurve: Curves.easeInQuart,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      isOpened = !isOpened;
      if (isOpened) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String label,
    required bool isExpense,
  }) {
    const double distance = 100.0; // Reduced distance for better positioning
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          right: 20, // Keep items aligned with the main button
          bottom: isExpense
              ? (distance * _scaleAnimation.value)
              : (distance *
                  2 *
                  _scaleAnimation.value), // Stack items vertically
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 350),
              opacity: isOpened ? 1.0 : 0.0,
              child: GestureDetector(
                onTap: () {
                  onTap();
                  _toggleMenu();
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: _buttonSize,
                      height: _buttonSize,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            spreadRadius: 2,
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
          bottom: 110.0), // Adjust based on your navigation bar height
      height: 350,
      width: MediaQuery.of(context).size.width,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Income Button
          _buildMenuItem(
            icon: Icons.attach_money_rounded,
            color: const Color(0xFF22C55E),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AddIncomePage()),
              );
            },
            label: 'Income',
            isExpense: false,
          ),
          // Expense Button
          _buildMenuItem(
            icon: Icons.money_off_csred_rounded,
            color: const Color(0xFFDC2626),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AddExpensePage()),
              );
            },
            label: 'Expense',
            isExpense: true,
          ),
          // Main Toggle Button
          Positioned(
            bottom: 0,
            right: 20, // Position on the right
            child: GestureDetector(
              onTap: _toggleMenu,
              child: AnimatedBuilder(
                animation: _rotationAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationAnimation.value * 2 * 3.14159,
                    child: Container(
                      width: _buttonSize,
                      height: _buttonSize,
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(127, 61, 255, 1),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromRGBO(127, 61, 255, 1)
                                .withOpacity(0.3),
                            spreadRadius: 2,
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 35,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
