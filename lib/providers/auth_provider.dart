import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/cart_provider.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<Map<String, dynamic>> login(String username, String password) async {
    _setLoading(true);
    try {
      final result = await _authService.login(username, password);
      if (result['success']) {
        await CartProvider().loadCartFromServer();
      }
      return result;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> signup(String username, String email, String password, String phone) async {
    _setLoading(true);
    try {
      final result = await _authService.signup(username, email, password, phone);
      if (result['success'] && result['requireVerification'] != true) {
        await CartProvider().loadCartFromServer();
      }
      return result;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> verifySignup(String token, String nonce, String code, List<String> cookies, String username, String password) async {
    _setLoading(true);
    try {
      final result = await _authService.verifySignup(token, nonce, code, cookies);
      if (result['success']) {
        final loginResult = await login(username, password);
        if (!loginResult['success']) {
          return {
            'success': true,
            'loginFailed': true,
            'message': loginResult['message'] ?? 'Automatic login failed',
          };
        }
        return loginResult;
      }
      return result;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> resendVerificationCode(String token, String nonce, List<String> cookies) async {
    _setLoading(true);
    try {
      return await _authService.resendVerificationCode(token, nonce, cookies);
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> sendForgotPasswordOtp(String email) async {
    _setLoading(true);
    try {
      return await _authService.sendForgotPasswordOtp(email);
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> verifyOtpAndLogin(String email, String otp, String newPassword) async {
    _setLoading(true);
    try {
      final result = await _authService.verifyOtpAndLogin(email, otp, newPassword);
      if (result['success'] == true) {
        await CartProvider().loadCartFromServer();
      }
      return result;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
