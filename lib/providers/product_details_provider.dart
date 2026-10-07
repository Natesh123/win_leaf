import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/testimonial.dart';
import '../models/product.dart';
import '../services/woocommerce_service.dart';
import '../services/auth_service.dart';

class SubscriptionPlan {
  final String name;
  final int months;          // billing interval in months (e.g. 3)
  final String period;       // 'month' or 'year'
  final int intervalCount;   // e.g. 3 for "every 3 months"
  final double billingPrice; // amount charged per billing cycle (e.g. ₹98 every 3 months)
  final double regularPrice; // undiscounted product price (for crossed-out display)
  final int savingsPercent;

  SubscriptionPlan({
    required this.name,
    required this.months,
    this.period = 'month',
    this.intervalCount = 1,
    required this.billingPrice,
    required this.regularPrice,
    required this.savingsPercent,
  });

  /// Total amount for full plan period — matches website label
  /// e.g. ₹149 × 3 × 0.9 = ₹402 for "3 Months Plan" (calculated WITHOUT intermediate rounding)
  double get planTotalPrice {
    if (period == 'year') {
      // Yearly: billingPrice is already the annual total (regularPrice × 12 × discount)
      return billingPrice;
    }
    // Monthly plans: compute total WITHOUT intermediate rounding to avoid ₹762 vs ₹760 errors
    // e.g. ₹149 × 6 × 0.85 = ₹759.9 → ₹760 (not ₹127 × 6 = ₹762)
    return (regularPrice * intervalCount * (1 - savingsPercent / 100)).roundToDouble();
  }

  /// Crossed-out original price for the same period (no discount)
  double get planOriginalPrice {
    if (period == 'year') return (regularPrice * 12 * intervalCount).roundToDouble();
    return (regularPrice * intervalCount).roundToDouble();
  }

  /// Human-readable billing description matching WEBSITE format
  /// Website: "3 Months Plan – ₹294 (Save 10%)"
  String get billingLabel {
    final total = planTotalPrice.toStringAsFixed(0);
    if (period == 'year') return '₹$total / year';
    return '₹$total every $intervalCount months';
  }

  /// Dropdown label: "3 Months Plan – ₹294 (Save 10%)"
  String get label => '$name – ₹${planTotalPrice.toStringAsFixed(0)} (Save $savingsPercent%)';

  // Keep for backward compat
  double get monthlyPrice => billingPrice;
  double get totalPrice => planTotalPrice;
}

class ProductDetailsProvider extends ChangeNotifier {
  final Product product;
  final WooCommerceService _wcService = WooCommerceService();
  final AuthService _authService = AuthService();

  String _purchaseOption = 'One-time';
  
  List<SubscriptionPlan> _plans = [];

  late SubscriptionPlan _selectedPlan;
  int _selectedImageIndex = 0;
  String _activeTab = 'Description';
  List<Testimonial> _productReviews = [];
  bool _isLoadingReviews = false;
  bool _reviewsFetched = false;
  int _selectedRating = 0;
  bool _isSubmittingReview = false;

  ProductDetailsProvider(this.product) {
    _initializePlans();
    _selectedPlan = _plans[0];
    _fetchApiPlans();
  }

  int get productId => product.id;

  void _initializePlans() {
    // Fallback plans computed from product.price until API data loads
    double price = product.price;
    _plans = [
      SubscriptionPlan(
        name: '3 Months Plan',
        months: 3,
        period: 'month',
        intervalCount: 3,
        billingPrice: (price * 0.9).roundToDouble(),
        regularPrice: price,
        savingsPercent: 10,
      ),
      SubscriptionPlan(
        name: '6 Months Plan',
        months: 6,
        period: 'month',
        intervalCount: 6,
        billingPrice: (price * 0.85).roundToDouble(),
        regularPrice: price,
        savingsPercent: 15,
      ),
      SubscriptionPlan(
        name: '12 Months Plan',
        months: 12,
        period: 'year',
        intervalCount: 1,
        billingPrice: (price * 12 * 0.8).roundToDouble(), // annual total ₹1,430 not ₹119
        regularPrice: price,
        savingsPercent: 20,
      ),
    ];
  }

  void _fetchApiPlans() {
    // Reads _wcsatt_schemes from WooCommerce API (correct key for All Products for WC Subscriptions)
    // API structure confirmed for product 4961:
    //   { subscription_period_interval: '3', subscription_period: 'month', subscription_discount: 10 }
    //   → billingPrice = ₹98 every 3 months (per cycle)
    //   → planTotalPrice = ₹98 × 3 = ₹294 (matches website label)
    try {
      // Try _wcsatt_schemes first (the real data key), fallback to _satt_data
      final schemeMeta = product.metaData.firstWhere(
        (m) => m['key'] == '_wcsatt_schemes',
        orElse: () => product.metaData.firstWhere(
          (m) => m['key'] == '_satt_data',
          orElse: () => null,
        ),
      );

      if (schemeMeta != null && schemeMeta['value'] != null) {
        final List<dynamic> schemes = [];

        final val = schemeMeta['value'];
        if (val is String) {
          final decoded = json.decode(val);
          if (decoded is List) schemes.addAll(decoded);
          else if (decoded is Map) schemes.addAll(decoded.values);
        } else if (val is List) {
          schemes.addAll(val);
        } else if (val is Map) {
          // _wcsatt_schemes is a List, _satt_data may be a Map
          schemes.addAll(val.values);
        }

        if (schemes.isNotEmpty) {
          List<SubscriptionPlan> apiPlans = [];

          for (var item in schemes) {
            if (item is! Map) continue;
            // _wcsatt_schemes uses 'subscription_period_interval' and 'subscription_discount'
            // _satt_data uses nested 'subscription_scheme' map
            final scheme = item['subscription_scheme'] ?? item;
            if (scheme is! Map) continue;

            final intervalCount = int.tryParse(
              (scheme['subscription_period_interval'] ?? scheme['interval'] ?? '0').toString()
            ) ?? 0;
            final period = (scheme['subscription_period'] ?? scheme['period'] ?? 'month').toString();
            // _wcsatt_schemes uses 'subscription_discount'; _satt_data uses 'discount'
            final discount = double.tryParse(
              (scheme['subscription_discount'] ?? scheme['discount'] ?? '0').toString()
            ) ?? 0.0;

            if (intervalCount > 0) {
              // billingPrice = amount charged per billing cycle (what WooCommerce actually charges)
              // For monthly plans: per-cycle amount = regularPrice × discount
              //   e.g. ₹149 × 0.9 = ₹134.10 ≈ ₹134 charged every 3 months
              // For yearly plans: annual total = regularPrice × 12 × discount
              //   e.g. ₹149 × 12 × 0.8 = ₹1,430 charged once per year
              double billingPrice;
              if (period == 'year') {
                // Annual billing: multiply by 12 months so WC charges annual total
                billingPrice = (product.price * 12 * (1 - discount / 100)).roundToDouble();
              } else {
                // Monthly billing: per-cycle = discounted monthly price
                billingPrice = (product.price * (1 - discount / 100)).roundToDouble();
              }

              int months = intervalCount;
              if (period == 'year') months = intervalCount * 12;

              String name;
              if (period == 'year') {
                name = '${intervalCount == 1 ? 'Yearly' : '$intervalCount Year'} Plan (Best Value)';
              } else if (intervalCount == 6) {
                name = '6 Months Plan (Most Popular)';
              } else {
                name = '$intervalCount Months Plan';
              }

              apiPlans.add(SubscriptionPlan(
                name: name,
                months: months,
                period: period,
                intervalCount: intervalCount,
                billingPrice: billingPrice,
                regularPrice: product.price,
                savingsPercent: discount.toInt(),
              ));

              print('DEBUG plan: $name → billingPrice=₹${billingPrice.toStringAsFixed(0)}, planTotal=₹${(period == "year" ? billingPrice : billingPrice * intervalCount).toStringAsFixed(0)}, discount=$discount%');
            }
          }

          if (apiPlans.isNotEmpty) {
            apiPlans.sort((a, b) => a.months.compareTo(b.months));
            _plans = apiPlans;
            _selectedPlan = _plans.firstWhere(
              (p) => p.months == _selectedPlan.months,
              orElse: () => _plans[0],
            );
            notifyListeners();
          }
        }
      }
    } catch (e) {
      print('Error parsing SATT subscription plans: $e');
      // Falls back to _initializePlans() values
    }
  }

  String get purchaseOption => _purchaseOption;
  SubscriptionPlan get selectedPlan => _selectedPlan;
  List<SubscriptionPlan> get plans => _plans;
  int get selectedImageIndex => _selectedImageIndex;
  String get activeTab => _activeTab;
  List<Testimonial> get productReviews => _productReviews;
  bool get isLoadingReviews => _isLoadingReviews;
  int get selectedRating => _selectedRating;
  bool get isSubmittingReview => _isSubmittingReview;

  void setPurchaseOption(String option) {
    _purchaseOption = option;
    notifyListeners();
  }

  void setSelectedPlan(SubscriptionPlan plan) {
    _selectedPlan = plan;
    notifyListeners();
  }

  void setSelectedImageIndex(int index) {
    _selectedImageIndex = index;
    notifyListeners();
  }

  void setActiveTab(String tab) {
    _activeTab = tab;
    if (tab == 'Reviews') {
      fetchReviews();
    }
    notifyListeners();
  }

  void setSelectedRating(int rating) {
    _selectedRating = rating;
    notifyListeners();
  }

  Future<void> fetchReviews({bool force = false}) async {
    if (_reviewsFetched && !force) return;

    _isLoadingReviews = true;
    notifyListeners();

    try {
      _productReviews = await _wcService.getProductReviews(productId);
      _reviewsFetched = true;
    } catch (e) {
      print('Error fetching reviews: $e');
    } finally {
      _isLoadingReviews = false;
      notifyListeners();
    }
  }

  Future<bool> submitReview(String comment) async {
    if (_selectedRating == 0 || comment.trim().isEmpty) return false;

    _isSubmittingReview = true;
    notifyListeners();

    try {
      final token = await (await SharedPreferences.getInstance()).getString('jwt_token') ?? '';
      final user = await _authService.getMe(token);
      
      final success = await _wcService.createReview(
        productId: productId,
        review: comment.trim(),
        reviewer: user?['name']?.toString() ?? 'Guest',
        reviewerEmail: user?['email']?.toString() ?? 'guest@example.com',
        rating: _selectedRating,
      );

      if (success) {
        _selectedRating = 0;
        await fetchReviews(force: true);
        return true;
      }
      return false;
    } catch (e) {
      print('Error submitting review: $e');
      return false;
    } finally {
      _isSubmittingReview = false;
      notifyListeners();
    }
  }
}
