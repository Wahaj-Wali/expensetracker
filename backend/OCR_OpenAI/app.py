import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'screens/LoginPage.dart';
import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ExpenseTracker());
}

class ExpenseTracker extends StatefulWidget {
  const ExpenseTracker({super.key});

  @override
  State<ExpenseTracker> createState() => _ExpenseTrackerState();
}

class _ExpenseTrackerState extends State<ExpenseTracker> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _listenForCategoryUpdates();
  }

  void _listenForCategoryUpdates() {
    _firestore.collection('categories').snapshots().listen((snapshot) {
      for (var docChange in snapshot.docChanges) {
        if (docChange.type == DocumentChangeType.modified) {
          var categoryDoc = docChange.doc;
          double spendAmount = (categoryDoc['spend'] ?? 0).toDouble();
          double balance = (categoryDoc['balance'] ?? 0).toDouble();

          if (spendAmount > balance) {
            // You can implement any local logic here, if needed.
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GlobalLoaderOverlay(
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'Expense Tracker',
        home: const LoginPage(),
      ),
    );
  }
}

