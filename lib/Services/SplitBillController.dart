import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:developer';

class SplitBillController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  /// Creates a new split bill
  ///
  /// [totalAmount] - The total amount of the bill
  /// [description] - Description of the bill
  /// [categoryName] - Category for the expense
  /// [accountName] - Account from which payment was made
  /// [participants] - List of participant emails
  /// [splitType] - 'equal', 'custom', or 'percentage'
  /// [customAmounts] - Map of email to amount (for custom split)
  /// [percentages] - Map of email to percentage (for percentage split)
  Future<Map<String, dynamic>> createSplitBill({
    required double totalAmount,
    required String description,
    required String categoryName,
    required String accountName,
    required List<String> participants,
    required String splitType, // 'equal', 'custom', 'percentage'
    Map<String, double>? customAmounts,
    Map<String, double>? percentages,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final creatorEmail = prefs.getString('email');

      if (creatorEmail == null) {
        return {
          'success': false,
          'message': 'User not authenticated',
        };
      }

      // Validate participants
      if (participants.isEmpty) {
        return {
          'success': false,
          'message': 'At least one participant is required',
        };
      }

      // Add creator to participants if not already included
      if (!participants.contains(creatorEmail)) {
        participants.add(creatorEmail);
      }

      // Calculate individual amounts based on split type
      Map<String, double> individualAmounts = {};

      switch (splitType) {
        case 'equal':
          double amountPerPerson = totalAmount / participants.length;
          for (String participant in participants) {
            individualAmounts[participant] = amountPerPerson;
          }
          break;

        case 'custom':
          if (customAmounts == null) {
            return {
              'success': false,
              'message': 'Custom amounts are required for custom split',
            };
          }

          double totalCustom = customAmounts.values.reduce((a, b) => a + b);
          if ((totalCustom - totalAmount).abs() > 0.01) {
            return {
              'success': false,
              'message': 'Custom amounts do not match total amount',
            };
          }

          individualAmounts = Map.from(customAmounts);
          break;

        case 'percentage':
          if (percentages == null) {
            return {
              'success': false,
              'message': 'Percentages are required for percentage split',
            };
          }

          double totalPercentage = percentages.values.reduce((a, b) => a + b);
          if ((totalPercentage - 100.0).abs() > 0.01) {
            return {
              'success': false,
              'message': 'Percentages must add up to 100%',
            };
          }

          for (String participant in participants) {
            double percentage = percentages[participant] ?? 0.0;
            individualAmounts[participant] = (totalAmount * percentage) / 100.0;
          }
          break;

        default:
          return {
            'success': false,
            'message': 'Invalid split type',
          };
      }

      // Generate unique bill ID
      String billId = _uuid.v4();

      // Create split bill document
      Map<String, dynamic> splitBillData = {
        'bill_id': billId,
        'creator_email': creatorEmail,
        'total_amount': totalAmount,
        'description': description,
        'category_name': categoryName,
        'account_name': accountName,
        'participants': participants,
        'split_type': splitType,
        'individual_amounts': individualAmounts,
        'status': 'active', // active, settled, cancelled
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      // Add split-specific data
      if (splitType == 'custom' && customAmounts != null) {
        splitBillData['custom_amounts'] = customAmounts;
      }
      if (splitType == 'percentage' && percentages != null) {
        splitBillData['percentages'] = percentages;
      }

      // Use batch to create split bill and individual settlements
      WriteBatch batch = _firestore.batch();

      // Create split bill document
      DocumentReference billRef =
          _firestore.collection('split_bills').doc(billId);
      batch.set(billRef, splitBillData);

      // Create individual settlement records
      for (String participant in participants) {
        if (participant != creatorEmail) {
          String settlementId = _uuid.v4();
          DocumentReference settlementRef =
              _firestore.collection('bill_settlements').doc(settlementId);

          batch.set(settlementRef, {
            'settlement_id': settlementId,
            'bill_id': billId,
            'payer_email': creatorEmail,
            'debtor_email': participant,
            'amount': individualAmounts[participant],
            'status': 'pending', // pending, paid, cancelled
            'created_at': FieldValue.serverTimestamp(),
            'updated_at': FieldValue.serverTimestamp(),
          });
        }
      }

      // Commit batch
      await batch.commit();

      return {
        'success': true,
        'message': 'Split bill created successfully',
        'bill_id': billId,
        'individual_amounts': individualAmounts,
      };
    } catch (e) {
      log('Error creating split bill: $e');
      return {
        'success': false,
        'message': 'Failed to create split bill: ${e.toString()}',
      };
    }
  }

  /// Get all split bills for the current user
  Future<List<Map<String, dynamic>>> getUserSplitBills({
    String? status, // Filter by status
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email');

      if (email == null) {
        return [];
      }

      Query query = _firestore
          .collection('split_bills')
          .where('participants', arrayContains: email)
          .orderBy('created_at', descending: true);

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'bill_id': data['bill_id'],
          'creator_email': data['creator_email'],
          'total_amount': data['total_amount'],
          'description': data['description'],
          'category_name': data['category_name'],
          'account_name': data['account_name'],
          'participants': List<String>.from(data['participants'] ?? []),
          'split_type': data['split_type'],
          'individual_amounts':
              Map<String, double>.from(data['individual_amounts'] ?? {}),
          'status': data['status'],
          'created_at': data['created_at'],
          'updated_at': data['updated_at'],
        };
      }).toList();
    } catch (e) {
      log('Error fetching user split bills: $e');
      return [];
    }
  }

  /// Get pending settlements for the current user (amounts they owe)
  Future<List<Map<String, dynamic>>> getUserPendingDebts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email');

      if (email == null) {
        return [];
      }

      final snapshot = await _firestore
          .collection('bill_settlements')
          .where('debtor_email', isEqualTo: email)
          .where('status', isEqualTo: 'pending')
          .orderBy('created_at', descending: true)
          .get();

      List<Map<String, dynamic>> debts = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();

        // Get bill details
        final billSnapshot = await _firestore
            .collection('split_bills')
            .doc(data['bill_id'])
            .get();

        if (billSnapshot.exists) {
          final billData = billSnapshot.data() as Map<String, dynamic>;

          debts.add({
            'settlement_id': data['settlement_id'],
            'bill_id': data['bill_id'],
            'payer_email': data['payer_email'],
            'debtor_email': data['debtor_email'],
            'amount': data['amount'],
            'status': data['status'],
            'created_at': data['created_at'],
            'bill_description': billData['description'],
            'bill_total_amount': billData['total_amount'],
            'bill_category': billData['category_name'],
          });
        }
      }

      return debts;
    } catch (e) {
      log('Error fetching user pending debts: $e');
      return [];
    }
  }

  /// Get amounts owed to the current user
  Future<List<Map<String, dynamic>>> getUserPendingCredits() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email');

      if (email == null) {
        return [];
      }

      final snapshot = await _firestore
          .collection('bill_settlements')
          .where('payer_email', isEqualTo: email)
          .where('status', isEqualTo: 'pending')
          .orderBy('created_at', descending: true)
          .get();

      List<Map<String, dynamic>> credits = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();

        // Get bill details
        final billSnapshot = await _firestore
            .collection('split_bills')
            .doc(data['bill_id'])
            .get();

        if (billSnapshot.exists) {
          final billData = billSnapshot.data() as Map<String, dynamic>;

          credits.add({
            'settlement_id': data['settlement_id'],
            'bill_id': data['bill_id'],
            'payer_email': data['payer_email'],
            'debtor_email': data['debtor_email'],
            'amount': data['amount'],
            'status': data['status'],
            'created_at': data['created_at'],
            'bill_description': billData['description'],
            'bill_total_amount': billData['total_amount'],
            'bill_category': billData['category_name'],
          });
        }
      }

      return credits;
    } catch (e) {
      log('Error fetching user pending credits: $e');
      return [];
    }
  }

  /// Mark a settlement as paid
  Future<Map<String, dynamic>> markSettlementAsPaid({
    required String settlementId,
    String? paymentMethod,
    String? paymentNote,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email');

      if (email == null) {
        return {
          'success': false,
          'message': 'User not authenticated',
        };
      }

      // Get settlement details
      final settlementSnapshot = await _firestore
          .collection('bill_settlements')
          .doc(settlementId)
          .get();

      if (!settlementSnapshot.exists) {
        return {
          'success': false,
          'message': 'Settlement not found',
        };
      }

      final settlementData = settlementSnapshot.data() as Map<String, dynamic>;

      // Verify user is authorized to mark this settlement (either payer or debtor)
      if (settlementData['payer_email'] != email &&
          settlementData['debtor_email'] != email) {
        return {
          'success': false,
          'message': 'Unauthorized to update this settlement',
        };
      }

      // Update settlement status
      Map<String, dynamic> updateData = {
        'status': 'paid',
        'updated_at': FieldValue.serverTimestamp(),
        'paid_by': email,
      };

      if (paymentMethod != null) {
        updateData['payment_method'] = paymentMethod;
      }

      if (paymentNote != null) {
        updateData['payment_note'] = paymentNote;
      }

      await _firestore
          .collection('bill_settlements')
          .doc(settlementId)
          .update(updateData);

      // Check if all settlements for this bill are paid
      await _checkAndUpdateBillStatus(settlementData['bill_id']);

      return {
        'success': true,
        'message': 'Settlement marked as paid',
      };
    } catch (e) {
      log('Error marking settlement as paid: $e');
      return {
        'success': false,
        'message': 'Failed to update settlement: ${e.toString()}',
      };
    }
  }

  /// Check if all settlements for a bill are paid and update bill status
  Future<void> _checkAndUpdateBillStatus(String billId) async {
    try {
      final settlementsSnapshot = await _firestore
          .collection('bill_settlements')
          .where('bill_id', isEqualTo: billId)
          .get();

      bool allPaid = settlementsSnapshot.docs.every((doc) {
        return doc.data()['status'] == 'paid';
      });

      if (allPaid) {
        await _firestore.collection('split_bills').doc(billId).update({
          'status': 'settled',
          'updated_at': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      log('Error checking bill status: $e');
    }
  }

  /// Cancel a split bill (only by creator)
  Future<Map<String, dynamic>> cancelSplitBill(String billId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email');

      if (email == null) {
        return {
          'success': false,
          'message': 'User not authenticated',
        };
      }

      // Get bill details
      final billSnapshot =
          await _firestore.collection('split_bills').doc(billId).get();

      if (!billSnapshot.exists) {
        return {
          'success': false,
          'message': 'Bill not found',
        };
      }

      final billData = billSnapshot.data() as Map<String, dynamic>;

      // Verify user is the creator
      if (billData['creator_email'] != email) {
        return {
          'success': false,
          'message': 'Only the bill creator can cancel the bill',
        };
      }

      // Check if bill is already settled
      if (billData['status'] == 'settled') {
        return {
          'success': false,
          'message': 'Cannot cancel a settled bill',
        };
      }

      // Use batch to update bill and all related settlements
      WriteBatch batch = _firestore.batch();

      // Update bill status
      batch.update(_firestore.collection('split_bills').doc(billId), {
        'status': 'cancelled',
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Cancel all pending settlements
      final settlementsSnapshot = await _firestore
          .collection('bill_settlements')
          .where('bill_id', isEqualTo: billId)
          .where('status', isEqualTo: 'pending')
          .get();

      for (var doc in settlementsSnapshot.docs) {
        batch.update(doc.reference, {
          'status': 'cancelled',
          'updated_at': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      return {
        'success': true,
        'message': 'Split bill cancelled successfully',
      };
    } catch (e) {
      log('Error cancelling split bill: $e');
      return {
        'success': false,
        'message': 'Failed to cancel split bill: ${e.toString()}',
      };
    }
  }

  /// Get split bill details by ID
  Future<Map<String, dynamic>?> getSplitBillDetails(String billId) async {
    try {
      final billSnapshot =
          await _firestore.collection('split_bills').doc(billId).get();

      if (!billSnapshot.exists) {
        return null;
      }

      final billData = billSnapshot.data() as Map<String, dynamic>;

      // Get all settlements for this bill
      final settlementsSnapshot = await _firestore
          .collection('bill_settlements')
          .where('bill_id', isEqualTo: billId)
          .get();

      List<Map<String, dynamic>> settlements =
          settlementsSnapshot.docs.map((doc) {
        return doc.data();
      }).toList();

      return {
        ...billData,
        'settlements': settlements,
      };
    } catch (e) {
      log('Error fetching split bill details: $e');
      return null;
    }
  }

  /// Get summary of user's split bill activity
  Future<Map<String, dynamic>> getUserSplitBillSummary() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email');

      if (email == null) {
        return {
          'total_debts': 0.0,
          'total_credits': 0.0,
          'active_bills': 0,
          'settled_bills': 0,
        };
      }

      // Get pending debts
      final debtsSnapshot = await _firestore
          .collection('bill_settlements')
          .where('debtor_email', isEqualTo: email)
          .where('status', isEqualTo: 'pending')
          .get();

      double totalDebts = 0.0;
      for (var doc in debtsSnapshot.docs) {
        totalDebts += doc.data()['amount'] ?? 0.0;
      }

      // Get pending credits
      final creditsSnapshot = await _firestore
          .collection('bill_settlements')
          .where('payer_email', isEqualTo: email)
          .where('status', isEqualTo: 'pending')
          .get();

      double totalCredits = 0.0;
      for (var doc in creditsSnapshot.docs) {
        totalCredits += doc.data()['amount'] ?? 0.0;
      }

      // Get active bills count
      final activeBillsSnapshot = await _firestore
          .collection('split_bills')
          .where('participants', arrayContains: email)
          .where('status', isEqualTo: 'active')
          .get();

      // Get settled bills count
      final settledBillsSnapshot = await _firestore
          .collection('split_bills')
          .where('participants', arrayContains: email)
          .where('status', isEqualTo: 'settled')
          .get();

      return {
        'total_debts': totalDebts,
        'total_credits': totalCredits,
        'active_bills': activeBillsSnapshot.docs.length,
        'settled_bills': settledBillsSnapshot.docs.length,
        'net_balance': totalCredits - totalDebts,
      };
    } catch (e) {
      log('Error fetching split bill summary: $e');
      return {
        'total_debts': 0.0,
        'total_credits': 0.0,
        'active_bills': 0,
        'settled_bills': 0,
        'net_balance': 0.0,
      };
    }
  }

  /// Send reminder for pending settlement
  Future<Map<String, dynamic>> sendSettlementReminder(
      String settlementId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email');

      if (email == null) {
        return {
          'success': false,
          'message': 'User not authenticated',
        };
      }

      // Get settlement details
      final settlementSnapshot = await _firestore
          .collection('bill_settlements')
          .doc(settlementId)
          .get();

      if (!settlementSnapshot.exists) {
        return {
          'success': false,
          'message': 'Settlement not found',
        };
      }

      final settlementData = settlementSnapshot.data() as Map<String, dynamic>;

      // Verify user is the payer (creditor)
      if (settlementData['payer_email'] != email) {
        return {
          'success': false,
          'message': 'Only the creditor can send reminders',
        };
      }

      // Create reminder record
      String reminderId = _uuid.v4();
      await _firestore.collection('settlement_reminders').doc(reminderId).set({
        'reminder_id': reminderId,
        'settlement_id': settlementId,
        'bill_id': settlementData['bill_id'],
        'from_email': email,
        'to_email': settlementData['debtor_email'],
        'amount': settlementData['amount'],
        'sent_at': FieldValue.serverTimestamp(),
        'status': 'sent',
      });

      return {
        'success': true,
        'message': 'Reminder sent successfully',
      };
    } catch (e) {
      log('Error sending settlement reminder: $e');
      return {
        'success': false,
        'message': 'Failed to send reminder: ${e.toString()}',
      };
    }
  }

  /// Get settlement reminders for the current user
  Future<List<Map<String, dynamic>>> getSettlementReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email');

      if (email == null) {
        return [];
      }

      final snapshot = await _firestore
          .collection('settlement_reminders')
          .where('to_email', isEqualTo: email)
          .orderBy('sent_at', descending: true)
          .limit(20)
          .get();

      List<Map<String, dynamic>> reminders = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();

        // Get bill details
        final billSnapshot = await _firestore
            .collection('split_bills')
            .doc(data['bill_id'])
            .get();

        if (billSnapshot.exists) {
          final billData = billSnapshot.data() as Map<String, dynamic>;

          reminders.add({
            'reminder_id': data['reminder_id'],
            'settlement_id': data['settlement_id'],
            'bill_id': data['bill_id'],
            'from_email': data['from_email'],
            'to_email': data['to_email'],
            'amount': data['amount'],
            'sent_at': data['sent_at'],
            'bill_description': billData['description'],
            'bill_total_amount': billData['total_amount'],
          });
        }
      }

      return reminders;
    } catch (e) {
      log('Error fetching settlement reminders: $e');
      return [];
    }
  }
}
