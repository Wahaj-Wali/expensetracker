// Enhanced ReportController.dart with Fixed Save to Downloads and Sales Tax Integration
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:csv/csv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
// Import your SalesTaxController
import 'SalesTaxController.dart';

class ReportController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SalesTaxController _salesTaxController = SalesTaxController();

  // Generate CSV report for a specific year with sales tax information
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

      // Calculate sales tax summary
      final salesTaxSummary =
          await _salesTaxController.calculateYearlySalesTax(year);

      // Generate and save CSV file with sales tax information
      final filePath =
          await _generateEnhancedCSVFile(transactions, year, salesTaxSummary);

      return {
        'success': true,
        'message':
            'Annual report with sales tax information generated successfully.',
        'filePath': filePath,
        'salesTaxSummary': salesTaxSummary,
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

  // Generate enhanced CSV file with sales tax information
  Future<String> _generateEnhancedCSVFile(
      List<Map<String, dynamic>> transactions,
      int year,
      Map<String, dynamic> salesTaxSummary) async {
    List<List<dynamic>> csvData = [];
    final dateFormat = DateFormat('yyyy-MM-dd');

    // Add title and summary information
    csvData.add(['ANNUAL FINANCIAL REPORT - $year']);
    csvData.add(['Generated on: ${dateFormat.format(DateTime.now())}']);
    csvData.add([]);

    // Add sales tax summary section
    csvData.add(['SALES TAX SUMMARY']);
    csvData.add([
      'Total Sales Tax:',
      'PKR ${(salesTaxSummary['totalSalesTax'] ?? 0.0).toStringAsFixed(2)}'
    ]);
    csvData.add([
      'Total Expense Amount:',
      'PKR ${(salesTaxSummary['totalExpenseAmount'] ?? 0.0).toStringAsFixed(2)}'
    ]);
    csvData.add([
      'Total Taxable Amount:',
      'PKR ${(salesTaxSummary['totalTaxableAmount'] ?? 0.0).toStringAsFixed(2)}'
    ]);
    csvData.add([
      'Average Tax Rate:',
      '${(salesTaxSummary['averageTaxRate'] ?? 0.0).toStringAsFixed(2)}%'
    ]);
    csvData.add(
        ['Transaction Count:', '${salesTaxSummary['transactionCount'] ?? 0}']);
    csvData.add([]);

    // Add category-wise tax breakdown
    if (salesTaxSummary['categoryWiseTax'] != null) {
      csvData.add(['CATEGORY-WISE TAX BREAKDOWN']);
      csvData.add(['Category', 'Total Amount', 'Total Tax']);

      final categoryWiseTax =
          salesTaxSummary['categoryWiseTax'] as Map<String, double>;
      final categoryWiseAmount =
          salesTaxSummary['categoryWiseAmount'] as Map<String, double>;

      for (String category in categoryWiseTax.keys) {
        csvData.add([
          category,
          'PKR ${(categoryWiseAmount[category] ?? 0.0).toStringAsFixed(2)}',
          'PKR ${(categoryWiseTax[category] ?? 0.0).toStringAsFixed(2)}'
        ]);
      }
      csvData.add([]);
    }

    // Add detailed transaction data
    csvData.add(['DETAILED TRANSACTION RECORDS']);
    csvData.add([
      'Date',
      'Category',
      'Description',
      'Amount',
      'Transaction Type',
      'Account',
      'Tax Rate',
      'Sales Tax',
      'Tax Status'
    ]);

    // Format transaction data with sales tax information
    for (var transaction in transactions) {
      DateTime date = (transaction['timestamp'] as Timestamp).toDate();
      String formattedDate = dateFormat.format(date);
      String categoryName = transaction['category_name'] ?? 'No Category';
      double amount = transaction['amount'] is String
          ? double.tryParse(transaction['amount']) ?? 0.0
          : (transaction['amount'] ?? 0.0).toDouble();
      String transactionType = transaction['transaction_type'] ?? '';

      // Calculate sales tax for this transaction (only for expenses)
      double salesTax = 0.0;
      double taxRate = 0.0;
      String taxStatus = 'N/A';

      if (transactionType == 'Expense') {
        taxRate = await _salesTaxController.getSalesTaxRate(categoryName);
        salesTax = await _salesTaxController.calculateSalesTaxForTransaction(
            categoryName, amount);
        taxStatus = await _salesTaxController.isCategoryTaxExempt(categoryName)
            ? 'Tax Exempt'
            : 'Taxable';
      }

      csvData.add([
        formattedDate,
        categoryName,
        transaction['description'] ?? '',
        'PKR ${amount.toStringAsFixed(2)}',
        transactionType,
        transaction['account_name'] ?? '',
        transactionType == 'Expense'
            ? '${(taxRate * 100).toStringAsFixed(1)}%'
            : 'N/A',
        transactionType == 'Expense'
            ? 'PKR ${salesTax.toStringAsFixed(2)}'
            : 'N/A',
        taxStatus
      ]);
    }

    // Convert to CSV string
    String csv = const ListToCsvConverter().convert(csvData);

    // Get local document directory
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/annual_report_with_tax_$year.csv';
    final file = File(path);

    // Write to file
    await file.writeAsString(csv);

    return path;
  }

  // Generate monthly report with sales tax (new method)
  Future<Map<String, dynamic>> generateMonthlyReport(
      int year, int month) async {
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

      // Define date range for the month
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

      // Fetch transactions
      final transactions = await _fetchTransactionsForPeriod(
        email: email,
        startDate: startDate,
        endDate: endDate,
      );

      if (transactions.isEmpty) {
        return {
          'success': false,
          'message':
              'No transactions found for ${DateFormat('MMMM yyyy').format(startDate)}.',
        };
      }

      // Calculate sales tax summary
      final salesTaxSummary =
          await _salesTaxController.calculateMonthlySalesTax(year, month);

      // Generate and save CSV file with sales tax information
      final filePath = await _generateMonthlyCSVFile(
          transactions, year, month, salesTaxSummary);

      return {
        'success': true,
        'message':
            'Monthly report with sales tax information generated successfully.',
        'filePath': filePath,
        'salesTaxSummary': salesTaxSummary,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error generating monthly report: ${e.toString()}',
      };
    }
  }

  // Generate monthly CSV file
  Future<String> _generateMonthlyCSVFile(
      List<Map<String, dynamic>> transactions,
      int year,
      int month,
      Map<String, dynamic> salesTaxSummary) async {
    List<List<dynamic>> csvData = [];
    final dateFormat = DateFormat('yyyy-MM-dd');
    final monthName = DateFormat('MMMM yyyy').format(DateTime(year, month));

    // Add title and summary information
    csvData.add(['MONTHLY FINANCIAL REPORT - $monthName']);
    csvData.add(['Generated on: ${dateFormat.format(DateTime.now())}']);
    csvData.add([]);

    // Add sales tax summary section
    csvData.add(['SALES TAX SUMMARY']);
    csvData.add([
      'Total Sales Tax:',
      'PKR ${(salesTaxSummary['totalSalesTax'] ?? 0.0).toStringAsFixed(2)}'
    ]);
    csvData.add([
      'Total Expense Amount:',
      'PKR ${(salesTaxSummary['totalExpenseAmount'] ?? 0.0).toStringAsFixed(2)}'
    ]);
    csvData.add([
      'Total Taxable Amount:',
      'PKR ${(salesTaxSummary['totalTaxableAmount'] ?? 0.0).toStringAsFixed(2)}'
    ]);
    csvData.add([
      'Average Tax Rate:',
      '${(salesTaxSummary['averageTaxRate'] ?? 0.0).toStringAsFixed(2)}%'
    ]);
    csvData.add(
        ['Transaction Count:', '${salesTaxSummary['transactionCount'] ?? 0}']);
    csvData.add([]);

    // Add category-wise tax breakdown
    if (salesTaxSummary['categoryWiseTax'] != null) {
      csvData.add(['CATEGORY-WISE TAX BREAKDOWN']);
      csvData.add(['Category', 'Total Amount', 'Total Tax']);

      final categoryWiseTax =
          salesTaxSummary['categoryWiseTax'] as Map<String, double>;
      final categoryWiseAmount =
          salesTaxSummary['categoryWiseAmount'] as Map<String, double>;

      for (String category in categoryWiseTax.keys) {
        csvData.add([
          category,
          'PKR ${(categoryWiseAmount[category] ?? 0.0).toStringAsFixed(2)}',
          'PKR ${(categoryWiseTax[category] ?? 0.0).toStringAsFixed(2)}'
        ]);
      }
      csvData.add([]);
    }

    // Add detailed transaction data
    csvData.add(['DETAILED TRANSACTION RECORDS']);
    csvData.add([
      'Date',
      'Category',
      'Description',
      'Amount',
      'Transaction Type',
      'Account',
      'Tax Rate',
      'Sales Tax',
      'Tax Status'
    ]);

    // Format transaction data with sales tax information
    for (var transaction in transactions) {
      DateTime date = (transaction['timestamp'] as Timestamp).toDate();
      String formattedDate = dateFormat.format(date);
      String categoryName = transaction['category_name'] ?? 'No Category';
      double amount = transaction['amount'] is String
          ? double.tryParse(transaction['amount']) ?? 0.0
          : (transaction['amount'] ?? 0.0).toDouble();
      String transactionType = transaction['transaction_type'] ?? '';

      // Calculate sales tax for this transaction (only for expenses)
      double salesTax = 0.0;
      double taxRate = 0.0;
      String taxStatus = 'N/A';

      if (transactionType == 'Expense') {
        taxRate = await _salesTaxController.getSalesTaxRate(categoryName);
        salesTax = await _salesTaxController.calculateSalesTaxForTransaction(
            categoryName, amount);
        taxStatus = await _salesTaxController.isCategoryTaxExempt(categoryName)
            ? 'Tax Exempt'
            : 'Taxable';
      }

      csvData.add([
        formattedDate,
        categoryName,
        transaction['description'] ?? '',
        'PKR ${amount.toStringAsFixed(2)}',
        transactionType,
        transaction['account_name'] ?? '',
        transactionType == 'Expense'
            ? '${(taxRate * 100).toStringAsFixed(1)}%'
            : 'N/A',
        transactionType == 'Expense'
            ? 'PKR ${salesTax.toStringAsFixed(2)}'
            : 'N/A',
        taxStatus
      ]);
    }

    // Convert to CSV string
    String csv = const ListToCsvConverter().convert(csvData);

    // Get local document directory
    final directory = await getApplicationDocumentsDirectory();
    final path =
        '${directory.path}/monthly_report_with_tax_${year}_${month.toString().padLeft(2, '0')}.csv';
    final file = File(path);

    // Write to file
    await file.writeAsString(csv);

    return path;
  }

  // Generate custom date range report with sales tax
  Future<Map<String, dynamic>> generateCustomDateRangeReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
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

      // Fetch transactions
      final transactions = await _fetchTransactionsForPeriod(
        email: email,
        startDate: startDate,
        endDate: endDate,
      );

      if (transactions.isEmpty) {
        return {
          'success': false,
          'message': 'No transactions found for the selected date range.',
        };
      }

      // Calculate sales tax summary for the date range
      final salesTaxSummary = await _salesTaxController.calculateTotalSalesTax(
        startDate: startDate,
        endDate: endDate,
      );

      // Generate and save CSV file with sales tax information
      final filePath = await _generateCustomDateRangeCSVFile(
          transactions, startDate, endDate, salesTaxSummary);

      return {
        'success': true,
        'message':
            'Custom date range report with sales tax information generated successfully.',
        'filePath': filePath,
        'salesTaxSummary': salesTaxSummary,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error generating custom date range report: ${e.toString()}',
      };
    }
  }

  // Generate custom date range CSV file
  Future<String> _generateCustomDateRangeCSVFile(
      List<Map<String, dynamic>> transactions,
      DateTime startDate,
      DateTime endDate,
      Map<String, dynamic> salesTaxSummary) async {
    List<List<dynamic>> csvData = [];
    final dateFormat = DateFormat('yyyy-MM-dd');
    final startDateStr = dateFormat.format(startDate);
    final endDateStr = dateFormat.format(endDate);

    // Add title and summary information
    csvData.add(['CUSTOM DATE RANGE FINANCIAL REPORT']);
    csvData.add(['Period: $startDateStr to $endDateStr']);
    csvData.add(['Generated on: ${dateFormat.format(DateTime.now())}']);
    csvData.add([]);

    // Add sales tax summary section
    csvData.add(['SALES TAX SUMMARY']);
    csvData.add([
      'Total Sales Tax:',
      'PKR ${(salesTaxSummary['totalSalesTax'] ?? 0.0).toStringAsFixed(2)}'
    ]);
    csvData.add([
      'Total Expense Amount:',
      'PKR ${(salesTaxSummary['totalExpenseAmount'] ?? 0.0).toStringAsFixed(2)}'
    ]);
    csvData.add([
      'Total Taxable Amount:',
      'PKR ${(salesTaxSummary['totalTaxableAmount'] ?? 0.0).toStringAsFixed(2)}'
    ]);
    csvData.add([
      'Average Tax Rate:',
      '${(salesTaxSummary['averageTaxRate'] ?? 0.0).toStringAsFixed(2)}%'
    ]);
    csvData.add(
        ['Transaction Count:', '${salesTaxSummary['transactionCount'] ?? 0}']);
    csvData.add([]);

    // Add category-wise tax breakdown
    if (salesTaxSummary['categoryWiseTax'] != null) {
      csvData.add(['CATEGORY-WISE TAX BREAKDOWN']);
      csvData.add(['Category', 'Total Amount', 'Total Tax']);

      final categoryWiseTax =
          salesTaxSummary['categoryWiseTax'] as Map<String, double>;
      final categoryWiseAmount =
          salesTaxSummary['categoryWiseAmount'] as Map<String, double>;

      for (String category in categoryWiseTax.keys) {
        csvData.add([
          category,
          'PKR ${(categoryWiseAmount[category] ?? 0.0).toStringAsFixed(2)}',
          'PKR ${(categoryWiseTax[category] ?? 0.0).toStringAsFixed(2)}'
        ]);
      }
      csvData.add([]);
    }

    // Add detailed transaction data
    csvData.add(['DETAILED TRANSACTION RECORDS']);
    csvData.add([
      'Date',
      'Category',
      'Description',
      'Amount',
      'Transaction Type',
      'Account',
      'Tax Rate',
      'Sales Tax',
      'Tax Status'
    ]);

    // Format transaction data with sales tax information
    for (var transaction in transactions) {
      DateTime date = (transaction['timestamp'] as Timestamp).toDate();
      String formattedDate = dateFormat.format(date);
      String categoryName = transaction['category_name'] ?? 'No Category';
      double amount = transaction['amount'] is String
          ? double.tryParse(transaction['amount']) ?? 0.0
          : (transaction['amount'] ?? 0.0).toDouble();
      String transactionType = transaction['transaction_type'] ?? '';

      // Calculate sales tax for this transaction (only for expenses)
      double salesTax = 0.0;
      double taxRate = 0.0;
      String taxStatus = 'N/A';

      if (transactionType == 'Expense') {
        taxRate = await _salesTaxController.getSalesTaxRate(categoryName);
        salesTax = await _salesTaxController.calculateSalesTaxForTransaction(
            categoryName, amount);
        taxStatus = await _salesTaxController.isCategoryTaxExempt(categoryName)
            ? 'Tax Exempt'
            : 'Taxable';
      }

      csvData.add([
        formattedDate,
        categoryName,
        transaction['description'] ?? '',
        'PKR ${amount.toStringAsFixed(2)}',
        transactionType,
        transaction['account_name'] ?? '',
        transactionType == 'Expense'
            ? '${(taxRate * 100).toStringAsFixed(1)}%'
            : 'N/A',
        transactionType == 'Expense'
            ? 'PKR ${salesTax.toStringAsFixed(2)}'
            : 'N/A',
        taxStatus
      ]);
    }

    // Convert to CSV string
    String csv = const ListToCsvConverter().convert(csvData);

    // Get local document directory
    final directory = await getApplicationDocumentsDirectory();
    final path =
        '${directory.path}/custom_report_with_tax_${startDateStr}_to_${endDateStr}.csv';
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
        text: 'Financial Report with Sales Tax Information',
      );

      return result.status == ShareResultStatus.success;
    } catch (e) {
      print('Error sharing report: $e');
      return false;
    }
  }

  // Save report to downloads folder (Android) - FIXED VERSION
  Future<Map<String, dynamic>> saveReportToDownloads(String filePath) async {
    try {
      if (Platform.isAndroid) {
        // Get the file name from path
        final fileName = filePath.split('/').last;

        // Request storage permission
        final hasPermission = await _requestStoragePermission();
        if (!hasPermission) {
          return {
            'success': false,
            'message': 'Storage permission required to save file to Downloads.',
          };
        }

        // Try to save to Downloads folder
        try {
          // For Android 10+ use scoped storage approach
          if (await _isAndroid10OrAbove()) {
            final result = await _saveToDownloadsScoped(filePath, fileName);
            return result;
          } else {
            // For older Android versions, use direct file access
            final downloadsDir = Directory('/storage/emulated/0/Download');
            if (!downloadsDir.existsSync()) {
              downloadsDir.createSync(recursive: true);
            }

            final downloadFilePath = '${downloadsDir.path}/$fileName';
            await File(filePath).copy(downloadFilePath);

            return {
              'success': true,
              'message': 'Report saved to Downloads folder successfully.',
              'downloadPath': downloadFilePath,
            };
          }
        } catch (e) {
          print('Error saving to Downloads: $e');
          return {
            'success': false,
            'message':
                'Failed to save to Downloads folder. Error: ${e.toString()}',
          };
        }
      } else if (Platform.isIOS) {
        // For iOS, files are saved to app's Documents directory
        // The file is already saved there, so just return success
        return {
          'success': true,
          'message':
              'Report saved to device successfully. Use Share to save to Files app.',
          'filePath': filePath,
        };
      } else {
        return {
          'success': false,
          'message': 'File saving is only supported on Android and iOS.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error saving report: ${e.toString()}',
      };
    }
  }

  // Improved method to save file to Downloads folder for Android 10+
  Future<Map<String, dynamic>> _saveToDownloadsScoped(
      String sourceFilePath, String fileName) async {
    try {
      // Use external storage directory for Android 10+
      final downloadsDir = Directory('/storage/emulated/0/Download');

      // Create Downloads directory if it doesn't exist
      if (!downloadsDir.existsSync()) {
        downloadsDir.createSync(recursive: true);
      }

      final downloadFilePath = '${downloadsDir.path}/$fileName';

      // Copy file to Downloads
      await File(sourceFilePath).copy(downloadFilePath);

      return {
        'success': true,
        'message': 'Report saved to Downloads folder successfully.',
        'downloadPath': downloadFilePath,
      };
    } catch (e) {
      print('Error saving to Downloads (scoped): $e');
      // If scoped storage fails, try alternative approach
      return await _saveToAlternativeLocation(sourceFilePath, fileName);
    }
  }

  // Alternative save location if Downloads folder access fails
  Future<Map<String, dynamic>> _saveToAlternativeLocation(
      String sourceFilePath, String fileName) async {
    try {
      // Try to save to external storage Documents folder
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        final savePath = '${externalDir.path}/$fileName';
        await File(sourceFilePath).copy(savePath);

        return {
          'success': true,
          'message':
              'Report saved to device storage successfully.\nLocation: ${externalDir.path}',
          'downloadPath': savePath,
        };
      } else {
        return {
          'success': false,
          'message':
              'Unable to access device storage. Please try sharing the report instead.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to save report to device storage.',
      };
    }
  }

  // Improved permission request method
  Future<bool> _requestStoragePermission() async {
    try {
      if (Platform.isAndroid) {
        // For Android 13+ (API 33+)
        if (await _isAndroid13OrAbove()) {
          // Android 13+ doesn't need storage permission for Downloads folder
          return true;
        }
        // For Android 10-12 (API 29-32)
        else if (await _isAndroid10OrAbove()) {
          // Check if we have storage permission
          var status = await Permission.storage.status;
          if (status.isGranted) {
            return true;
          }

          // Request permission
          status = await Permission.storage.request();
          return status.isGranted;
        }
        // For Android 9 and below (API 28 and below)
        else {
          var status = await Permission.storage.status;
          if (status.isGranted) {
            return true;
          }

          status = await Permission.storage.request();
          return status.isGranted;
        }
      }
      return false;
    } catch (e) {
      print('Error requesting storage permission: $e');
      return false;
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

  // Get sales tax summary for a specific period (utility method)
  Future<Map<String, dynamic>> getSalesTaxSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _salesTaxController.calculateTotalSalesTax(
      startDate: startDate,
      endDate: endDate,
    );
  }

  // Get tax exempt categories (utility method)
  Future<List<String>> getTaxExemptCategories() async {
    return await _salesTaxController.getTaxExemptCategories();
  }

  // Get taxable categories (utility method)
  Future<List<String>> getTaxableCategories() async {
    return await _salesTaxController.getTaxableCategories();
  }

  // Clear sales tax cache (utility method)
  void clearSalesTaxCache() {
    _salesTaxController.clearCache();
  }
}
