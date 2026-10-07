import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/auth_service.dart';
import '../services/woocommerce_service.dart';

class OrderProvider extends ChangeNotifier {
  final _wcService = WooCommerceService();
  final _authService = AuthService();
  
  List<Order> _orders = [];
  bool _isLoading = true;
  String? _error;

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  OrderProvider() {
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final userId = await _authService.getUserId();
      if (userId != null) {
        _orders = await _wcService.getOrdersByCustomer(userId);
      }
    } catch (e) {
      _error = "Failed to load orders: ${e.toString()}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> cancelOrder(int orderId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final success = await _wcService.cancelOrder(orderId);
      if (success) {
        await fetchOrders();
      } else {
        _error = "Failed to cancel order";
        _isLoading = false;
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = "Error cancelling order: ${e.toString()}";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
