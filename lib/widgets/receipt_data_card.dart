import 'package:flutter/material.dart';
import '../models/receipts_data.dart';

class ReceiptDataCard extends StatelessWidget {
  final ReceiptData receiptData;

  const ReceiptDataCard({Key? key, required this.receiptData})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Receipt Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Divider(),
            _buildInfoRow('Merchant', receiptData.merchantName),
            _buildInfoRow('Date', receiptData.date),
            _buildInfoRow(
                'Subtotal', 'Rs. ${receiptData.subtotal.toStringAsFixed(2)}'),
            _buildInfoRow('Tax Amount',
                'Rs. ${receiptData.taxAmount.toStringAsFixed(2)}'),
            _buildInfoRow(
                'Tax Rate', '${receiptData.taxRate.toStringAsFixed(1)}%'),
            _buildInfoRow(
                'Total', 'Rs. ${receiptData.total.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? textColor}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child:
                Text('$label:', style: TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: textColor)),
          ),
        ],
      ),
    );
  }
}
