import 'package:ExpenseTracker/screens/AccountPage.dart';
import 'package:ExpenseTracker/screens/ReportGenerationPage.dart';
import 'package:ExpenseTracker/screens/TransactionPage.dart';
import 'package:ExpenseTracker/screens/tax_calulator_screen.dart';
import 'package:flutter/material.dart';
import 'package:ExpenseTracker/screens/BudgetPage.dart';
import 'package:ExpenseTracker/screens/HomeScreen.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int activeIndex;

  const CustomBottomNavigationBar({
    super.key,
    required this.activeIndex,
  });

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(bottom: 0),
        child: Stack(
          children: [
            CustomPaint(
              size: Size(width, (width * 0.25).toDouble()),
              painter: RPSCustomPainter(),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 80,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Home
                    Column(
                      children: [
                        IconButton(
                          icon: Icon(Icons.home_rounded,
                              color: activeIndex == 0
                                  ? const Color.fromRGBO(127, 61, 255, 1)
                                  : Colors.grey),
                          onPressed: () => {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (context) => const HomeScreen()),
                            ),
                          },
                          iconSize: activeIndex != 0 ? 35 : 36,
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (context) => const HomeScreen()),
                            );
                          },
                          child: Text(
                            'Home',
                            style: TextStyle(
                                color: activeIndex == 0
                                    ? const Color.fromRGBO(127, 61, 255, 1)
                                    : Colors.grey,
                                fontSize: activeIndex != 0 ? 12 : 13,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    // Budget
                    Column(
                      children: [
                        IconButton(
                          icon: Icon(Icons.compare_arrows_rounded,
                              color: activeIndex == 1
                                  ? const Color.fromRGBO(127, 61, 255, 1)
                                  : Colors.grey),
                          onPressed: () => {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const Transactionpage()),
                            ),
                          },
                          iconSize: activeIndex != 1 ? 35 : 36,
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const Transactionpage()),
                            );
                          },
                          child: Text(
                            'Transaction',
                            style: TextStyle(
                                color: activeIndex == 1
                                    ? const Color.fromRGBO(127, 61, 255, 1)
                                    : Colors.grey,
                                fontSize: activeIndex != 1 ? 12 : 13,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    // Transaction
                    Column(
                      children: [
                        IconButton(
                          icon: Icon(Icons.pie_chart_rounded,
                              color: activeIndex == 2
                                  ? const Color.fromRGBO(127, 61, 255, 1)
                                  : Colors.grey),
                          onPressed: () => {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (context) => const BudgetPage()),
                            ),
                          },
                          iconSize: activeIndex != 2 ? 35 : 36,
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (context) => const BudgetPage()),
                            );
                            // Add your transaction page navigation here
                          },
                          child: Text(
                            'Budget',
                            style: TextStyle(
                                color: activeIndex == 2
                                    ? const Color.fromRGBO(127, 61, 255, 1)
                                    : Colors.grey,
                                fontSize: activeIndex != 2 ? 12 : 13,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    // Report
                    Column(
                      children: [
                        IconButton(
                          icon: Icon(Icons.receipt_rounded,
                              color: activeIndex == 3
                                  ? const Color.fromRGBO(127, 61, 255, 1)
                                  : Colors.grey),
                          onPressed: () => {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const ReportGenerationPage()),
                            ),
                          },
                          iconSize: activeIndex != 3 ? 35 : 36,
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const ReportGenerationPage()),
                            );
                          },
                          child: Text(
                            'Report',
                            style: TextStyle(
                                color: activeIndex == 3
                                    ? const Color.fromRGBO(127, 61, 255, 1)
                                    : Colors.grey,
                                fontSize: activeIndex != 3 ? 12 : 13,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    // Tax
                    Column(
                      children: [
                        IconButton(
                          icon: Icon(Icons.calculate,
                              color: activeIndex == 4
                                  ? const Color.fromRGBO(127, 61, 255, 1)
                                  : Colors.grey),
                          onPressed: () => {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (context) => TaxCalculatorScreen()),
                            ),
                          },
                          iconSize: activeIndex != 4 ? 35 : 36,
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => TaxCalculatorScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'Tax',
                            style: TextStyle(
                                color: activeIndex == 4
                                    ? const Color.fromRGBO(127, 61, 255, 1)
                                    : Colors.grey,
                                fontSize: activeIndex != 4 ? 12 : 13,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RPSCustomPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    Path path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
