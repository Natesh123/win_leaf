import 'package:flutter/material.dart';
import '../services/woocommerce_service.dart';
import '../services/auth_service.dart';
import '../models/subscription.dart';

class SubscriptionsProvider extends ChangeNotifier {
  final WooCommerceService _wcService = WooCommerceService();
  final AuthService _authService = AuthService();

  List<Subscription> _subscriptions = [];
  bool _isLoading = false;
  String? _error;

  List<Subscription> get subscriptions => _subscriptions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchSubscriptions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId = await _authService.getUserId();
      if (userId != null) {
        _subscriptions = await _wcService.getSubscriptions(userId);
      } else {
        _error = "User not logged in";
      }
    } catch (e) {
      _error = "Failed to load subscriptions: $e";
      print('Error in SubscriptionsProvider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
