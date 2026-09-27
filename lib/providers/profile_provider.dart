import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/woocommerce_service.dart';
import '../models/customer.dart';

class ProfileProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final WooCommerceService _wcService = WooCommerceService();

  bool _isLoggedIn = false;
  String? _userName;
  Customer? _customer;
  bool _isLoading = false;
  File? _pickedImage;

  bool get isLoggedIn => _isLoggedIn;
  String? get userName => _userName;
  Customer? get customer => _customer;
  bool get isLoading => _isLoading;
  File? get pickedImage => _pickedImage;
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) super.notifyListeners();
  }

  ProfileProvider() {
    checkStatus();
  }

  Future<void> checkStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      _isLoggedIn = await _authService.isLoggedIn();
      _userName = await _authService.getUserName();
      final userId = await _authService.getUserId();

      if (_isLoggedIn && userId != null) {
        final customerData = await _wcService.getCustomerData(userId);
        if (customerData != null) {
          _customer = Customer.fromJson(customerData);
          
          // Fetch actual loyalty balance
          final token = await _authService.getToken();
          final email = await _authService.getUserEmail();
          
          // Try to get balance from loyalty endpoints
          int balance = await _wcService.getLoyaltyBalance(userId, token: token);
          
          // Fallback: If balance is 0, check points history to be sure
          if (balance == 0) {
            final history = await _wcService.getPointsHistory(userId, token: token, email: email);
            if (history.isNotEmpty) {
              int calculatedBalance = 0;
              for (var entry in history) {
                final ptsStr = entry.points.replaceAll('+', '').replaceAll('-', '').trim();
                final pts = int.tryParse(ptsStr) ?? 0;
                if (entry.points.contains('-')) {
                  calculatedBalance -= pts;
                } else {
                  calculatedBalance += pts;
                }
              }
              if (calculatedBalance > 0) balance = calculatedBalance;
            }
          }
          
          if (balance > 0 || _customer!.points == 0) {
            _customer = _customer!.copyWith(points: balance);
          }
        }
      } else {
        _customer = null;
      }
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _pickedImage = null;
    await checkStatus();
  }

  Future<bool> deleteAccount() async {
    _isLoading = true;
    notifyListeners();
    final result = await _authService.deleteAccount();
    if (result['success'] == true) {
      _pickedImage = null;
      await checkStatus();
    } else {
      _isLoading = false;
      notifyListeners();
    }
    return result['success'] == true;
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );
      
      if (pickedFile != null) {
        _pickedImage = File(pickedFile.path);
        notifyListeners();
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }
}
