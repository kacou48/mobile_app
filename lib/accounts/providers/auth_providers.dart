import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tadiago/accounts/models/user_models.dart';
import 'package:tadiago/accounts/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  String? _accessToken;
  String? _refreshToken;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  //bool _isDeleting = false;
  //bool get isDeleting => _isDeleting;

  bool _isGoogleLoading = false;
  bool get isGoogleLoading => _isGoogleLoading;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isInitialized => _isInitialized;

  String? _temporaryEmail;
  String? get temporaryEmail => _temporaryEmail;

  String? _passwordTemporaryToken;
  String? get passwordTemporaryToken => _passwordTemporaryToken;

  String? _profileImageUrl;
  String? get profileImageUrl => _profileImageUrl;

  // Initialize authentication state logout
  Future<void> initializeAuth() async {
    if (_isInitialized) return;

    _setLoading(true);

    try {
      await AuthService.loadUser();
      await loadTokens();

      if (_accessToken != null) {
        final isValid = await AuthService.refreshToken();
        if (!isValid) {
          await _clearAuthState();
        } else {
          await AuthService.loadUser();
        }
      }
    } catch (e) {
      debugPrint('Auth initialization error: $e');
      _setError('Authentication initialization failed');
      await _clearAuthState();
    } finally {
      _isInitialized = true;
      _setLoading(false);
    }
  }

  // Load tokens from storage loginWithGoogl
  Future<void> loadTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString('auth_token');
      _refreshToken = prefs.getString('refresh_token');

      debugPrint("loadtoken: $_accessToken");

      if (_refreshToken != null) {
        final refreshed = await AuthService.refreshToken();
        if (refreshed) {
          final updatedPrefs = await SharedPreferences.getInstance();
          _accessToken = updatedPrefs.getString('auth_token');
          _user = AuthService.currentUser;
        } else {
          await _clearAuthState();
        }
      }
    } catch (e) {
      debugPrint('Error loading tokens: $e');
      await _clearAuthState();
    }
    notifyListeners();
  }

  Future<String?> insistToGetToken() async {
    if (_accessToken == null) {
      await loadTokens();
    }
    return _accessToken;
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setGoogleLoading(bool loading) {
    _isGoogleLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> _clearAuthState() async {
    _user = null;
    _accessToken = null;
    _refreshToken = null;
    _temporaryEmail = null;
    await AuthService.clearTokens();
    debugPrint("accessToken suprimé");
    notifyListeners();
  }

  Future<String?> _getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('refresh_token');
  }

  Future<void> updateUser(Map<String, dynamic> userData) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_user != null) {
        _user = await AuthService.updateUser(_user!.id, userData);
        notifyListeners();
      }
    } catch (e) {
      _error = 'Error updating user: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> updateProfileImage(File imageFile) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String? newImageUrl = await AuthService.updateProfileImage(imageFile);
      if (newImageUrl != null) {
        _profileImageUrl = newImageUrl;
        notifyListeners();
        return newImageUrl;
      } else {
        _error = "Impossible de mettre à jour l'image.";
      }
    } catch (e) {
      _error = "Erreur lors de la mise à jour de l'image: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return null;
  }

  //Googl Login manager
  Future<bool> loginWithGoogle() async {
    _setGoogleLoading(true);
    _clearError();
    try {
      final result = await AuthService.signInWithGoogle();
      if (result['success']) {
        _user = result['user'];
        _accessToken = AuthService.token;
        _refreshToken = await _getRefreshToken();
        _clearError();
        return true;
      } else {
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setError('Login failed. Please try again.');
      return false;
    } finally {
      _setGoogleLoading(false);
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await AuthService.login(email, password);

      if (result['success']) {
        _user = result['user'];
        _accessToken = AuthService.token;
        _refreshToken = await _getRefreshToken();
        _clearError();

        return true;
      } else {
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setError('Login failed. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String firstname,
    String? telephone,
    String? civility,
    String? status,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await AuthService.register(
        email: email,
        password: password,
        name: name,
        firstname: firstname,
        telephone: telephone,
        civility: civility,
        status: status,
      );

      if (result['success']) {
        _temporaryEmail = result['email'];
        _error = null;
        notifyListeners();
        return true;
      } else {
        _error = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Une erreur est survenue';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String? getTemporaryEmail() {
    return _temporaryEmail;
  }

  void clearTemporaryEmail() {
    _temporaryEmail = null;
    notifyListeners();
  }

  Future<void> logout(BuildContext context) async {
    _setLoading(true);
    try {
      await AuthService.logout();
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      await _clearAuthState();
      _setLoading(false);

      // Rediriger vers la page de login après la déconnexion
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/login_page');
      }
    }
  }

  Future<Map<String, dynamic>> getVerificationCode(String email) async {
    try {
      final result = await AuthService.getVerifyCode({'email': email});
      return result;
    } catch (e) {
      // Handle the exception, e.g., set an error message
      _error = e.toString();
      notifyListeners();
      return {'success': false, 'message': _error};
    }
  }

  Future<Map<String, dynamic>> toActivateUser(
      String email, String verificationCode) async {
    try {
      final result = await AuthService.toActiveUser(
          {'email': email, 'verification_code': verificationCode});
      return result;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return {'success': false, 'message': _error};
    }
  }

  Future<Map<String, dynamic>> sendResetPassWord(String email) async {
    try {
      final result = await AuthService.sendResetPassWord({'email': email});
      if (result["success"]) {
        _passwordTemporaryToken = result["jwt_token_password"];
      }
      return result;
    } catch (e) {
      // Handle the exception, e.g., set an error message
      _error = e.toString();
      notifyListeners();
      return {'success': false, 'message': _error};
    }
  }

  Future<Map<String, dynamic>> sendResetPassWordVerify(
      String otpCode, String password) async {
    try {
      final data = {
        "jwt_token_password": _passwordTemporaryToken,
        "otp_code": otpCode,
        "password": password,
      };
      final result = await AuthService.sendResetPassWordVerify(data);
      return result;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return {'success': false, 'message': _error};
    }
  }

  Future<Map<String, dynamic>> sendNewPassWord(
      String newPassword, String oldPassword) async {
    try {
      final data = {"new_password": newPassword, "old_password": oldPassword};
      final result = await AuthService.sendNewPassWord(data);
      return result;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return {'success': false, 'message': _error};
    }
  }

  Future<void> deleteMyAccount(BuildContext context, int userId) async {
    _setLoading(true);
    _error = null;
    notifyListeners();

    try {
      final result = await AuthService.deleteMyAccount(userId);

      if (result["success"]) {
        await AuthService.logout();
        await _clearAuthState();
        _setLoading(false);

        // Rediriger vers la page de login après la déconnexion
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/login_page');
        }
      } else {
        _error = result['message'];
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
