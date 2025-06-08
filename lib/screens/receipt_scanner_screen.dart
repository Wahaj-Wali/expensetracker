import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../models/receipts_data.dart';
import '../models/tax_validation_result.dart';
import '../services/ocr_service.dart';
import '../services/tax_validator.dart';
import '../utils/receipt_parser.dart';
import '../widgets/image_picker_buttons.dart';
import '../widgets/receipt_data_card.dart';
import '../widgets/tax_validation_card.dart';

class ReceiptScannerScreen extends StatefulWidget {
  @override
  _ReceiptScannerScreenState createState() => _ReceiptScannerScreenState();
}

class _ReceiptScannerScreenState extends State<ReceiptScannerScreen> {
  final ImagePicker _picker = ImagePicker();

  File? _imageFile;
  String _extractedText = '';
  ReceiptData? _receiptData;
  TaxValidationResult? _taxValidation;
  bool _isProcessing = false;

  @override
  void dispose() {
    OCRService.dispose();
    super.dispose();
  }

  Future<void> _handleImagePicked(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
          _isProcessing = true;
        });
        await _processImage();
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _processImage() async {
    if (_imageFile == null) return;

    try {
      // Extract text using OCR
      final extractedText = await OCRService.extractTextFromImage(_imageFile!);

      setState(() {
        _extractedText = extractedText;
      });

      // Parse receipt data
      final receiptData = ReceiptParser.parseReceiptText(extractedText);

      // Validate tax
      final taxValidation = TaxValidator.validateTax(receiptData);

      setState(() {
        _receiptData = receiptData;
        _taxValidation = taxValidation;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showError('Failed to process image: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Receipt Scanner'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ImagePickerButtons(onImagePicked: _handleImagePicked),
            SizedBox(height: 20),
            if (_imageFile != null) ...[
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(_imageFile!, fit: BoxFit.contain),
                ),
              ),
              SizedBox(height: 20),
            ],
            if (_isProcessing) ...[
              Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Processing receipt...',
                        style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              SizedBox(height: 20),
            ],
            if (_receiptData != null) ...[
              ReceiptDataCard(receiptData: _receiptData!),
              SizedBox(height: 16),
            ],
            if (_taxValidation != null) ...[
              TaxValidationCard(taxValidation: _taxValidation!),
              SizedBox(height: 16),
            ],
            if (_extractedText.isNotEmpty) ...[
              ExpansionTile(
                title: Text('Raw Extracted Text'),
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_extractedText, style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
