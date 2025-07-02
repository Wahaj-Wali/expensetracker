import 'package:ExpenseTracker/Services/TransactionController.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:developer';

class SplitBillService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TransactionController _transactionController = TransactionController();

  // Add a new split bill
  Future<Map<String, dynamic>> addSplitBill({
    required String accountName,
    required double totalAmount,
    required String categoryName,
    required List<Map<String, dynamic>> participants,
    required String description,
    String? notes,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email');
      if (email == null) {
        return {
          'success': false,
          'message': "User email not found in preferences.",
        };
      }

      var uuid = const Uuid();
      String splitBillId = uuid.v4();
      String transactionId = uuid.v4();

      // Calculate user's share
      double numberOfParticipants = participants.length + 1; // +1 for the user
      double userShare = totalAmount / numberOfParticipants;

      // First process the expense transaction
      Map<String, dynamic> transactionResult =
          await _transactionController.processTransaction(
        amount: userShare, // Only deduct user's share
        accountName: accountName,
        transactionType: 'Expense',
      );

      if (!transactionResult['success']) {
        return transactionResult;
      }

      // Create the split bill document
      await _firestore.collection('split_bills').doc(splitBillId).set({
        'split_bill_id': splitBillId,
        'transaction_id': transactionId,
        'email': email,
        'total_amount': totalAmount,
        'user_share': userShare,
        'category_name': categoryName,
        'account_name': accountName,
        'description': description,
        'notes': notes,
        'participants': participants,
        'status': 'pending', // pending, settled
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Create the expense transaction record
      await _firestore.collection('transactions').doc(transactionId).set({
        'transaction_id': transactionId,
        'split_bill_id': splitBillId,
        'email': email,
        'transaction_type': 'Expense',
        'category_name': categoryName,
        'account_name': accountName,
        'amount': userShare,
        'description': "Split bill: $description",
        'is_split_bill': true,
        'created_at': FieldValue.serverTimestamp(),
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });

      return {
        'success': true,
        'message': 'Split bill created successfully',
        'splitBillId': splitBillId,
        'transactionId': transactionId,
      };
    } catch (e) {
      log("Error creating split bill: $e");
      return {
        'success': false,
        'message': "Failed to create split bill: ${e.toString()}",
      };
    }
  }

  // Get all split bills for current user
  Future<List<Map<String, dynamic>>> getAllSplitBills() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email');
      if (email == null) {
        throw Exception("User email not found in preferences.");
      }

      QuerySnapshot querySnapshot = await _firestore
          .collection('split_bills')
          .where('email', isEqualTo: email)
          .orderBy('created_at', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      log("Error getting split bills: $e");
      return [];
    }
  }

  // Mark split bill as settled
  Future<bool> markSplitBillAsSettled(String splitBillId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email');
      if (email == null) {
        throw Exception("User email not found in preferences.");
      }

      await _firestore.collection('split_bills').doc(splitBillId).update({
        'status': 'settled',
        'updated_at': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      log("Error marking split bill as settled: $e");
      return false;
    }
  }
}
