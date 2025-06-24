import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class AdminAuthController extends ChangeNotifier {
  static const String _adminTokenKey = 'admin_token';
  static const String _adminEmailKey = 'admin_email';
  static const String _adminPasswordKey = 'admin_password';
  static const String _lastLoginKey = 'admin_last_login';

  bool _isAuthenticated = false;
  String? _currentAdminEmail;
  DateTime? _lastLogin;
  String? _authToken;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  String? get currentAdminEmail => _currentAdminEmail;
  DateTime? get lastLogin => _lastLogin;
  String? get authToken => _authToken;

  // Default admin credentials (in production, use secure storage)
  static const String _defaultAdminEmail = 'admin@expensetracker.com';
  static const String _defaultAdminPassword = 'Admin@123';

  AdminAuthController() {
    _initializeAuth();
  }

  // Initialize authentication state
  Future<void> _initializeAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _authToken = prefs.getString(_adminTokenKey);
      _currentAdminEmail = prefs.getString(_adminEmailKey);

      final lastLoginStr = prefs.getString(_lastLoginKey);
      if (lastLoginStr != null) {
        _lastLogin = DateTime.parse(lastLoginStr);
      }

      // Check if token is still valid (24 hours)
      if (_authToken != null && _lastLogin != null) {
        final now = DateTime.now();
        final tokenAge = now.difference(_lastLogin!);

        if (tokenAge.inHours < 24) {
          _isAuthenticated = true;
        } else {
          await _clearAuthData();
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing auth: $e');
    }
  }

  // Admin login
  Future<bool> login(String email, String password) async {
    try {
      // Validate credentials
      if (!_validateCredentials(email, password)) {
        throw Exception('Invalid credentials');
      }

      // Generate auth token
      final token = _generateAuthToken(email);
      final now = DateTime.now();

      // Store authentication data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_adminTokenKey, token);
      await prefs.setString(_adminEmailKey, email);
      await prefs.setString(_lastLoginKey, now.toIso8601String());

      // Update state
      _isAuthenticated = true;
      _currentAdminEmail = email;
      _authToken = token;
      _lastLogin = now;

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  // Admin logout
  Future<void> logout() async {
    try {
      await _clearAuthData();

      _isAuthenticated = false;
      _currentAdminEmail = null;
      _authToken = null;
      _lastLogin = null;

      notifyListeners();
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }

  // Change admin password
  Future<bool> changePassword(
      String currentPassword, String newPassword) async {
    try {
      if (!_isAuthenticated || _currentAdminEmail == null) {
        throw Exception('Not authenticated');
      }

      // Validate current password
      if (!_validateCredentials(_currentAdminEmail!, currentPassword)) {
        throw Exception('Current password is incorrect');
      }

      // Validate new password
      if (!_isValidPassword(newPassword)) {
        throw Exception('New password does not meet requirements');
      }

      // In production, store hashed password securely
      final prefs = await SharedPreferences.getInstance();
      final hashedPassword = _hashPassword(newPassword);
      await prefs.setString(_adminPasswordKey, hashedPassword);

      return true;
    } catch (e) {
      debugPrint('Change password error: $e');
      return false;
    }
  }

  // Validate session
  bool validateSession() {
    if (!_isAuthenticated || _lastLogin == null) {
      return false;
    }

    final now = DateTime.now();
    final sessionAge = now.difference(_lastLogin!);

    if (sessionAge.inHours >= 24) {
      logout();
      return false;
    }

    return true;
  }

  // Extend session
  Future<void> extendSession() async {
    if (!_isAuthenticated) return;

    try {
      final now = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastLoginKey, now.toIso8601String());

      _lastLogin = now;
      notifyListeners();
    } catch (e) {
      debugPrint('Extend session error: $e');
    }
  }

  // Get session info
  Map<String, dynamic> getSessionInfo() {
    if (!_isAuthenticated) {
      return {'authenticated': false};
    }

    final now = DateTime.now();
    final sessionAge =
        _lastLogin != null ? now.difference(_lastLogin!) : Duration.zero;
    final remainingTime = Duration(hours: 24) - sessionAge;

    return {
      'authenticated': true,
      'email': _currentAdminEmail,
      'lastLogin': _lastLogin?.toIso8601String(),
      'sessionAge': sessionAge.inMinutes,
      'remainingMinutes': remainingTime.inMinutes,
    };
  }

  // Private helper methods
  bool _validateCredentials(String email, String password) {
    // In production, validate against secure database
    return email == _defaultAdminEmail && password == _defaultAdminPassword;
  }

  String _generateAuthToken(String email) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final data = '$email:$timestamp';
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  bool _isValidPassword(String password) {
    // Password requirements: at least 8 characters, contains uppercase, lowercase, number, special char
    if (password.length < 8) return false;

    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasNumber = password.contains(RegExp(r'[0-9]'));
    final hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    return hasUppercase && hasLowercase && hasNumber && hasSpecialChar;
  }

  Future<void> _clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_adminTokenKey);
    await prefs.remove(_adminEmailKey);
    await prefs.remove(_lastLoginKey);
  }

  // Reset admin password to default (emergency use only)
  Future<bool> resetToDefaultPassword() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_adminPasswordKey);
      return true;
    } catch (e) {
      debugPrint('Reset password error: $e');
      return false;
    }
  }
}
