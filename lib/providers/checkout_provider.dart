import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_provider.dart';
import '../models/order.dart';
import '../services/woocommerce_service.dart';
import '../services/auth_service.dart';
import '../models/customer.dart';

class CheckoutProvider extends ChangeNotifier {
  final WooCommerceService _wooService = WooCommerceService();
  final AuthService _authService = AuthService();
  final CartProvider _cart = CartProvider();

  bool _isLoading = false;
  String _selectedState = 'Tamil Nadu';

  final List<String> _states = [
    'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
    'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka',
    'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram',
    'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu',
    'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal'
  ];

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final companyController = TextEditingController();
  final address1Controller = TextEditingController();
  final address2Controller = TextEditingController();
  final cityController = TextEditingController();
  final postcodeController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();

  bool get isLoading => _isLoading;
  String get selectedState => _selectedState;
  List<String> get states => _states;

  void setSelectedState(String state) {
    _selectedState = state;
    notifyListeners();
  }

  Future<void> loadUserDetails() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedEmail = prefs.getString('user_email') ?? '';
      
      // Attempt to extract phone from cachedEmail if it's the firebase dummy email
      String cachedPhone = '';
      if (cachedEmail.contains('@winleaf-tea.firebaseapp.com')) {
        cachedPhone = cachedEmail.split('@')[0];
        if (cachedPhone.startsWith('+91')) {
          cachedPhone = cachedPhone.substring(3); // Remove +91
        }
      }
      
      // Set initial values from cache
      emailController.text = cachedEmail;
      phoneController.text = cachedPhone;

      final userId = await _authService.getUserId();
      if (userId != null) {
        final data = await _wooService.getCustomerData(userId);
        if (data != null) {
          final customer = Customer.fromJson(data);
          final billing = customer.billing;
          
          if (billing != null) {
            firstNameController.text = billing.firstName ?? '';
            lastNameController.text = billing.lastName ?? '';
            companyController.text = billing.company ?? '';
            address1Controller.text = billing.address1 ?? '';
            address2Controller.text = billing.address2 ?? '';
            cityController.text = billing.city ?? '';
            postcodeController.text = billing.postcode ?? '';
            
            if (billing.phone != null && billing.phone!.isNotEmpty) {
              phoneController.text = billing.phone!;
            } else if (cachedPhone.isNotEmpty) {
              phoneController.text = cachedPhone;
            }
            
            if (billing.email != null && billing.email!.isNotEmpty) {
              emailController.text = billing.email!;
            } else if (customer.email.isNotEmpty) {
              emailController.text = customer.email;
            } else if (cachedEmail.isNotEmpty) {
              emailController.text = cachedEmail;
            }
            
            if (billing.state != null && billing.state!.isNotEmpty) {
              // Try to match the state from the list
              if (_states.contains(billing.state)) {
                _selectedState = billing.state!;
              } else {
                // If it's a code or variations, we might need a mapping, 
                // but for now let's just use it if it exists in the list.
              }
            }
          } else {
            // Fallback to basic customer info if billing is empty
            firstNameController.text = customer.firstName;
            lastNameController.text = customer.lastName;
            if (customer.email.isNotEmpty) {
              emailController.text = customer.email;
            } else if (cachedEmail.isNotEmpty) {
              emailController.text = cachedEmail;
            }
          }
        }
      }
    } catch (e) {
      print('Error loading user details for checkout: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Order?> placeOrder() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = await _authService.getUserId();

      final billing = Address(
        firstName: firstNameController.text,
        lastName: lastNameController.text,
        company: companyController.text,
        address1: address1Controller.text,
        address2: address2Controller.text,
        city: cityController.text,
        state: _selectedState,
        postcode: postcodeController.text,
        email: emailController.text,
        phone: phoneController.text,
      );

      // Build line items — detect subscription items via extraData
      final lineItems = _cart.items.map((item) {
        // Base price = billing price / 1.05 (remove 5% GST so WC recalculates correctly)
        double basePrice = item.price / 1.05;

        return OrderItem(
          productId: item.id,
          quantity: item.quantity,
          total: (basePrice * item.quantity).toStringAsFixed(2),
        );
      }).toList();

      // Find subscription cart items
      final subscriptionCartItems = _cart.items.where((item) {
        if (item.extraData == null) return false;
        final subKey = 'convert_to_sub_${item.id}';
        return item.extraData!.containsKey(subKey);
      }).toList();

      final bool hasSubscription = subscriptionCartItems.isNotEmpty;

      // Create the regular WooCommerce order first
      final order = Order(
        lineItems: lineItems,
        billing: billing,
        customerId: userId ?? 0,
        status: 'pending',
        setPaid: false,
        metaData: [
          {'key': '_created_via', 'value': 'checkout'},
          if (hasSubscription) {'key': '_wcs_subscription_order', 'value': 'yes'},
        ],
      );

      final createdOrder = await _wooService.createOrder(order);

      if (createdOrder != null) {
        // Step 2: Create a WooCommerce Subscription for each subscription item
        if (hasSubscription) {
          for (final subCartItem in subscriptionCartItems) {
            final subKey = 'convert_to_sub_${subCartItem.id}';
            final subVal = subCartItem.extraData![subKey].toString();
            // subVal is like '3_month', '6_month', '1_year'

            String billingPeriod = 'month';
            String billingInterval = '1';

            if (subVal == '1_year') {
              billingPeriod = 'year';
              billingInterval = '1';
            } else {
              // '3_month' → interval=3, period=month
              final parts = subVal.split('_');
              billingInterval = parts[0]; // '3' or '6'
              billingPeriod = parts[1];   // 'month'
            }

            // Base price without GST (matches confirmed API structure)
            final basePrice = subCartItem.price / 1.05;

            final subData = {
              'customer_id': userId ?? 0,
              'parent_id': createdOrder.id,        // Link to the parent order
              'status': 'on-hold',                  // On hold until payment confirmed
              'billing_period': billingPeriod,       // 'month' or 'year'
              'billing_interval': billingInterval,   // '3' for every 3 months
              'payment_method': 'phonepe',
              'payment_method_title': 'PhonePe Payment Solutions',
              'billing': billing.toJson(),
              'shipping': billing.toJson(),
              'line_items': [
                {
                  'product_id': subCartItem.id,
                  'quantity': subCartItem.quantity,
                  'total': (basePrice * subCartItem.quantity).toStringAsFixed(2),
                }
              ],
            };

            print('DEBUG: Creating subscription for ${subCartItem.name} - period: $billingPeriod, interval: $billingInterval, total: ${(basePrice * subCartItem.quantity).toStringAsFixed(2)}');
            final subResult = await _wooService.createSubscription(subData);
            if (subResult != null) {
              print('DEBUG: Subscription created successfully - ID: ${subResult['id']}');
            } else {
              print('DEBUG: Subscription creation FAILED');
            }
          }
        }

        _cart.clear();
        return createdOrder;
      }

      return null;
    } catch (e) {
      print('Error placing order: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    companyController.dispose();
    address1Controller.dispose();
    address2Controller.dispose();
    cityController.dispose();
    postcodeController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }
}
