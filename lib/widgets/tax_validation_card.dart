import 'package:flutter/material.dart';
import '../models/tax_validation_result.dart';

class TaxValidationCard extends StatelessWidget {
  final TaxValidationResult taxValidation;

  const TaxValidationCard({Key? key, required this.taxValidation})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color statusColor = taxValidation.isValid ? Colors.green : Colors.red;
    IconData statusIcon =
        taxValidation.isValid ? Icons.check_circle : Icons.error;

    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 24),
                SizedBox(width: 8),
                Text('Tax Validation',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            Divider(),
            _buildInfoRow(
                'Status', taxValidation.isValid ? 'Valid ✓' : 'Invalid ✗',
                textColor: statusColor),
            _buildInfoRow(
                'Expected Tax Rate', '${taxValidation.expectedTaxRate}%'),
            _buildInfoRow('Found Tax Rate', '${taxValidation.foundTaxRate}%'),
            _buildInfoRow('Tax Type', taxValidation.taxType),
            if (taxValidation.message.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(taxValidation.message,
                    style: TextStyle(
                        color: statusColor, fontWeight: FontWeight.w500)),
              ),
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
            width: 120,
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
