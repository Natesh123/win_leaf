import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../models/order.dart';
import '../services/auth_service.dart';
import '../services/woocommerce_service.dart';
import '../models/point_history.dart';

class RewardsProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final WooCommerceService _wcService = WooCommerceService();

  bool _isLoading = true;
  Customer? _customer;
  List<Order> _recentOrders = [];
  List<PointHistory> _pointsHistory = [];
  int? _userId;

  bool get isLoading => _isLoading;
  Customer? get customer => _customer;
  List<Order> get recentOrders => _recentOrders;
  List<PointHistory> get pointsHistory => _pointsHistory;
  int? get userId => _userId;

  RewardsProvider() {
    fetchData();
  }

  Future<void> fetchData() async {
    _isLoading = true;
    notifyListeners();
    
    _userId = await _authService.getUserId();
    
    if (_userId != null) {
      final token = await _authService.getToken();
      final email = await _authService.getUserEmail();
      
      try {
        final results = await Future.wait([
          _wcService.getCustomerData(_userId!),
          _wcService.getOrdersByCustomer(_userId!),
          _wcService.getPointsHistory(_userId!, token: token, email: email),
          _wcService.getCustomerPoints(_userId!, token: token, email: email),
        ]);
        
        final customerData = results[0] as Map<String, dynamic>?;
        final ordersData = results[1] as List<Order>;
        final historyData = results[2] as List<PointHistory>;
        final pointsBalance = results[3] as int;
        
        if (customerData != null) {
          _customer = Customer.fromJson(customerData);
        }
        
        _recentOrders = ordersData;
        _recentOrders.sort((a, b) => (b.dateCreated ?? DateTime.now()).compareTo(a.dateCreated ?? DateTime.now()));
        if (_recentOrders.length > 5) {
          _recentOrders = _recentOrders.sublist(0, 5);
        }
        
        _pointsHistory = historyData;
        
        if (_customer != null) {
          _customer = _customer!.copyWith(points: pointsBalance);
        }
      } catch (e) {
        print('Error fetching rewards data: $e');
      }
    }

    _isLoading = false;
    notifyListeners();
  }
}
