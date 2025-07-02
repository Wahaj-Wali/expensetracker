import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TransactionController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> processTransaction({
    required double amount, // Pass amount as a double
    required String accountName,
    required String transactionType,
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

        // Update the balance field in Firestore
        transaction.update(accountRef, {'balance': updatedBalance});
      });

      // Return success with a confirmation message
      return {
        'success': true,
        'message': "Transaction completed successfully.",
      };
    } catch (e) {
      // Return failure with an error message
      return {
        'success': false,
        'message': "Transaction failed: ${e.toString()}",
      };
    }
  }

  Future<Map<String, dynamic>> deleteTransaction({
    required String transactionId,
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

      // First, find the transaction by transaction_id field (not document ID)
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
        return {
          'success': false,
          'message':
              "Cannot delete split bill transaction directly. Please delete the split bill instead.",
        };
      }

      // Get transaction details
      String transactionType = transactionData['transaction_type'];

      // Handle different transaction types
      if (transactionType == 'Transfer') {
        return await _deleteTransferTransaction(
            transactionSnapshot, transactionData, email);
      } else {
        return await _deleteRegularTransaction(
            transactionSnapshot, transactionData, email);
      }
    } catch (e) {
      // Return failure with an error message
      return {
        'success': false,
        'message': "Transaction deletion failed: ${e.toString()}",
      };
    }
  }

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

  /// Get all transactions including split bill transactions
  Future<List<Map<String, dynamic>>> getAllTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email');
      if (email == null) {
        throw Exception("User email not found in preferences.");
      }

      QuerySnapshot querySnapshot = await _firestore
          .collection('transactions')
          .where('email', isEqualTo: email)
          .orderBy('created_at', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print("Error getting all transactions: $e");
      return [];
    }
  }

  /// Get transactions by type (including split bill filter)
  Future<List<Map<String, dynamic>>> getTransactionsByType({
    String? transactionType,
    bool? isSplitBill,
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

      if (transactionType != null) {
        query = query.where('transaction_type', isEqualTo: transactionType);
      }

      if (isSplitBill != null) {
        query = query.where('is_split_bill', isEqualTo: isSplitBill);
      }

      QuerySnapshot querySnapshot =
          await query.orderBy('created_at', descending: true).get();

      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print("Error getting transactions by type: $e");
      return [];
    }
  }

  /// Get transaction statistics including split bill stats
  Future<Map<String, dynamic>> getTransactionStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email');
      if (email == null) {
        throw Exception("User email not found in preferences.");
      }

      QuerySnapshot querySnapshot = await _firestore
          .collection('transactions')
          .where('email', isEqualTo: email)
          .get();

      List<Map<String, dynamic>> transactions = querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      int totalTransactions = transactions.length;
      int expenseTransactions =
          transactions.where((t) => t['transaction_type'] == 'Expense').length;
      int incomeTransactions =
          transactions.where((t) => t['transaction_type'] == 'Income').length;
      int transferTransactions =
          transactions.where((t) => t['transaction_type'] == 'Transfer').length;
      int splitBillTransactions =
          transactions.where((t) => t['is_split_bill'] == true).length;

      return {
        'total_transactions': totalTransactions,
        'expense_transactions': expenseTransactions,
        'income_transactions': incomeTransactions,
        'transfer_transactions': transferTransactions,
        'split_bill_transactions': splitBillTransactions,
      };
    } catch (e) {
      print("Error getting transaction stats: $e");
      return {
        'total_transactions': 0,
        'expense_transactions': 0,
        'income_transactions': 0,
        'transfer_transactions': 0,
        'split_bill_transactions': 0,
      };
    }
  }
}
