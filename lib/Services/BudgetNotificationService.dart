import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class BudgetNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;
  static const String _budgetAlertsChannelId = 'budget_alerts';
  static const String _budgetWarningsChannelId = 'budget_warnings';
  static const String _dailyRemindersChannelId = 'daily_reminders';

  /// Initialize the notification service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz.initializeTimeZones();

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

    // Create notification channels for Android
    await _createNotificationChannels();

    _isInitialized = true;
    debugPrint("Budget Notification Service initialized");
  }

  /// Create notification channels for Android
  static Future<void> _createNotificationChannels() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      const AndroidNotificationChannel budgetAlertsChannel =
          AndroidNotificationChannel(
        _budgetAlertsChannelId,
        'Budget Alerts',
        description: 'Notifications for budget exceeded alerts',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      const AndroidNotificationChannel budgetWarningsChannel =
          AndroidNotificationChannel(
        _budgetWarningsChannelId,
        'Budget Warnings',
        description: 'Notifications for budget warning alerts',
        importance: Importance.defaultImportance,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      const AndroidNotificationChannel dailyRemindersChannel =
          AndroidNotificationChannel(
        _dailyRemindersChannelId,
        'Daily Reminders',
        description: 'Daily budget check reminders',
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
        showBadge: false,
      );

      final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(budgetAlertsChannel);

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(budgetWarningsChannel);

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(dailyRemindersChannel);
    }
  }

  /// Request notification permissions
  static Future<bool> _requestNotificationPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      // For Android 13+ (API 33+)
      final status = await Permission.notification.request();
      if (status != PermissionStatus.granted) {
        debugPrint("Notification permission denied");
        return false;
      }
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      // For iOS
      final result = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );

      if (result != true) {
        debugPrint("iOS notification permission denied");
        return false;
      }
    }

    return true;
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse details) {
    debugPrint("Notification tapped: ${details.payload}");

    // Parse the payload to handle different notification types
    if (details.payload != null) {
      final payload = details.payload!;
      if (payload.startsWith('budget_exceeded:')) {
        final categoryName = payload.substring('budget_exceeded:'.length);
        debugPrint("Budget exceeded notification tapped for: $categoryName");
        // Add navigation logic here
      } else if (payload.startsWith('budget_warning:')) {
        final categoryName = payload.substring('budget_warning:'.length);
        debugPrint("Budget warning notification tapped for: $categoryName");
        // Add navigation logic here
      } else if (payload == 'daily_reminder') {
        debugPrint("Daily reminder notification tapped");
        // Add navigation logic here
      }
    }
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

    // Check if notifications are enabled
    final notificationsEnabled = await areNotificationsEnabled();
    if (!notificationsEnabled) return;

    // Check if budget alerts are enabled
    final budgetAlertsEnabled = await isBudgetAlertsEnabled();
    if (!budgetAlertsEnabled) return;

    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      _budgetAlertsChannelId,
      'Budget Alerts',
      channelDescription: 'Notifications for budget exceeded alerts',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      color: Color.fromARGB(255, 244, 67, 54), // Red color
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(
        'You\'ve spent Rs${spentAmount.toStringAsFixed(2)} of your Rs${budgetAmount.toStringAsFixed(2)} budget. $alertMessage',
        htmlFormatBigText: true,
        contentTitle: '💰 Budget Alert: $categoryName',
        htmlFormatContentTitle: true,
      ),
      category: AndroidNotificationCategory.alarm,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
      categoryIdentifier: 'budget_alert',
    );

    NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    final String title = '💰 Budget Alert: $categoryName';
    final String body = 'You\'ve spent Rs${spentAmount.toStringAsFixed(2)} '
        'of your Rs${budgetAmount.toStringAsFixed(2)} budget. $alertMessage';

    await _notificationsPlugin.show(
      _generateNotificationId(categoryName, 'exceeded'),
      title,
      body,
      platformChannelSpecifics,
      payload: 'budget_exceeded:$categoryName',
    );

    // Log the notification
    await _logNotification(
        'budget_exceeded', categoryName, spentAmount, budgetAmount);

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
    final notificationsEnabled = await areNotificationsEnabled();
    if (!notificationsEnabled) return;

    // Check if budget warnings are enabled
    final budgetWarningsEnabled = await isBudgetWarningsEnabled();
    if (!budgetWarningsEnabled) return;

    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      _budgetWarningsChannelId,
      'Budget Warnings',
      channelDescription: 'Notifications for budget warning alerts',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      color: Color.fromARGB(255, 255, 152, 0), // Orange color
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(
        'You\'ve used ${warningPercentage.toStringAsFixed(0)}% of your budget (Rs${spentAmount.toStringAsFixed(2)} of Rs${budgetAmount.toStringAsFixed(2)}). Consider reviewing your spending.',
        htmlFormatBigText: true,
        contentTitle: '⚠️ Budget Warning: $categoryName',
        htmlFormatContentTitle: true,
      ),
      category: AndroidNotificationCategory.reminder,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
      categoryIdentifier: 'budget_warning',
    );

    NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    final String title = '⚠️ Budget Warning: $categoryName';
    final String body = 'You\'ve used ${warningPercentage.toStringAsFixed(0)}% '
        'of your budget (Rs${spentAmount.toStringAsFixed(2)} of Rs${budgetAmount.toStringAsFixed(2)})';

    await _notificationsPlugin.show(
      _generateNotificationId(categoryName, 'warning'),
      title,
      body,
      platformChannelSpecifics,
      payload: 'budget_warning:$categoryName',
    );

    // Log the notification
    await _logNotification(
        'budget_warning', categoryName, spentAmount, budgetAmount);

    debugPrint("Budget warning notification sent for: $categoryName");
  }

  /// Show daily budget reminder notification
  static Future<void> showDailyReminderNotification({
    required int totalBudgets,
    required int exceededBudgets,
    required int warningBudgets,
    required double totalSpent,
    required double totalBudget,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Check if daily reminders are enabled
    final dailyRemindersEnabled = await isDailyRemindersEnabled();
    if (!dailyRemindersEnabled) return;

    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      _dailyRemindersChannelId,
      'Daily Reminders',
      channelDescription: 'Daily budget check reminders',
      importance: Importance.low,
      priority: Priority.low,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      color: Color.fromARGB(255, 76, 175, 80), // Green color
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(
        'You have $totalBudgets active budgets. $exceededBudgets exceeded, $warningBudgets need attention. Total spent: Rs${totalSpent.toStringAsFixed(2)} of Rs${totalBudget.toStringAsFixed(2)}',
        htmlFormatBigText: true,
        contentTitle: '📊 Daily Budget Summary',
        htmlFormatContentTitle: true,
      ),
      category: AndroidNotificationCategory.reminder,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
      categoryIdentifier: 'daily_reminder',
    );

    NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    final String title = '📊 Daily Budget Summary';
    final String body = 'You have $totalBudgets active budgets. '
        '$exceededBudgets exceeded, $warningBudgets need attention.';

    await _notificationsPlugin.show(
      999999, // Fixed ID for daily reminder
      title,
      body,
      platformChannelSpecifics,
      payload: 'daily_reminder',
    );

    debugPrint("Daily reminder notification sent");
  }

  /// Schedule daily reminder notification
  static Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Cancel any existing daily reminder
    await _notificationsPlugin.cancel(999999);

    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);

    // If the scheduled time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      _dailyRemindersChannelId,
      'Daily Reminders',
      channelDescription: 'Daily budget check reminders',
      importance: Importance.low,
      priority: Priority.low,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _notificationsPlugin.zonedSchedule(
      999999,
      '📊 Daily Budget Check',
      'Time to review your budget status',
      tz.TZDateTime.from(scheduledDate, tz.local),
      platformChannelSpecifics,
      payload: 'daily_reminder',
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    debugPrint(
        "Daily reminder scheduled for ${scheduledDate.hour}:${scheduledDate.minute}");
  }

  /// Cancel daily reminder
  static Future<void> cancelDailyReminder() async {
    await _notificationsPlugin.cancel(999999);
    debugPrint("Daily reminder cancelled");
  }

  /// Cancel all notifications for a specific category
  static Future<void> cancelCategoryNotification(String categoryName) async {
    final exceededId = _generateNotificationId(categoryName, 'exceeded');
    final warningId = _generateNotificationId(categoryName, 'warning');

    await _notificationsPlugin.cancel(exceededId);
    await _notificationsPlugin.cancel(warningId);

    debugPrint("Cancelled notifications for category: $categoryName");
  }

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
    debugPrint("All notifications cancelled");
  }

  /// Generate unique notification ID based on category and type
  static int _generateNotificationId(String categoryName, String type) {
    final combined = '$categoryName-$type';
    return combined.hashCode.abs() % 2147483647; // Ensure positive 32-bit int
  }

  /// Log notification to Firestore for analytics
  static Future<void> _logNotification(
    String type,
    String categoryName,
    double spentAmount,
    double budgetAmount,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email');
      if (email == null) return;

      await FirebaseFirestore.instance.collection('notification_logs').add({
        'email': email,
        'type': type,
        'category_name': categoryName,
        'spent_amount': spentAmount,
        'budget_amount': budgetAmount,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error logging notification: $e');
    }
  }

  /// Check if notifications are enabled globally
  static Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? true;
  }

  /// Check if budget alerts are enabled
  static Future<bool> isBudgetAlertsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('budget_alerts_enabled') ?? true;
  }

  /// Check if budget warnings are enabled
  static Future<bool> isBudgetWarningsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('budget_warnings_enabled') ?? true;
  }

  /// Check if daily reminders are enabled
  static Future<bool> isDailyRemindersEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('daily_reminders_enabled') ?? false;
  }

  /// Set notification preferences
  static Future<void> setNotificationPreferences({
    bool? notificationsEnabled,
    bool? budgetAlertsEnabled,
    bool? budgetWarningsEnabled,
    bool? dailyRemindersEnabled,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (notificationsEnabled != null) {
      await prefs.setBool('notifications_enabled', notificationsEnabled);
    }
    if (budgetAlertsEnabled != null) {
      await prefs.setBool('budget_alerts_enabled', budgetAlertsEnabled);
    }
    if (budgetWarningsEnabled != null) {
      await prefs.setBool('budget_warnings_enabled', budgetWarningsEnabled);
    }
    if (dailyRemindersEnabled != null) {
      await prefs.setBool('daily_reminders_enabled', dailyRemindersEnabled);

      // Cancel daily reminder if disabled
      if (!dailyRemindersEnabled) {
        await cancelDailyReminder();
      }
    }
  }

  /// Get notification preferences
  static Future<Map<String, bool>> getNotificationPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'notifications_enabled': prefs.getBool('notifications_enabled') ?? true,
      'budget_alerts_enabled': prefs.getBool('budget_alerts_enabled') ?? true,
      'budget_warnings_enabled':
          prefs.getBool('budget_warnings_enabled') ?? true,
      'daily_reminders_enabled':
          prefs.getBool('daily_reminders_enabled') ?? false,
    };
  }

  /// Get pending notifications
  static Future<List<PendingNotificationRequest>>
      getPendingNotifications() async {
    return await _notificationsPlugin.pendingNotificationRequests();
  }

  /// Check if app has notification permissions
  static Future<bool> hasNotificationPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.notification.status;
      return status == PermissionStatus.granted;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final result = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: false, badge: false, sound: false);
      return result == true;
    }
    return true;
  }

  /// Open app notification settings
  static Future<void> openNotificationSettings() async {
    await openAppSettings();
  }
}
