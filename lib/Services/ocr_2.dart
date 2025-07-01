import 'dart:io';
import 'package:ExpenseTracker/models/receipts_response.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;

class ReceiptOCRService {
  static const String _baseUrl =
      'http://localhost:5000'; // Change to your server URL
  final Dio _dio = Dio();

  ReceiptOCRService() {
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }

  Future<ReceiptResponse> processReceipt(File imageFile) async {
    try {
      String fileName = path.basename(imageFile.path);

      FormData formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });

      Response response = await _dio.post(
        '$_baseUrl/process_receipt',
        data: formData,
      );

      return ReceiptResponse.fromJson(response.data);
    } on DioException catch (e) {
      return ReceiptResponse(
        success: false,
        error: 'Network error: ${e.message}',
      );
    } catch (e) {
      return ReceiptResponse(
        success: false,
        error: 'Unexpected error: $e',
      );
    }
  }

  Future<bool> checkServerHealth() async {
    try {
      Response response = await _dio.get('$_baseUrl/health');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
