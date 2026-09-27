import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../models/testimonial.dart';
import '../models/customer.dart';
import '../services/woocommerce_service.dart';
import '../services/auth_service.dart';

class HomeProvider extends ChangeNotifier {
  final WooCommerceService _wooService = WooCommerceService();
  final AuthService _authService = AuthService();

  List<Product>? _featuredProducts;
  List<Testimonial>? _testimonials;
  int? _points;
  bool _isLoadingProducts = false;
  bool _isLoadingTestimonials = false;
  bool _isLoadingPoints = false;
  String? _error;

  List<Product>? get featuredProducts => _featuredProducts;
  List<Testimonial>? get testimonials => _testimonials;
  int? get points => _points;
  bool get isLoadingProducts => _isLoadingProducts;
  bool get isLoadingTestimonials => _isLoadingTestimonials;
  bool get isLoadingPoints => _isLoadingPoints;
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  HomeProvider() {
    // Show fallback testimonials INSTANTLY — no spinner, no wait
    _testimonials = Testimonial.fallbacks;
    // Load products from cache first, then fetch fresh ones
    _initFeaturedProducts();
    // Points and real testimonials load in background — don't block home content
    _loadInBackground();
  }

  Future<void> _initFeaturedProducts() async {
    await _loadCachedProducts();
    await fetchFeaturedProducts();
  }

  Future<void> _loadCachedProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString('cached_featured_products');
      if (cachedJson != null) {
        final List<dynamic> decoded = json.decode(cachedJson);
        _featuredProducts = decoded.map((json) => Product.fromJson(json)).toList();
        notifyListeners();
      }
    } catch (e) {
      print('Error loading cached products: $e');
    }
  }

  void _loadInBackground() async {
    // Replace fallback testimonials with real ones silently
    fetchTestimonials();
    // Load loyalty points separately
    fetchPoints();
  }

  /// Used by pull-to-refresh on home screen
  Future<void> fetchAll() async {
    await Future.wait([
      fetchFeaturedProducts(),
      fetchTestimonials(),
      fetchPoints(),
    ]);
  }

  Future<void> fetchFeaturedProducts() async {
    if (_featuredProducts == null || _featuredProducts!.isEmpty) {
      _isLoadingProducts = true;
      notifyListeners();
    }
    try {
      _featuredProducts = await _wooService.getProducts(perPage: 5);
    } catch (e) {
      _error = 'Error loading products: $e';
    } finally {
      _isLoadingProducts = false;
      notifyListeners();
    }
  }

  Future<void> fetchTestimonials() async {
    _isLoadingTestimonials = true;
    notifyListeners();
    try {
      _testimonials = await _wooService.getReviews();
    } catch (e) {
      _error = 'Error loading testimonials: $e';
    } finally {
      _isLoadingTestimonials = false;
      notifyListeners();
    }
  }

  Future<void> fetchPoints() async {
    final userId = await _authService.getUserId();
    final token = await _authService.getToken();
    final email = await _authService.getUserEmail();
    
    if (userId != null) {
      _isLoadingPoints = true;
      notifyListeners();
      try {
        _points = await _wooService.getCustomerPoints(userId, token: token, email: email);
      } catch (e) {
        _error = 'Error loading points: $e';
      } finally {
        _isLoadingPoints = false;
        notifyListeners();
      }
    }
  }
}
