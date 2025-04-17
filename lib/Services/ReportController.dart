// ReportController.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:csv/csv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

class ReportController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generate CSV report for a specific year
  Future<Map<String, dynamic>> generateAnnualReport(int year) async {
    try {
      // Get user email
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email');

      if (email == null) {
        return {
          'success': false,
          'message': 'User email not found in preferences.',
        };
      }

      // Define date range for the year
      final startDate = DateTime(year, 1, 1);
      final endDate = DateTime(year, 12, 31, 23, 59, 59);

      // Fetch transactions
      final transactions = await _fetchTransactionsForPeriod(
        email: email,
        startDate: startDate,
        endDate: endDate,
      );

      if (transactions.isEmpty) {
        return {
          'success': false,
          'message': 'No transactions found for $year.',
        };
      }

      // Generate and save CSV file
      final filePath = await _generateCSVFile(transactions, year);

      return {
        'success': true,
        'message': 'Annual report generated successfully.',
        'filePath': filePath,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error generating report: ${e.toString()}',
      };
    }
  }

  // Fetch transactions for a specific time period
  Future<List<Map<String, dynamic>>> _fetchTransactionsForPeriod({
    required String email,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final querySnapshot = await _firestore
        .collection('transactions')
        .where('email', isEqualTo: email)
        .where('timestamp', isGreaterThanOrEqualTo: startDate)
        .where('timestamp', isLessThanOrEqualTo: endDate)
        .orderBy('timestamp', descending: false)
        .get();

    return querySnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  // Generate CSV file from transaction data
  Future<String> _generateCSVFile(
      List<Map<String, dynamic>> transactions, int year) async {
    // Define headers
    List<List<dynamic>> csvData = [
      [
        'Date',
        'Category',
        'Description',
        'Amount',
        'Transaction Type',
        'Account'
      ]
    ];

    // Format data
    final dateFormat = DateFormat('yyyy-MM-dd');

    for (var transaction in transactions) {
      DateTime date = (transaction['timestamp'] as Timestamp).toDate();
      String formattedDate = dateFormat.format(date);

      // Add transaction row
      csvData.add([
        formattedDate,
        transaction['category_name'] ?? 'No Category',
        transaction['description'] ?? '',
        transaction['amount'] ?? 0.0,
        transaction['transaction_type'] ?? '',
        transaction['account_name'] ?? '',
      ]);
    }

    // Convert to CSV string
    String csv = const ListToCsvConverter().convert(csvData);

    // Get local document directory
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/annual_report_$year.csv';
    final file = File(path);

    // Write to file
    await file.writeAsString(csv);

    return path;
  }

  // Share generated report
  Future<bool> shareReport(String filePath) async {
    try {
      final result = await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Annual Transaction Report',
      );

      return result.status == ShareResultStatus.success;
    } catch (e) {
      print('Error sharing report: $e');
      return false;
    }
  }

  // Save report to downloads folder (Android)
  // Updated method in ReportController.dart
  Future<Map<String, dynamic>> saveReportToDownloads(String filePath) async {
    try {
      if (Platform.isAndroid) {
        // Check Android version to handle permissions appropriately
        if (await _requestStoragePermission() == false) {
          return {
            'success': false,
            'message':
                'Storage permission denied. Please grant permission in app settings.',
          };
        }

        // Get the file name from path
        final fileName = filePath.split('/').last;

        // For Android 10 (API 29) and above, use MediaStore API
        if (await _isAndroid10OrAbove()) {
          final result = await _saveUsingMediaStore(filePath, fileName);
          return result;
        } else {
          // Older Android versions use direct file access
          final downloadsDir = Directory('/storage/emulated/0/Download');
          final downloadFilePath = '${downloadsDir.path}/$fileName';

          await File(filePath).copy(downloadFilePath);

          return {
            'success': true,
            'message': 'Report saved to Downloads folder',
            'filePath': downloadFilePath,
          };
        }
      } else if (Platform.isIOS) {
        // For iOS, we can only share the file
        final result = await shareReport(filePath);
        return {
          'success': result,
          'message':
              result ? 'Report shared successfully' : 'Failed to share report',
        };
      } else {
        return {
          'success': false,
          'message': 'Saving to Downloads is only supported on Android.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error saving report: ${e.toString()}',
      };
    }
  }

// Helper method to request storage permission
  Future<bool> _requestStoragePermission() async {
    // For Android 13+ (API 33+), use more specific permissions
    if (await _isAndroid13OrAbove()) {
      // Use READ_MEDIA_IMAGES permission for Android 13+
      var status = await Permission.photos.status;
      if (!status.isGranted) {
        status = await Permission.photos.request();
      }
      return status.isGranted;
    }
    // For Android 10-12
    else if (await _isAndroid10OrAbove()) {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }
      return status.isGranted;
    }
    // For Android 9 and below
    else {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }
      return status.isGranted;
    }
  }

// Check if device is running Android 10 (API 29) or above
  Future<bool> _isAndroid10OrAbove() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      return androidInfo.version.sdkInt >= 29;
    }
    return false;
  }

// Check if device is running Android 13 (API 33) or above
  Future<bool> _isAndroid13OrAbove() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      return androidInfo.version.sdkInt >= 33;
    }
    return false;
  }

// Save file using MediaStore API (for Android 10+)
  Future<Map<String, dynamic>> _saveUsingMediaStore(
      String sourceFilePath, String fileName) async {
    try {
      // Import required packages
      // ignore: implementation_imports
      final contentValues = <String, dynamic>{
        'relative_path': 'Download',
        'display_name': fileName,
        'mime_type': 'text/csv',
      };

      // Use platform channel to call Android's MediaStore API
      // This is a simplified example - you might need to implement
      // the platform-specific code for this to work
      final methodChannel =
          MethodChannel('com.yourdomain.expensetracker/file_operations');
      final result = await methodChannel.invokeMethod(
        'saveFile',
        {
          'values': contentValues,
          'filePath': sourceFilePath,
        },
      );

      if (result != null && result is String) {
        return {
          'success': true,
          'message': 'Report saved to Downloads folder',
          'filePath': result,
        };
      } else {
        // Fallback to sharing if MediaStore API fails
        final shared = await shareReport(sourceFilePath);
        return {
          'success': shared,
          'message': shared
              ? 'Report shared successfully (MediaStore API not available)'
              : 'Failed to save report',
        };
      }
    } catch (e) {
      print('Error using MediaStore: $e');
      // Fallback to sharing if MediaStore API fails
      final shared = await shareReport(sourceFilePath);
      return {
        'success': shared,
        'message': shared
            ? 'Report shared successfully (fallback)'
            : 'Failed to save report',
        'error': e.toString(),
      };
    }
  }
}
