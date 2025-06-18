import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ExpenseOCRService {
  static const String baseUrl =
      'http://192.168.157.83:5000'; // Replace with your Flask server URL

  static Future<Map<String, dynamic>> processReceipt(File imageFile) async {
    try {
      // Convert image to base64
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      final response = await http.post(
        Uri.parse('$baseUrl/process-receipt'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'image_base64': base64Image,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to process receipt: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error processing receipt: $e');
    }
  }

  static Future<Map<String, dynamic>> validateTax({
    required double subtotal,
    required double taxAmount,
    double? taxRate,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/validate-tax'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'subtotal': subtotal,
          'tax_amount': taxAmount,
          'tax_rate': taxRate,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to validate tax: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error validating tax: $e');
    }
  }
}
