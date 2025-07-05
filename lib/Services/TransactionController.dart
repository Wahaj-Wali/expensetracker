import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class TransactionController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final uuid = const Uuid();

  // Process a regular transaction or a split bill transaction (with budget support)
  Future<Map<String, dynamic>> processTransaction({
    required double amount,
    required String accountName,
    required String transactionType,
    String? categoryName, // Optional for transfers
    String? description,
    String? splitBillId, // For split bills
    bool isSplitBill = false, // To identify split bills
    String? budgetId, // <-- NEW PARAMETER
  }) async {
    try {
      // Retrieve email from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email');
      if (email == null) {
        return {
          'success': false,
          'message': "User email not found in preferences.",
        };
      }

      final String transactionId = uuid.v4();

      // Execute Firestore transaction to ensure atomicity
      await _firestore.runTransaction((transaction) async {
        // Reference to the account document
        QuerySnapshot accountSnapshot = await _firestore
            .collection('accounts')
            .where('email', isEqualTo: email)
            .where('account_name', isEqualTo: accountName)
            .limit(1)
            .get();

        if (accountSnapshot.docs.isEmpty) {
          throw Exception("Account not found.");
        }

        DocumentReference accountRef = accountSnapshot.docs.first.reference;

        // Get current balance and ensure it's a double
        var currentBalance = accountSnapshot.docs.first['balance'];
        double currentBalanceDouble = currentBalance is double
            ? currentBalance
            : double.tryParse(currentBalance.toString()) ?? 0.0;

        // Calculate new balance based on transaction type
        double updatedBalance;
        if (transactionType == "Expense") {
          updatedBalance = currentBalanceDouble - amount;
          if (updatedBalance < 0) {
            throw Exception("Insufficient funds in the account.");
          }
        } else if (transactionType == "Income") {
          updatedBalance = currentBalanceDouble + amount;
        } else {
          throw Exception("Invalid transaction type.");
        }

        // Create transaction document data
        Map<String, dynamic> transactionData = {
          'transaction_id': transactionId,
          'email': email,
          'transaction_type': transactionType,
          'amount': amount.toString(),
          'account_name': accountName,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
          'created_at': FieldValue.serverTimestamp(),
        };

        // Add optional fields if provided
        if (categoryName != null) {
          transactionData['category_name'] = categoryName;
        }
        if (description != null) {
          transactionData['description'] = description;
        }
        if (isSplitBill) {
          transactionData['is_split_bill'] = true;
          if (splitBillId != null) {
            transactionData['split_bill_id'] = splitBillId;
          }
        }

        // ADD: budget_id if provided and it's an Expense
        if (budgetId != null && transactionType == "Expense") {
          transactionData['budget_id'] = budgetId;
        }

        // Update the balance field in Firestore
        transaction.update(accountRef, {'balance': updatedBalance});

        // Create the transaction document
        transaction.set(
          _firestore.collection('transactions').doc(transactionId),
          transactionData,
        );

        // ADD: Update the budget's spent_amount if budgetId is provided and Expense
        if (budgetId != null && transactionType == "Expense") {
          DocumentReference budgetRef =
              _firestore.collection('budgets').doc(budgetId);
          transaction.update(budgetRef, {
            'spent_amount': FieldValue.increment(amount),
          });
        }
      });

      // Return success with transaction ID
      return {
        'success': true,
        'message': "Transaction completed successfully.",
        'transactionId': transactionId,
      };
    } catch (e) {
      // Return failure with an error message
      return {
        'success': false,
        'message': "Transaction failed: ${e.toString()}",
      };
    }
  }

  // Get all transactions including split bills with optional filters
  Future<List<Map<String, dynamic>>> getAllTransactions({
    bool includeSplitBills = true,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email');
      if (email == null) {
        throw Exception("User email not found in preferences.");
      }

      Query query = _firestore
          .collection('transactions')
          .where('email', isEqualTo: email);

      if (!includeSplitBills) {
        query = query.where('is_split_bill', isEqualTo: false);
      }

      if (startDate != null) {
        query = query.where('timestamp',
            isGreaterThanOrEqualTo: startDate.toUtc().toIso8601String());
      }

      if (endDate != null) {
        query = query.where('timestamp',
            isLessThanOrEqualTo: endDate.toUtc().toIso8601String());
      }

      QuerySnapshot querySnapshot =
          await query.orderBy('timestamp', descending: true).get();

      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print("Error getting transactions: $e");
      return [];
    }
  }

  // Get split bill transactions only
  Future<List<Map<String, dynamic>>> getSplitBillTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email');
      if (email == null) {
        throw Exception("User email not found in preferences.");
      }

      QuerySnapshot querySnapshot = await _firestore
          .collection('transactions')
          .where('email', isEqualTo: email)
          .where('is_split_bill', isEqualTo: true)
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print("Error getting split bill transactions: $e");
      return [];
    }
  }

  // Delete a transaction with support for split bills
  Future<Map<String, dynamic>> deleteTransaction({
    required String transactionId,
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

      // First, find the transaction
      QuerySnapshot transactionQuery = await _firestore
          .collection('transactions')
          .where('email', isEqualTo: email)
          .where('transaction_id', isEqualTo: transactionId)
          .limit(1)
          .get();

      if (transactionQuery.docs.isEmpty) {
        return {
          'success': false,
          'message': "Transaction not found.",
        };
      }

      DocumentSnapshot transactionSnapshot = transactionQuery.docs.first;
      var transactionData = transactionSnapshot.data() as Map<String, dynamic>;

      // Check if this is a split bill transaction
      if (transactionData['is_split_bill'] == true) {
        // If it's a split bill transaction, check if the split bill still exists
        String? splitBillId = transactionData['split_bill_id'];
        if (splitBillId != null) {
          DocumentSnapshot splitBillDoc =
              await _firestore.collection('split_bills').doc(splitBillId).get();

          if (splitBillDoc.exists) {
            return {
              'success': false,
              'message':
                  "Cannot delete split bill transaction directly. Please delete the split bill instead.",
            };
          }
        }
      }

      // Process the deletion as before
      if (transactionData['transaction_type'] == 'Transfer') {
        return await _deleteTransferTransaction(
            transactionSnapshot, transactionData, email);
      } else {
        return await _deleteRegularTransaction(
            transactionSnapshot, transactionData, email);
      }
    } catch (e) {
      return {
        'success': false,
        'message': "Transaction deletion failed: ${e.toString()}",
      };
    }
  }

  // Modify the _deleteRegularTransaction method to handle budget reverse
  Future<Map<String, dynamic>> _deleteRegularTransaction(
      DocumentSnapshot transactionSnapshot,
      Map<String, dynamic> transactionData,
      String email) async {
    // Get transaction details
    String accountName =
        transactionData['account_name'] ?? transactionData['account'] ?? '';

    // Parse amount - handle both string and number formats
    double amount;
    var amountData = transactionData['amount'];
    if (amountData is double) {
      amount = amountData;
    } else if (amountData is int) {
      amount = amountData.toDouble();
    } else if (amountData is String) {
      amount = double.tryParse(amountData) ?? 0.0;
    } else {
      amount = 0.0;
    }

    String transactionType = transactionData['transaction_type'];

    // Execute Firestore transaction to ensure atomicity
    await _firestore.runTransaction((transaction) async {
      // Reference to the account document
      QuerySnapshot accountSnapshot = await _firestore
          .collection('accounts')
          .where('email', isEqualTo: email)
          .where('account_name', isEqualTo: accountName)
          .limit(1)
          .get();

      if (accountSnapshot.docs.isEmpty) {
        throw Exception("Account not found.");
      }

      DocumentReference accountRef = accountSnapshot.docs.first.reference;

      // Get current balance and ensure it's a double
      var currentBalance = accountSnapshot.docs.first['balance'];

      // Ensure currentBalance is a double (parse if it's a String)
      double currentBalanceDouble = currentBalance is double
          ? currentBalance
          : double.tryParse(currentBalance.toString()) ?? 0.0;

      // Calculate new balance based on transaction type (reverse the original transaction)
      double updatedBalance;
      if (transactionType == "Expense") {
        updatedBalance = currentBalanceDouble + amount; // Reverse the expense
      } else if (transactionType == "Income") {
        updatedBalance = currentBalanceDouble - amount; // Reverse the income
        if (updatedBalance < 0) {
          throw Exception(
              "Cannot delete this income transaction as it would result in negative balance.");
        }
      } else {
        throw Exception("Invalid transaction type.");
      }

      // Update the balance field in Firestore
      transaction.update(accountRef, {'balance': updatedBalance});

      // Delete the transaction document
      transaction.delete(transactionSnapshot.reference);

      // ADD: Reverse budget spent if budget_id exists
      if (transactionData.containsKey('budget_id')) {
        String budgetId = transactionData['budget_id'];
        DocumentReference budgetRef =
            _firestore.collection('budgets').doc(budgetId);

        // Use FieldValue.increment with a negative value to subtract
        transaction.update(budgetRef, {
          'spent_amount': FieldValue.increment(-amount),
        });
      }
    });

    return {
      'success': true,
      'message': "Transaction deleted successfully.",
    };
  }

  Future<Map<String, dynamic>> _deleteTransferTransaction(
      DocumentSnapshot transactionSnapshot,
      Map<String, dynamic> transactionData,
      String email) async {
    // Get transfer details
    String fromAccountName = transactionData['from_account'] ?? '';
    String toAccountName = transactionData['to_account'] ?? '';

    // Parse amount
    double amount;
    var amountData = transactionData['amount'];
    if (amountData is double) {
      amount = amountData;
    } else if (amountData is int) {
      amount = amountData.toDouble();
    } else if (amountData is String) {
      amount = double.tryParse(amountData) ?? 0.0;
    } else {
      amount = 0.0;
    }

    // Execute Firestore transaction to ensure atomicity
    await _firestore.runTransaction((transaction) async {
      // Get both accounts
      QuerySnapshot fromAccountSnapshot = await _firestore
          .collection('accounts')
          .where('email', isEqualTo: email)
          .where('account_name', isEqualTo: fromAccountName)
          .limit(1)
          .get();

      QuerySnapshot toAccountSnapshot = await _firestore
          .collection('accounts')
          .where('email', isEqualTo: email)
          .where('account_name', isEqualTo: toAccountName)
          .limit(1)
          .get();

      if (fromAccountSnapshot.docs.isEmpty || toAccountSnapshot.docs.isEmpty) {
        throw Exception("One or both accounts not found.");
      }

      DocumentReference fromAccountRef =
          fromAccountSnapshot.docs.first.reference;
      DocumentReference toAccountRef = toAccountSnapshot.docs.first.reference;

      // Get current balances
      var fromCurrentBalance = fromAccountSnapshot.docs.first['balance'];
      var toCurrentBalance = toAccountSnapshot.docs.first['balance'];

      double fromBalanceDouble = fromCurrentBalance is double
          ? fromCurrentBalance
          : double.tryParse(fromCurrentBalance.toString()) ?? 0.0;

      double toBalanceDouble = toCurrentBalance is double
          ? toCurrentBalance
          : double.tryParse(toCurrentBalance.toString()) ?? 0.0;

      // Reverse the transfer
      double fromUpdatedBalance =
          fromBalanceDouble + amount; // Add back to source
      double toUpdatedBalance =
          toBalanceDouble - amount; // Remove from destination

      // Check if destination account would have sufficient funds after reversal
      if (toUpdatedBalance < 0) {
        throw Exception(
            "Cannot delete this transfer as it would result in negative balance in the destination account.");
      }

      // Update both accounts
      transaction.update(fromAccountRef, {'balance': fromUpdatedBalance});
      transaction.update(toAccountRef, {'balance': toUpdatedBalance});

      // Delete the transaction document
      transaction.delete(transactionSnapshot.reference);
    });

    return {
      'success': true,
      'message': "Transfer transaction deleted successfully.",
    };
  }
}
