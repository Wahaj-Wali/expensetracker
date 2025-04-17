import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ExpenseTracker/Services/auth_service.dart';
import 'package:ExpenseTracker/screens/ForgotPasswordPage.dart';
import 'package:ExpenseTracker/screens/HomeScreen.dart';
import 'package:ExpenseTracker/screens/SignUpPage.dart';
import 'package:ExpenseTracker/widgets/custom_loader.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _auth = AuthService();
  bool _supportsBiometrics = false;
  bool _showBiometricButton = false;
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _emailError;
  String? _passwordError;

  bool _validateInputs() {
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    bool isValid = true;

    // Email validation
    if (_email.text.isEmpty) {
      setState(() {
        _emailError = 'Email is required';
      });
      isValid = false;
    } else if (!_isValidEmail(_email.text)) {
      setState(() {
        _emailError = 'Please enter a valid email';
      });
      isValid = false;
    }

    // Password validation
    if (_password.text.isEmpty) {
      setState(() {
        _passwordError = 'Password is required';
      });
      isValid = false;
    } else if (_password.text.length < 6) {
      setState(() {
        _passwordError = 'Password must be at least 6 characters';
      });
      isValid = false;
    }

    return isValid;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  final FirebaseAuth _authh = FirebaseAuth.instance;
  User? _user;

  @override
  void initState() {
    super.initState();
    _checkBiometricSupport();
    _checkPreviousLogin();
    _authh.authStateChanges().listen((event) {
      setState(() {
        _user = event;
      });
    });
  }

  Future<void> _checkPreviousLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    final String? lastEmail = prefs.getString('last_logged_in_email');

    setState(() {
      _showBiometricButton = isLoggedIn && lastEmail != null;
    });
  }

  Future<void> _checkBiometricSupport() async {
    final supportsBiometrics = await _auth.canUseBiometrics();
    setState(() {
      _supportsBiometrics = supportsBiometrics;
    });
  }

  Future<void> _handleBiometricLogin() async {
    await CustomLoader.showLoaderForTask(
      context: context,
      task: () async {
        try {
          final prefs = await SharedPreferences.getInstance();
          final bool isLoggedIn = prefs.getBool('is_logged_in') ?? false;
          final String? lastEmail = prefs.getString('last_logged_in_email');

          if (!isLoggedIn || lastEmail == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Please login with email first')),
            );
            return;
          }

          final LocalAuthentication localAuth = LocalAuthentication();
          final bool didAuthenticate = await localAuth.authenticate(
            localizedReason: 'Please authenticate to login',
            options: const AuthenticationOptions(
              biometricOnly: false,
            ),
          );

          if (didAuthenticate) {
            // Get the stored user data
            final querySnapshot = await FirebaseFirestore.instance
                .collection('authentication')
                .where('email', isEqualTo: lastEmail)
                .get();

            if (querySnapshot.docs.isNotEmpty) {
              final userData = querySnapshot.docs.first.data();

              // Update SharedPreferences
              await prefs.setString('email', userData['email']);
              await prefs.setString('uid', userData['auth_id']);
              await prefs.setBool('is_logged_in', true);

              goToHome(context);
            } else {
              await prefs.clear();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content:
                        Text('User data not found. Please login with email')),
              );
            }
          }
        } catch (e) {
          print('Error during biometric authentication: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Authentication failed')),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    _email.dispose();
    _password.dispose();
  }

  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    var screenHeight = MediaQuery.of(context).size.height;
    var screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Login",
          style: TextStyle(fontSize: screenHeight * 0.03),
        ),
        leading: GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SignUpPage()),
            );
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
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            SizedBox(height: screenHeight * 0.02),
            Text(
              "Welcome Back!",
              style: TextStyle(
                fontSize: screenHeight * 0.03,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            Text(
              "Sign in to access your account and keep track of your expenses.",
              style: TextStyle(
                fontSize: screenHeight * 0.02,
                color: Colors.black54,
              ),
            ),
            SizedBox(height: screenHeight * 0.05),
            TextField(
              controller: _email,
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
                errorText: _emailError,
                errorStyle: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: BorderSide(
                    color: _emailError != null
                        ? Colors.red
                        : const Color(0xFFF1F1FA),
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: BorderSide(
                    color: _emailError != null
                        ? Colors.red
                        : const Color(0xFFF1F1FA),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: BorderSide(
                    color: _emailError != null
                        ? Colors.red
                        : const Color.fromRGBO(127, 61, 255, 1),
                    width: 1,
                  ),
                ),
                filled: true,
                fillColor: const Color(0xFFF1F1FA),
              ),
            ),
            const SizedBox(height: 12),

            // Password TextField with error message
            TextField(
              controller: _password,
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
                errorText: _passwordError,
                errorStyle: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: BorderSide(
                    color: _passwordError != null
                        ? Colors.red
                        : const Color(0xFFF1F1FA),
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: BorderSide(
                    color: _passwordError != null
                        ? Colors.red
                        : const Color(0xFFF1F1FA),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: BorderSide(
                    color: _passwordError != null
                        ? Colors.red
                        : const Color.fromRGBO(127, 61, 255, 1),
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
            SizedBox(height: screenHeight * 0.03),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) => const ForgotPasswordPage()),
                  );
                },
                child: Text(
                  "Forgot Password?",
                  style: TextStyle(
                    color: const Color.fromRGBO(127, 61, 255, 1),
                    fontSize: screenHeight * 0.02,
                  ),
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.03),
            // Sign In Button
            ElevatedButton(
              onPressed: _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromRGBO(127, 61, 255, 1),
                padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Text(
                "Sign In",
                style: TextStyle(
                    fontSize: screenHeight * 0.025, color: Colors.white),
              ),
            ),
            const SizedBox(height: 12), // Match spacing between text fields
// Or with text
            if (_showBiometricButton) ...[
              SizedBox(height: screenHeight * 0.02),
              ElevatedButton.icon(
                onPressed: _handleBiometricLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: BorderSide(color: Color.fromRGBO(127, 61, 255, 1)),
                  padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                icon: Icon(
                  Icons.fingerprint,
                  color: Color.fromRGBO(127, 61, 255, 1),
                  size: screenHeight * 0.03,
                ),
                label: Text(
                  "Login with Biometrics",
                  style: TextStyle(
                    fontSize: screenHeight * 0.025,
                    color: Color.fromRGBO(127, 61, 255, 1),
                  ),
                ),
              ),
            ],

            SizedBox(height: screenHeight * 0.03),
            Text(
              "Or with",
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: Colors.grey, fontSize: screenHeight * 0.02),
            ),
            const SizedBox(height: 12), // Match spacing between text fields
// Google Sign In button
            ElevatedButton.icon(
              onPressed: _handleGoogleSignIn,
              style: ElevatedButton.styleFrom(
                elevation: 2, // Add shadow
                backgroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                side: const BorderSide(color: Color(0xFFF1F1FA), width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                shadowColor:
                    Colors.black.withOpacity(0.3), // Customize shadow color
              ),
              icon: Image.asset(
                'assets/images/google_logo.png',
                height: 24,
              ),
              label: const Text(
                "Sign In With Google",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.03),
            Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const SignUpPage()),
                  );
                },
                child: RichText(
                  text: TextSpan(
                    text: "Don't have an account yet? ",
                    style: TextStyle(
                        fontSize: screenHeight * 0.02, color: Colors.black),
                    children: <TextSpan>[
                      TextSpan(
                        text: 'Sign Up',
                        style: TextStyle(
                          color: const Color.fromRGBO(127, 61, 255, 1),
                          fontSize: screenHeight * 0.02,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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

  Future<void> _login() async {
    if (_email.text.isEmpty || _password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    await CustomLoader.showLoaderForTask(
      context: context,
      task: () async {
        try {
          // Simple email/password login without biometric check
          final querySnapshot = await FirebaseFirestore.instance
              .collection('authentication')
              .where('email', isEqualTo: _email.text)
              .where('password', isEqualTo: _password.text)
              .get();

          if (querySnapshot.docs.isNotEmpty) {
            final userData = querySnapshot.docs.first.data();

            // Save user data to SharedPreferences
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('email', userData['email']);
            await prefs.setString('uid', userData['auth_id']);
            await prefs.setBool('is_logged_in', true);
            await prefs.setString('last_logged_in_email', _email.text);

            goToHome(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Invalid credentials')),
            );
          }
        } catch (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login failed: ${error.toString()}')),
          );
        }
      },
    );
  }

  void goToSignup(BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SignUpPage()),
      );

  void goToHome(BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
}
