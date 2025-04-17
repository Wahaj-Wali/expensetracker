import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Currency extends StatefulWidget {
  final Color color;
  final void Function(
          String fromCurrency, String toCurrency, double amount, String result)
      onConvert;

  const Currency({
    Key? key,
    required this.color,
    required this.onConvert,
  }) : super(key: key);

  @override
  _CurrencyState createState() => _CurrencyState();
}

class _CurrencyState extends State<Currency> {
  final String _fromCurrency = 'PKR';
  final String _toCurrency = 'PKR';
  double _amount = 0;
  String _result = '';
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _triggerConversionCallback() {
    widget.onConvert(_fromCurrency, _toCurrency, _amount, _amount.toString());
  }

  bool _validateAmount(String value) {
    if (value.isEmpty) {
      setState(() {
        _result = 'Amount required'; // Show error message
      });
      return false;
    }

    String cleanValue = value.trim();

    if (cleanValue.startsWith('-')) {
      setState(() {
        _result = 'Negative amounts not allowed'; // Show error message
      });
      return false;
    }

    if (!RegExp(r'^\d*\.?\d{0,2}$').hasMatch(cleanValue)) {
      setState(() {
        _result = 'Invalid amount format'; // Show error message
      });
      return false;
    }

    try {
      double amount = double.parse(cleanValue);
      if (amount <= 0) {
        setState(() {
          _result = 'Amount must be greater than 0'; // Show error message
        });
        return false;
      }
      setState(() {
        _result = ''; // Clear error message on valid input
      });
      return true;
    } catch (e) {
      setState(() {
        _result = 'Amount should be greater than 0'; // Show error message
      });
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Form(
        key: _formKey,
        child: Container(
          decoration: BoxDecoration(
            color: widget.color,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 5),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      cursorColor: Colors.white,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 50,
                      ),
                      controller: _amountController,
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        prefixIcon: Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: const Icon(
                            Icons.currency_exchange,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                        hintText: '0',
                        hintStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 50,
                        ),
                        labelStyle: const TextStyle(color: Colors.white),
                        errorStyle: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      onChanged: (value) {
                        if (_validateAmount(value)) {
                          setState(() {
                            _amount = double.parse(value);
                            _triggerConversionCallback();
                          });
                        }
                      },
                      validator: (value) {
                        if (!_validateAmount(value ?? '')) {
                          return _result; // Show validation error message
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              // Show error messages if present
              if (_result.isNotEmpty && _result != 'Amount required')
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                  child: Text(
                    _result,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}
