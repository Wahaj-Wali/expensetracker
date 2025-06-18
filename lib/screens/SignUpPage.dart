import 'package:flutter/material.dart';
import 'package:ExpenseTracker/Services/auth_service.dart';
import 'package:ExpenseTracker/screens/HomeScreen.dart';
import 'package:ExpenseTracker/screens/LoginPage.dart';
import 'package:ExpenseTracker/widgets/custom_loader.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isValidName(String name) {
    final nameRegex = RegExp(r'^[A-Za-z][A-Za-z ]*$');
    return nameRegex.hasMatch(name);
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  bool _isStrongPassword(String password) {
    final passwordRegex =
        RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$&*~]).{8,}$');
    return passwordRegex.hasMatch(password);
  }

  @override
  Widget build(BuildContext context) {
    var screenHeight = MediaQuery.of(context).size.height;
    var screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title:
            Text("Sign Up", style: TextStyle(fontSize: screenHeight * 0.025)),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.arrow_back_ios_rounded, size: screenHeight * 0.03),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05, vertical: screenHeight * 0.02),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(height: screenHeight * 0.02),
            Text("Join",
                style: TextStyle(
                    fontSize: screenHeight * 0.03,
                    fontWeight: FontWeight.bold)),
            SizedBox(height: screenHeight * 0.01),
            Text(
                "Create your account and start managing your finances effortlessly.",
                style: TextStyle(
                    fontSize: screenHeight * 0.02, color: Colors.black54)),
            SizedBox(height: screenHeight * 0.02),
            TextField(
              controller: _nameController,
              decoration: _buildInputDecoration("Name"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: _buildInputDecoration("Email"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: _buildInputDecoration("Password").copyWith(
                suffixIcon: IconButton(
                  icon: Icon(_isPasswordVisible
                      ? Icons.visibility
                      : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                await CustomLoader.showLoaderForTask(
                  context: context,
                  task: () async {
                    final name = _nameController.text.trim();
                    final email = _emailController.text.trim();
                    final password = _passwordController.text;

                    if (name.isEmpty || email.isEmpty || password.isEmpty) {
                      _showSnackbar(context, 'Please fill in all fields.');
                      return;
                    }

                    if (!_isValidName(name)) {
                      _showSnackbar(context,
                          'Name must start with a letter and contain only letters and spaces.');
                      return;
                    }

                    if (!_isValidEmail(email)) {
                      _showSnackbar(
                          context, 'Please enter a valid email address.');
                      return;
                    }

                    if (!_isStrongPassword(password)) {
                      _showSnackbar(context,
                          'Password must be at least 8 characters and include upper, lower, number, and special character.');
                      return;
                    }

                    try {
                      final user =
                          await _authService.createUserWithEmailAndPassword(
                              name, email, password);
                      if (user != null) {
                        await _saveToSharedPrefs(
                            user['email']!, user['auth_id']!);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const HomeScreen()),
                        );
                      } else {
                        _showSnackbar(
                            context, 'Sign-up failed. Please try again.');
                      }
                    } catch (e) {
                      _showSnackbar(context, 'Error: ${e.toString()}');
                    }
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(127, 61, 255, 1),
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0)),
              ),
              child: const Text("Sign Up",
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w500)),
            ),
            const SizedBox(height: 12),
            const Text("Or with",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _handleGoogleSignIn,
              icon: Image.asset('assets/images/google_logo.png', height: 24),
              label: const Text("Sign Up With Google",
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                side: const BorderSide(color: Color(0xFFF1F1FA)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            TextButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const LoginPage()));
              },
              child: RichText(
                text: TextSpan(
                  text: 'Already have an account?',
                  style: TextStyle(
                      fontSize: screenHeight * 0.02, color: Colors.black),
                  children: const [
                    TextSpan(
                      text: ' Login',
                      style: TextStyle(color: Color.fromRGBO(127, 61, 255, 1)),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 16, color: Colors.black54),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.0)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: const BorderSide(color: Color(0xFFF1F1FA)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: const BorderSide(color: Color.fromRGBO(127, 61, 255, 1)),
      ),
      filled: true,
      fillColor: const Color(0xFFF1F1FA),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    await CustomLoader.showLoaderForTask(
      context: context,
      task: () async {
        try {
          final result = await _authService.signInWithGoogle();
          if (result != null && result.containsKey('uid')) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('uid', result['uid']!);
            await prefs.setString('email', result['email']!);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          } else {
            _showSnackbar(context, 'Google sign-in failed.');
          }
        } catch (e) {
          _showSnackbar(context, 'Error during Google Sign-In: $e');
        }
      },
    );
  }

  Future<void> _saveToSharedPrefs(String email, String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', email);
    await prefs.setString('uid', uid);
  }

  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red));
  }
}
