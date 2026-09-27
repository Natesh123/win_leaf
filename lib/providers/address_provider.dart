import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../services/auth_service.dart';
import '../services/woocommerce_service.dart';

class AddressProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final WooCommerceService _woocommerceService = WooCommerceService();

  Customer? _customer;
  bool _isLoading = true;
  String? _error;

  Customer? get customer => _customer;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AddressProvider() {
    fetchAddresses();
  }

  Future<void> fetchAddresses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        _error = 'Please log in to view your addresses.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final data = await _woocommerceService.getCustomerData(userId);
      if (data != null) {
        _customer = Customer.fromJson(data);
        _isLoading = false;
      } else {
        _error = 'Failed to load address data.';
        _isLoading = false;
      }
    } catch (e) {
      _error = 'An error occurred: $e';
      _isLoading = false;
    }
    notifyListeners();
  }
}
