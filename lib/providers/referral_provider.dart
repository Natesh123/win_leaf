import 'package:flutter/material.dart';
import '../models/referral_data.dart';
import '../services/auth_service.dart';
import '../services/woocommerce_service.dart';

class ReferralProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final WooCommerceService _wcService = WooCommerceService();

  bool _isLoading = true;
  ReferralData _referralData = ReferralData.empty();
  int? _userId;

  bool get isLoading => _isLoading;
  ReferralData get referralData => _referralData;
  int? get userId => _userId;

  ReferralProvider() {
    fetchData();
  }

  Future<void> fetchData() async {
    _isLoading = true;
    notifyListeners();

    _userId = await _authService.getUserId();
    final token = await _authService.getToken();
    
    print('DEBUG: ReferralProvider - Fetching data for User ID: $_userId');
    print('DEBUG: ReferralProvider - JWT Token found: ${token != null && token.isNotEmpty}');

    if (_userId != null) {
      _referralData = await _wcService.getReferralData(_userId!, token: token);
      print('DEBUG: ReferralProvider - Successfully fetched ${_referralData.coupons.length} coupons');
    }

    _isLoading = false;
    notifyListeners();
  }
}
