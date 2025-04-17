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
  final _nameController = TextEditingController(); // Name controller
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final _auth = AuthService();

  @override
  void dispose() {
    _nameController.dispose(); // Dispose of the name controller
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    var screenHeight = MediaQuery.of(context).size.height;
    var screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          "Sign Up",
          style: TextStyle(fontSize: screenHeight * 0.025),
        ),
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
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
            Text(
              "Join Us!",
              style: TextStyle(
                fontSize: screenHeight * 0.03,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            Text(
              "Create your account and start managing your finances effortlessly.",
              style: TextStyle(
                fontSize: screenHeight * 0.02,
                color: Colors.black54,
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            // Name TextField
            TextField(
              controller: _nameController,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                isDense: true,
                labelText: "Name",
                labelStyle: const TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide:
                      const BorderSide(color: Color(0xFFF1F1FA), width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide:
                      const BorderSide(color: Color(0xFFF1F1FA), width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: const BorderSide(
                    color: Color.fromRGBO(127, 61, 255, 1),
                    width: 1,
                  ),
                ),
                filled: true,
                fillColor: const Color(0xFFF1F1FA),
              ),
            ),
            const SizedBox(height: 12),

// Email TextField
            TextField(
              controller: _emailController,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                isDense: true,
                labelText: "Email",
                labelStyle: const TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide:
                      const BorderSide(color: Color(0xFFF1F1FA), width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide:
                      const BorderSide(color: Color(0xFFF1F1FA), width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: const BorderSide(
                    color: Color.fromRGBO(127, 61, 255, 1),
                    width: 1,
                  ),
                ),
                filled: true,
                fillColor: const Color(0xFFF1F1FA),
              ),
            ),
            const SizedBox(height: 12),

// Password TextField
            TextField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                isDense: true,
                labelText: "Password",
                labelStyle: const TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide:
                      const BorderSide(color: Color(0xFFF1F1FA), width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide:
                      const BorderSide(color: Color(0xFFF1F1FA), width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: const BorderSide(
                    color: Color.fromRGBO(127, 61, 255, 1),
                    width: 1,
                  ),
                ),
                filled: true,
                fillColor: const Color(0xFFF1F1FA),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.black54,
                    size: 24,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),

// Terms and Conditions Checkbox

            const SizedBox(height: 12),
            // Sign-Up Button
            ElevatedButton(
              onPressed: () async {
                await CustomLoader.showLoaderForTask(
                  context: context,
                  task: () async {
                    if (_nameController.text.isNotEmpty &&
                        _emailController.text.isNotEmpty &&
                        _passwordController.text.isNotEmpty) {
                      // Removed _isChecked condition
                      try {
                        final user =
                            await _authService.createUserWithEmailAndPassword(
                          _nameController.text,
                          _emailController.text,
                          _passwordController.text,
                        );

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
                    } else {
                      _showSnackbar(context,
                          'Please fill in all fields.'); // Updated message
                    }
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(127, 61, 255, 1),
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
              ),
              child: const Text(
                "Sign Up",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 12),

// Or with text
            const Text(
              "Or with",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),

// Google Sign Up button
            ElevatedButton.icon(
              onPressed: _handleGoogleSignIn,
              style: ElevatedButton.styleFrom(
                elevation: 2,
                backgroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                side: const BorderSide(color: Color(0xFFF1F1FA), width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                shadowColor: Colors.black.withOpacity(0.3),
              ),
              icon: Image.asset(
                'assets/images/google_logo.png',
                height: 24,
              ),
              label: const Text(
                "Sign Up With Google",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            // Redirect to Login Page
            TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
                child: RichText(
                  text: TextSpan(
                    text: 'Already have an account?',
                    style: TextStyle(
                        fontSize: screenHeight * 0.02, color: Colors.black),
                    children: const <TextSpan>[
                      TextSpan(
                        text: ' Login',
                        style: TextStyle(
                            color: Color.fromRGBO(127, 61, 255, 1),
                            fontSize: 16),
                      ),
                    ],
                  ),
                )),
            SizedBox(height: screenHeight * 0.02),
          ],
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    await CustomLoader.showLoaderForTask(
        context: context,
        task: () async {
          try {
            // Call the Google sign-in method, which returns a Map<String, String>?
            final result = await _auth.signInWithGoogle();

            // Check if result is not null and contains the required user info (like uid)
            if (result != null && result.containsKey('uid')) {
              // Optionally store the email or other user information in SharedPreferences
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('uid', result['uid']!);
              await prefs.setString('email', result['email']!);

              // Navigate to the HomeScreen
            } else {
              print('Google sign-in failed');
            }
          } catch (error) {
            print("Error during Google Sign-In: $error");
          }
        });
  }

  Future<void> _saveToSharedPrefs(String email, String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', email);
    await prefs.setString('uid', uid);
  }

  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    ));
  }
}
