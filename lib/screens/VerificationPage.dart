import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:ExpenseTracker/screens/ResetPasswordPage.dart';
import 'package:ExpenseTracker/widgets/custom_loader.dart';
import 'package:ExpenseTracker/services/email_service.dart';

class VerificationPage extends StatefulWidget {
  final String email;

  const VerificationPage({super.key, required this.email});

  @override
  _VerificationPageState createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String otpMap = '';

  final int _pinLength = 6;
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  int _remainingTime = 119;
  late Timer _timer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_pinLength, (_) => TextEditingController());
    _focusNodes = List.generate(_pinLength, (_) => FocusNode());
    _startTimer();
  }

  String maskEmail(String email) {
    if (email.isEmpty) return '';
    var parts = email.split('@');
    if (parts.length != 2) return email;
    var username = parts[0];
    var domain = parts[1];
    if (username.length <= 3) return email;
    return '${username.substring(0, 3)}${'*' * (username.length - 3)}@$domain';
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
      } else {
        setState(() {
          _remainingTime = 0;
        });
        _timer.cancel();
      }
    });
  }

  void _resetTimer() {
    setState(() {
      _remainingTime = 119; // Reset to the initial timer value
    });
    _timer.cancel();
    _startTimer();
  }

  String get _formattedTime {
    final minutes = (_remainingTime ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingTime % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  Future<void> _resendOTP() async {
    await CustomLoader.showLoaderForTask(
        context: context,
        task: () async {
          // Clear existing OTP fields
          for (var controller in _controllers) {
            controller.clear();
          }
          _currentIndex = 0;

          // Generate and send new OTP
          String email = widget.email;
          String otp = (Random().nextInt(900000) + 100000).toString();

          await _firestore.collection('recovery').add({
            'email': email,
            'otp': otp,
            'timestamp': FieldValue.serverTimestamp(),
          });

          await EmailService.sendOTP(email, otp);

          // Reset timer
          _resetTimer();

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('New OTP sent successfully')),
          );
        });
  }

  void _onKeyPressed(String value) {
    if (value == 'backspace') {
      if (_currentIndex > 0) {
        setState(() {
          _controllers[_currentIndex].clear();
          _currentIndex--;
          FocusScope.of(context).requestFocus(_focusNodes[_currentIndex]);
          _controllers[_currentIndex].clear();
        });
      } else if (_currentIndex == 0) {
        setState(() {
          _controllers[_currentIndex].clear();
        });
      }
    } else if (_currentIndex < _pinLength) {
      setState(() {
        _controllers[_currentIndex].text = value;
        if (_currentIndex < _pinLength - 1) {
          _currentIndex++;
        }
        FocusScope.of(context).requestFocus(_focusNodes[_currentIndex]);
      });
    }

    // Collect the OTP whenever a key is pressed
    otpMap = _controllers.map((controller) => controller.text).join();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _timer.cancel();
    super.dispose();
  }

  Future<void> _verifyOTP() async {
    if (otpMap.length != _pinLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter complete OTP')),
      );
      return;
    }

    await CustomLoader.showLoaderForTask(
        context: context,
        task: () async {
          try {
            QuerySnapshot snapshot = await _firestore
                .collection('recovery')
                .where('email', isEqualTo: widget.email)
                .where('otp', isEqualTo: otpMap)
                .orderBy('timestamp', descending: true)
                .limit(1)
                .get();

            if (snapshot.docs.isNotEmpty) {
              // Delete used OTP for security
              await snapshot.docs.first.reference.delete();

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ResetPasswordPage(email: widget.email),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invalid or expired OTP')),
              );
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Error verifying OTP. Please try again.')),
            );
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    var screenHeight = MediaQuery.of(context).size.height;
    var screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Verification",
          style: TextStyle(fontSize: screenHeight * 0.025),
        ),
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: Icon(
            Icons.arrow_back_ios_rounded,
            size: screenHeight * 0.03,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.05,
                  vertical: screenHeight * 0.02),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  SizedBox(height: screenHeight * 0.03),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Enter your Verification Code",
                      style: TextStyle(
                        fontSize: screenHeight * 0.025,
                        color: const Color.fromRGBO(0, 0, 0, 80),
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      _pinLength,
                      (index) => _buildPinBox(index, screenHeight, screenWidth),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  if (_remainingTime > 0)
                    Text(
                      _formattedTime,
                      style: TextStyle(
                        fontSize: screenHeight * 0.025,
                        color: const Color.fromRGBO(127, 61, 255, 1),
                      ),
                      textAlign: TextAlign.left,
                    )
                  else
                    TextButton(
                      onPressed: _remainingTime == 0 ? _resendOTP : null,
                      child: Text(
                        "Send code again",
                        style: TextStyle(
                          fontSize: screenHeight * 0.02,
                          color: _remainingTime == 0
                              ? const Color.fromRGBO(127, 61, 255, 1)
                              : Colors.grey,
                        ),
                      ),
                    ),
                  SizedBox(height: screenHeight * 0.01),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      text: "We sent a verification code to your email",
                      style: TextStyle(
                        fontSize: screenHeight * 0.02,
                        color: Colors.black54,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: '\n${maskEmail(widget.email)}',
                          style: const TextStyle(
                            color: Color.fromRGBO(127, 61, 255, 1),
                            fontSize: 17,
                          ),
                        ),
                        const TextSpan(
                          text: '. You can check your inbox.',
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  ElevatedButton(
                    onPressed: _verifyOTP,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(127, 61, 255, 1),
                      padding:
                          EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: Text(
                      "Verify",
                      style: TextStyle(
                          fontSize: screenHeight * 0.025, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            _buildCustomKeyboard(screenHeight, screenWidth),
          ],
        ),
      ),
    );
  }

  Widget _buildPinBox(int index, double screenHeight, double screenWidth) {
    return SizedBox(
      width: screenWidth * 0.12,
      height: screenHeight * 0.06,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        readOnly: true,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: screenHeight * 0.03,
          fontWeight: FontWeight.bold,
        ),
        decoration: const InputDecoration(
          border: UnderlineInputBorder(),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.black, width: 1.5),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide:
                BorderSide(color: Color.fromRGBO(127, 61, 255, 1), width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomKeyboard(double screenHeight, double screenWidth) {
    return Container(
      margin: EdgeInsets.only(bottom: screenHeight * 0.02),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKeyboardButton('1', screenHeight),
              _buildKeyboardButton('2', screenHeight),
              _buildKeyboardButton('3', screenHeight),
            ],
          ),
          SizedBox(height: screenHeight * 0.01),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKeyboardButton('4', screenHeight),
              _buildKeyboardButton('5', screenHeight),
              _buildKeyboardButton('6', screenHeight),
            ],
          ),
          SizedBox(height: screenHeight * 0.01),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKeyboardButton('7', screenHeight),
              _buildKeyboardButton('8', screenHeight),
              _buildKeyboardButton('9', screenHeight),
            ],
          ),
          SizedBox(height: screenHeight * 0.01),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKeyboardButton('0', screenHeight),
              SizedBox(width: screenWidth * 0.15),
              _buildKeyboardButton('backspace', screenHeight,
                  isBackspace: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeyboardButton(String value, double screenHeight,
      {bool isBackspace = false}) {
    return GestureDetector(
      onTap: () => _onKeyPressed(value),
      child: Container(
        width: screenHeight * 0.1,
        height: screenHeight * 0.1,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: isBackspace
            ? Icon(
                Icons.backspace,
                size: screenHeight * 0.03,
                color: const Color.fromRGBO(127, 61, 255, 1),
              )
            : Text(
                value,
                style: TextStyle(
                  fontSize: screenHeight * 0.035,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromRGBO(127, 61, 255, 1),
                ),
              ),
      ),
    );
  }
}
