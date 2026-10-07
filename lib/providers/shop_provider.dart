import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/woocommerce_service.dart';
import '../services/auth_service.dart';

class ShopProvider extends ChangeNotifier {
  final WooCommerceService _wooService = WooCommerceService();
  final AuthService _authService = AuthService();

  List<Product> _products = [];
  bool _isFirstOrder = true;
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;

  List<Product> get products => _products;
  bool get isFirstOrder => _isFirstOrder;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get error => _error;

  ShopProvider() {
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    _isLoading = true;
    _error = null;
    _currentPage = 1;
    _products = [];
    _hasMore = true;
    notifyListeners();

    try {
      final userId = await _authService.getUserId();

      // Run orders check and product fetch IN PARALLEL — saves ~1-2s
      final results = await Future.wait([
        _wooService.getProducts(page: 1),
        if (userId != null)
          _wooService.getOrdersByCustomer(userId)
        else
          Future.value(<dynamic>[]),
      ]);

      final initialProducts = results[0] as List<Product>;
      final orders = results[1] as List<dynamic>;

      _products = initialProducts;
      _isFirstOrder = orders.isEmpty;

      if (initialProducts.length < 20) {
        _hasMore = false;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreProducts() async {
    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    notifyListeners();

    try {
      _currentPage++;
      final newProducts = await _wooService.getProducts(page: _currentPage);

      if (newProducts.isEmpty) {
        _hasMore = false;
      } else {
        _products.addAll(newProducts);
        if (newProducts.length < 20) {
          _hasMore = false;
        }
      }
    } catch (e) {
      // Maybe handle error but don't stop hasMore if it's just a transient error?
      // For now, just stop loading.
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
