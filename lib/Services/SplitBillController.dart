import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:developer';

class SplitBillService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  /// Creates a split bill and logs it as an expense transaction
  Future<Map<String, dynamic>> createSplitBill({
    required String title,
    required double totalAmount,
    required String accountName,
    required String categoryId,
    required List<Map<String, dynamic>>
        participants, // [{name, email?, amount, isPaid}]
    String? description,
    String? imageUrl,
  }) async {
    try {
      // Get current user email
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email');
      if (email == null) {
        return {
          'success': false,
          'message': "User email not found in preferences.",
        };
      }

      // Validate participants
      if (participants.isEmpty) {
        return {
          'success': false,
          'message': "At least one participant is required.",
        };
      }

      // Calculate total split amount
      double totalSplitAmount = participants.fold(
          0.0, (sum, participant) => sum + (participant['amount'] as double));

      if (totalSplitAmount != totalAmount) {
        return {
          'success': false,
          'message': "Split amounts don't match the total amount.",
        };
      }

      // Generate unique IDs
      String splitBillId = _uuid.v4();
      String transactionId = _uuid.v4();

      // Execute Firestore transaction to ensure atomicity
      await _firestore.runTransaction((transaction) async {
        // 1. Check if account exists and get current balance
        QuerySnapshot accountSnapshot = await _firestore
            .collection('accounts')
            .where('email', isEqualTo: email)
            .where('account_name', isEqualTo: accountName)
            .limit(1)
            .get();

        if (accountSnapshot.docs.isEmpty) {
          throw Exception("Account '$accountName' not found.");
        }

        DocumentReference accountRef = accountSnapshot.docs.first.reference;
        var currentBalance = accountSnapshot.docs.first['balance'];

        // Ensure currentBalance is a double
        double currentBalanceDouble = currentBalance is double
            ? currentBalance
            : double.tryParse(currentBalance.toString()) ?? 0.0;

        // Check sufficient funds
        if (currentBalanceDouble < totalAmount) {
          throw Exception("Insufficient funds in account '$accountName'.");
        }

        // 2. Create split bill document
        DocumentReference splitBillRef =
            _firestore.collection('split_bills').doc(splitBillId);

        transaction.set(splitBillRef, {
          'split_bill_id': splitBillId,
          'title': title,
          'description': description ?? '',
          'total_amount': totalAmount,
          'account_name': accountName,
          'category_id': categoryId,
          'image_url': imageUrl,
          'creator_email': email,
          'participants': participants
              .map((p) => {
                    'name': p['name'],
                    'email': p['email'],
                    'amount': p['amount'],
                    'is_paid': p['isPaid'] ?? false,
                    'paid_at': p['isPaid'] == true
                        ? DateTime.now().toUtc().toIso8601String()
                        : null,
                  })
              .toList(),
          'total_paid': participants
              .where((p) => p['isPaid'] == true)
              .fold(0.0, (sum, p) => sum + (p['amount'] as double)),
          'is_settled': participants.every((p) => p['isPaid'] == true),
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
          'status': 'active', // active, settled, cancelled
        });

        // 3. Create expense transaction
        DocumentReference transactionRef =
            _firestore.collection('transactions').doc(transactionId);

        transaction.set(transactionRef, {
          'transaction_id': transactionId,
          'amount': totalAmount,
          'account_name': accountName,
          'transaction_type': 'Expense',
          'category_id': categoryId,
          'description':
              'Split Bill: $title${description != null && description.isNotEmpty ? ' - $description' : ''}',
          'split_bill_id': splitBillId, // Link to split bill
          'is_split_bill': true,
          'email': email,
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });

        // 4. Update account balance
        double updatedBalance = currentBalanceDouble - totalAmount;
        transaction.update(accountRef, {
          'balance': updatedBalance,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });
      });

      return {
        'success': true,
        'message': "Split bill created successfully.",
        'split_bill_id': splitBillId,
        'transaction_id': transactionId,
      };
    } catch (e) {
      log("Error creating split bill: $e");
      return {
        'success': false,
        'message': "Failed to create split bill: ${e.toString()}",
      };
    }
  }

  /// Get all split bills for current user
  Future<List<Map<String, dynamic>>> getAllSplitBills() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email');
      if (email == null) {
        throw Exception("User email not found in preferences.");
      }

      QuerySnapshot querySnapshot = await _firestore
          .collection('split_bills')
          .where('creator_email', isEqualTo: email)
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

  /// Get split bill by ID
  Future<Map<String, dynamic>?> getSplitBillById(String splitBillId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email');
      if (email == null) {
        throw Exception("User email not found in preferences.");
      }

      DocumentSnapshot doc =
          await _firestore.collection('split_bills').doc(splitBillId).get();

      if (!doc.exists) {
        return null;
      }

      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      // Check if current user is the creator
      if (data['creator_email'] != email) {
        throw Exception("Unauthorized access to split bill.");
      }

      return data;
    } catch (e) {
      log("Error getting split bill by ID: $e");
      return null;
    }
  }

  /// Mark participant as paid
  Future<Map<String, dynamic>> markParticipantAsPaid({
    required String splitBillId,
    required String participantName,
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

      await _firestore.runTransaction((transaction) async {
        DocumentReference splitBillRef =
            _firestore.collection('split_bills').doc(splitBillId);

        DocumentSnapshot splitBillDoc = await transaction.get(splitBillRef);
        if (!splitBillDoc.exists) {
          throw Exception("Split bill not found.");
        }

        Map<String, dynamic> data = splitBillDoc.data() as Map<String, dynamic>;

        // Check authorization
        if (data['creator_email'] != email) {
          throw Exception("Unauthorized access to split bill.");
        }

        List<dynamic> participants = List.from(data['participants']);
        bool participantFound = false;

        // Update participant status
        for (int i = 0; i < participants.length; i++) {
          if (participants[i]['name'] == participantName) {
            participants[i]['is_paid'] = true;
            participants[i]['paid_at'] =
                DateTime.now().toUtc().toIso8601String();
            participantFound = true;
            break;
          }
        }

        if (!participantFound) {
          throw Exception("Participant not found.");
        }

        // Calculate total paid amount
        double totalPaid = participants
            .where((p) => p['is_paid'] == true)
            .fold(0.0, (sum, p) => sum + (p['amount'] as double));

        // Check if bill is fully settled
        bool isSettled = participants.every((p) => p['is_paid'] == true);

        // Update split bill
        transaction.update(splitBillRef, {
          'participants': participants,
          'total_paid': totalPaid,
          'is_settled': isSettled,
          'status': isSettled ? 'settled' : 'active',
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });
      });

      return {
        'success': true,
        'message': "Participant marked as paid successfully.",
      };
    } catch (e) {
      log("Error marking participant as paid: $e");
      return {
        'success': false,
        'message': "Failed to mark participant as paid: ${e.toString()}",
      };
    }
  }

  /// Delete split bill and reverse transaction
  Future<Map<String, dynamic>> deleteSplitBill(String splitBillId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email');
      if (email == null) {
        return {
          'success': false,
          'message': "User email not found in preferences.",
        };
      }

      await _firestore.runTransaction((transaction) async {
        // Get split bill data
        DocumentReference splitBillRef =
            _firestore.collection('split_bills').doc(splitBillId);

        DocumentSnapshot splitBillDoc = await transaction.get(splitBillRef);
        if (!splitBillDoc.exists) {
          throw Exception("Split bill not found.");
        }

        Map<String, dynamic> splitBillData =
            splitBillDoc.data() as Map<String, dynamic>;

        // Check authorization
        if (splitBillData['creator_email'] != email) {
          throw Exception("Unauthorized access to split bill.");
        }

        String accountName = splitBillData['account_name'];
        double totalAmount = splitBillData['total_amount'].toDouble();

        // Find and delete related transaction
        QuerySnapshot transactionQuery = await _firestore
            .collection('transactions')
            .where('split_bill_id', isEqualTo: splitBillId)
            .limit(1)
            .get();

        if (transactionQuery.docs.isNotEmpty) {
          transaction.delete(transactionQuery.docs.first.reference);
        }

        // Get account and restore balance
        QuerySnapshot accountSnapshot = await _firestore
            .collection('accounts')
            .where('email', isEqualTo: email)
            .where('account_name', isEqualTo: accountName)
            .limit(1)
            .get();

        if (accountSnapshot.docs.isNotEmpty) {
          DocumentReference accountRef = accountSnapshot.docs.first.reference;
          var currentBalance = accountSnapshot.docs.first['balance'];

          double currentBalanceDouble = currentBalance is double
              ? currentBalance
              : double.tryParse(currentBalance.toString()) ?? 0.0;

          double updatedBalance = currentBalanceDouble + totalAmount;

          transaction.update(accountRef, {
            'balance': updatedBalance,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          });
        }

        // Delete split bill
        transaction.delete(splitBillRef);
      });

      return {
        'success': true,
        'message': "Split bill deleted successfully.",
      };
    } catch (e) {
      log("Error deleting split bill: $e");
      return {
        'success': false,
        'message': "Failed to delete split bill: ${e.toString()}",
      };
    }
  }

  /// Get split bill statistics
  Future<Map<String, dynamic>> getSplitBillStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email');
      if (email == null) {
        throw Exception("User email not found in preferences.");
      }

      QuerySnapshot querySnapshot = await _firestore
          .collection('split_bills')
          .where('creator_email', isEqualTo: email)
          .get();

      List<Map<String, dynamic>> splitBills = querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      int totalBills = splitBills.length;
      int settledBills =
          splitBills.where((bill) => bill['is_settled'] == true).length;
      int activeBills =
          splitBills.where((bill) => bill['status'] == 'active').length;

      double totalAmount = splitBills.fold(
          0.0, (sum, bill) => sum + (bill['total_amount'] as num).toDouble());

      double totalPaidAmount = splitBills.fold(
          0.0, (sum, bill) => sum + (bill['total_paid'] as num).toDouble());

      double pendingAmount = totalAmount - totalPaidAmount;

      return {
        'total_bills': totalBills,
        'settled_bills': settledBills,
        'active_bills': activeBills,
        'total_amount': totalAmount,
        'total_paid_amount': totalPaidAmount,
        'pending_amount': pendingAmount,
        'settlement_rate':
            totalBills > 0 ? (settledBills / totalBills * 100) : 0.0,
      };
    } catch (e) {
      log("Error getting split bill stats: $e");
      return {
        'total_bills': 0,
        'settled_bills': 0,
        'active_bills': 0,
        'total_amount': 0.0,
        'total_paid_amount': 0.0,
        'pending_amount': 0.0,
        'settlement_rate': 0.0,
      };
    }
  }

  /// Get recent split bills (last 10)
  Future<List<Map<String, dynamic>>> getRecentSplitBills() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email');
      if (email == null) {
        throw Exception("User email not found in preferences.");
      }

      QuerySnapshot querySnapshot = await _firestore
          .collection('split_bills')
          .where('creator_email', isEqualTo: email)
          .orderBy('created_at', descending: true)
          .limit(10)
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      log("Error getting recent split bills: $e");
      return [];
    }
  }

  /// Search split bills by title or description
  Future<List<Map<String, dynamic>>> searchSplitBills(String query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email');
      if (email == null) {
        throw Exception("User email not found in preferences.");
      }

      QuerySnapshot querySnapshot = await _firestore
          .collection('split_bills')
          .where('creator_email', isEqualTo: email)
          .get();

      List<Map<String, dynamic>> allBills = querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      // Filter by title or description containing the query (case-insensitive)
      String lowerQuery = query.toLowerCase();
      return allBills.where((bill) {
        String title = (bill['title'] ?? '').toString().toLowerCase();
        String description =
            (bill['description'] ?? '').toString().toLowerCase();
        return title.contains(lowerQuery) || description.contains(lowerQuery);
      }).toList();
    } catch (e) {
      log("Error searching split bills: $e");
      return [];
    }
  }

  /// Get split bills by status
  Future<List<Map<String, dynamic>>> getSplitBillsByStatus(
      String status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email');
      if (email == null) {
        throw Exception("User email not found in preferences.");
      }

      QuerySnapshot querySnapshot = await _firestore
          .collection('split_bills')
          .where('creator_email', isEqualTo: email)
          .where('status', isEqualTo: status)
          .orderBy('created_at', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      log("Error getting split bills by status: $e");
      return [];
    }
  }
}
