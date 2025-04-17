// ReportGenerationPage.dart
import 'package:ExpenseTracker/widgets/CircularMenuWidget.dart';
import 'package:flutter/material.dart';
import 'package:ExpenseTracker/Services/ReportController.dart';
import 'package:ExpenseTracker/widgets/CustomBottomNavigationBar.dart';

class ReportGenerationPage extends StatefulWidget {
  const ReportGenerationPage({Key? key}) : super(key: key);

  @override
  _ReportGenerationPageState createState() => _ReportGenerationPageState();
}

class _ReportGenerationPageState extends State<ReportGenerationPage> {
  final ReportController _reportController = ReportController();
  int _selectedYear = DateTime.now().year;
  bool _isGenerating = false;
  String? _reportFilePath;
  String? _statusMessage;
  bool _isSuccess = false;
  final int _activeIndex = 3;

  List<int> get availableYears {
    final currentYear = DateTime.now().year;
    return List.generate(5, (index) => currentYear - index);
  }

  Future<void> _generateReport() async {
    setState(() {
      _isGenerating = true;
      _statusMessage = null;
      _reportFilePath = null;
      _isSuccess = false;
    });

    final result = await _reportController.generateAnnualReport(_selectedYear);

    setState(() {
      _isGenerating = false;
      _statusMessage = result['message'];
      _isSuccess = result['success'];
      if (result['success']) {
        _reportFilePath = result['filePath'];
      }
    });
  }

  Future<void> _shareReport() async {
    if (_reportFilePath != null) {
      final shared = await _reportController.shareReport(_reportFilePath!);
      if (!shared) {
        setState(() {
          _statusMessage = 'Failed to share report';
          _isSuccess = false;
        });
      }
    }
  }

  Future<void> _saveToDownloads() async {
    if (_reportFilePath != null) {
      final result =
          await _reportController.saveReportToDownloads(_reportFilePath!);
      setState(() {
        _statusMessage = result['message'];
        _isSuccess = result['success'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Annual Reports",
          style: TextStyle(
            color: Colors.black,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Report Generation Card
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 3,
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(127, 61, 255, 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.description,
                          color: Color.fromRGBO(127, 61, 255, 1),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Generate Annual Report',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Select Year',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Year Selection Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(127, 61, 255, 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color.fromRGBO(127, 61, 255, 0.2),
                        width: 1,
                      ),
                    ),
                    child: DropdownButtonFormField<int>(
                      value: _selectedYear,
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Color.fromRGBO(127, 61, 255, 1),
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      menuMaxHeight: 300,
                      borderRadius: BorderRadius.circular(
                          12), // This adds rounded corners to the dropdown menu
                      items: availableYears
                          .map((year) => DropdownMenuItem<int>(
                                value: year,
                                child: Text(
                                  year.toString(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Color.fromRGBO(127, 61, 255, 1),
                                  ),
                                ),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedYear = value;
                          });
                        }
                      },
                      dropdownColor: Colors.white,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color.fromRGBO(127, 61, 255, 1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(127, 61, 255, 1),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isGenerating ? null : _generateReport,
                      child: _isGenerating
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Generate CSV Report',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Status Message
          if (_statusMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 3,
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: (_isSuccess
                              ? Colors.green
                              : const Color.fromRGBO(127, 61, 255, 1))
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _isSuccess ? Icons.check_circle : Icons.info,
                      color: _isSuccess
                          ? Colors.green
                          : const Color.fromRGBO(127, 61, 255, 1),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _statusMessage!,
                      style: TextStyle(
                        fontSize: 16,
                        color: _isSuccess
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Action Buttons
          if (_reportFilePath != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 3,
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.share, size: 20),
                        label: const Text(
                          'Share',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor:
                              const Color.fromRGBO(127, 61, 255, 1),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _shareReport,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 48,
                      margin: const EdgeInsets.only(left: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 3,
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.download, size: 20),
                        label: const Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor:
                              const Color.fromRGBO(127, 61, 255, 1),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _saveToDownloads,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        activeIndex: _activeIndex,
      ),
      floatingActionButton: const CircularMenuWidget(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
