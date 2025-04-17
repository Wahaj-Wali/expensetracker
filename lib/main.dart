import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  late SharedPreferences _prefs;

  DateTime _lastNotificationTime = DateTime.now();
  StreamSubscription? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _initializePreferences();
    _initNotifications();
    _initializeBudgetCheck();
    _listenForCategoryUpdates();
  }

  Future<void> _initializeBudgetCheck() async {
    await _checkAndAddNotification();
  }

  Future<bool> _checkAndAddNotification() async {
    bool notificationGenerated = false;

    try {
      QuerySnapshot categorySnapshot =
          await _firestore.collection('categories').get();

      for (var categoryDoc in categorySnapshot.docs) {
        double spendAmount = (categoryDoc['spend'] ?? 0).toDouble();
        double balance = (categoryDoc['balance'] ?? 0).toDouble();
        String categoryName = categoryDoc['name'] ?? '';
        String? email = categoryDoc['email'];

        if (spendAmount > balance) {
          QuerySnapshot existingNotifications = await _firestore
              .collection('notifications')
              .where('email', isEqualTo: email)
              .where('category', isEqualTo: categoryName)
              .get();

          if (existingNotifications.docs.isEmpty) {
            await _firestore.collection('notifications').add({
              'title': "Budget Alert for $categoryName",
              'description': "You have exceeded your budget for $categoryName.",
              'timestamp': DateTime.now(),
              'email': email,
              'category': categoryName,
            });

            notificationGenerated = true;
          }
        }
      }
    } catch (e) {
      print("Error fetching category data: $e");
    }

    return notificationGenerated;
  }

  void _initializePreferences() async {
    _prefs = await SharedPreferences.getInstance();
    String? lastTimestamp = _prefs.getString('last_notification_time');
    if (lastTimestamp != null) {
      _lastNotificationTime = DateTime.parse(lastTimestamp);
    }
    _setupNotificationListener(_prefs.getString('email') ?? '');
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _setEmailAndResetListener(String email) async {
    await _prefs.setString('email', email);
    _notificationSubscription?.cancel();
    _setupNotificationListener(email);
  }

  void _setupNotificationListener(String email) {
    _notificationSubscription = _firestore
        .collection('notifications')
        .where('email', isEqualTo: email)
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        DateTime docTimestamp = doc['timestamp'].toDate();

        if (docTimestamp.isAfter(_lastNotificationTime)) {
          String title = doc['title'];
          String description = doc['description'];
          String timestamp = docTimestamp.toString();
          String notificationId = doc.id;

          _showNotification(notificationId, title, description, timestamp);

          _prefs.setString('last_notification_time', timestamp);
          _lastNotificationTime = docTimestamp;
        }
      }
    });
  }

  void _listenForCategoryUpdates() {
    _firestore.collection('categories').snapshots().listen((snapshot) {
      for (var docChange in snapshot.docChanges) {
        if (docChange.type == DocumentChangeType.modified) {
          var categoryDoc = docChange.doc;
          double spendAmount = (categoryDoc['spend'] ?? 0).toDouble();
          double balance = (categoryDoc['balance'] ?? 0).toDouble();
          String categoryName = categoryDoc['name'] ?? '';
          String? email = categoryDoc['email'];

          if (spendAmount > balance) {
            _firestore
                .collection('notifications')
                .where('email', isEqualTo: email)
                .where('category', isEqualTo: categoryName)
                .get()
                .then((querySnapshot) {
              if (querySnapshot.docs.isEmpty) {
                _firestore.collection('notifications').add({
                  'title': "Budget Alert",
                  'description':
                      "Your spending in $categoryName has exceeded the allocated budget.",
                  'timestamp': DateTime.now(),
                  'email': email,
                  'category': categoryName,
                });
              }
            });
          }
        }
      }
    });
  }

  Future<void> _showNotification(String notificationId, String title,
      String body, String timestamp) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      notificationId.hashCode,
      title,
      body,
      platformChannelSpecifics,
      payload: timestamp,
    );
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
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
