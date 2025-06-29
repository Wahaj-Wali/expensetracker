import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class BudgetNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;

  /// Initialize the notification service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    // Request notification permissions
    await _requestNotificationPermissions();

    // Initialize settings for different platforms
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
    debugPrint("Budget Notification Service initialized");
  }

  /// Request notification permissions
  static Future<void> _requestNotificationPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.notification.request();
      if (status != PermissionStatus.granted) {
        debugPrint("Notification permission denied");
      }
    }
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse details) {
    debugPrint("Notification tapped: ${details.payload}");
    // You can add navigation logic here if needed
  }

  /// Show budget exceeded notification
  static Future<void> showBudgetExceededNotification({
    required String categoryName,
    required double spentAmount,
    required double budgetAmount,
    required String alertMessage,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Check if notifications are enabled for this category
    final prefs = await SharedPreferences.getInstance();
    final notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;

    if (!notificationsEnabled) return;

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'budget_alerts',
      'Budget Alerts',
      channelDescription: 'Notifications for budget exceeded alerts',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      color: Color.fromARGB(255, 127, 61, 255),
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    final String title = '💰 Budget Alert: $categoryName';
    final String body = 'You\'ve spent Rs${spentAmount.toStringAsFixed(2)} '
        'of your Rs${budgetAmount.toStringAsFixed(2)} budget. $alertMessage';

    await _notificationsPlugin.show(
      categoryName.hashCode, // Unique ID based on category
      title,
      body,
      platformChannelSpecifics,
      payload: 'budget_exceeded:$categoryName',
    );

    debugPrint("Budget exceeded notification sent for: $categoryName");
  }

  /// Show budget warning notification (when approaching limit)
  static Future<void> showBudgetWarningNotification({
    required String categoryName,
    required double spentAmount,
    required double budgetAmount,
    required double warningPercentage,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Check if notifications are enabled
    final prefs = await SharedPreferences.getInstance();
    final notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;

    if (!notificationsEnabled) return;

    AndroidNotificationDetails androidPlatformChannelSpecifics =
        const AndroidNotificationDetails(
      'budget_warnings',
      'Budget Warnings',
      channelDescription: 'Notifications for budget warning alerts',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      color: Color.fromARGB(255, 255, 152, 0),
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    final String title = '⚠️ Budget Warning: $categoryName';
    final String body = 'You\'ve used ${warningPercentage.toStringAsFixed(0)}% '
        'of your budget (Rs${spentAmount.toStringAsFixed(2)} of Rs${budgetAmount.toStringAsFixed(2)})';

    await _notificationsPlugin.show(
      categoryName.hashCode + 1000, // Different ID for warnings
      title,
      body,
      platformChannelSpecifics,
      payload: 'budget_warning:$categoryName',
    );

    debugPrint("Budget warning notification sent for: $categoryName");
  }

  /// Check all budgets and send notifications if needed
  static Future<void> checkAndNotifyBudgets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email');

      if (email == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .where('email', isEqualTo: email)
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final categoryName = data['name'] as String;
        final balance = (data['balance'] as num?)?.toDouble() ?? 0.0;
        final spend = (data['spend'] as num?)?.toDouble() ?? 0.0;
        final isAlert = data['is_alert'] as bool? ?? false;
        final alertPercentage =
            (data['alert_percentage'] as num?)?.toDouble() ?? 80.0;
        final alertMessage =
            data['alert_msg'] as String? ?? "You've exceeded the limit!";

        // Skip if no budget is set
        if (balance <= 0) continue;

        final spendPercentage = (spend / balance) * 100;

        // Check if budget is exceeded
        if (spend >= balance && isAlert) {
          // Check if we've already sent this notification today
          final lastNotificationKey =
              'last_exceeded_notification_$categoryName';
          final lastNotificationDate = prefs.getString(lastNotificationKey);
          final today = DateTime.now().toIso8601String().split('T')[0];

          if (lastNotificationDate != today) {
            await showBudgetExceededNotification(
              categoryName: categoryName,
              spentAmount: spend,
              budgetAmount: balance,
              alertMessage: alertMessage,
            );

            // Save that we sent notification today
            await prefs.setString(lastNotificationKey, today);
          }
        }
        // Check if approaching budget limit
        else if (spendPercentage >= alertPercentage && isAlert) {
          // Check if we've already sent this warning today
          final lastWarningKey = 'last_warning_notification_$categoryName';
          final lastWarningDate = prefs.getString(lastWarningKey);
          final today = DateTime.now().toIso8601String().split('T')[0];

          if (lastWarningDate != today) {
            await showBudgetWarningNotification(
              categoryName: categoryName,
              spentAmount: spend,
              budgetAmount: balance,
              warningPercentage: spendPercentage,
            );

            // Save that we sent warning today
            await prefs.setString(lastWarningKey, today);
          }
        }
      }
    } catch (e) {
      debugPrint("Error checking budgets for notifications: $e");
    }
  }

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
    debugPrint("All notifications cancelled");
  }

  /// Cancel notification for specific category
  static Future<void> cancelCategoryNotification(String categoryName) async {
    await _notificationsPlugin.cancel(categoryName.hashCode);
    await _notificationsPlugin.cancel(categoryName.hashCode + 1000);
    debugPrint("Cancelled notifications for: $categoryName");
  }

  /// Enable/disable notifications
  static Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);
    debugPrint("Notifications ${enabled ? 'enabled' : 'disabled'}");
  }

  /// Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? true;
  }
}
