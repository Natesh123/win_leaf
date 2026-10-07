import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/product.dart';
import '../models/testimonial.dart';
import '../models/category.dart' as wc;
import '../models/order.dart';
import '../models/referral_data.dart';
import '../models/referral_coupon.dart';
import '../models/subscription.dart';
import '../models/point_history.dart';
import '../models/customer.dart';


import 'package:shared_preferences/shared_preferences.dart';

class WooCommerceService {
  final String _baseUrl = (dotenv.env['WC_URL'] ?? '').endsWith('/') 
      ? (dotenv.env['WC_URL'] ?? '').substring(0, (dotenv.env['WC_URL'] ?? '').length - 1) 
      : (dotenv.env['WC_URL'] ?? '');
  final String _consumerKey = dotenv.env['WC_CONSUMER_KEY'] ?? '';
  final String _consumerSecret = dotenv.env['WC_CONSUMER_SECRET'] ?? '';

  String get _authHeader {
    String creds = '$_consumerKey:$_consumerSecret';
    String encoded = base64Encode(utf8.encode(creds));
    return 'Basic $encoded';
  }

  Future<List<Product>> getProducts({int page = 1, int perPage = 20, int? categoryId}) async {
    try {
      String url = '$_baseUrl/wp-json/wc/v3/products?page=$page&per_page=$perPage';
      if (categoryId != null) {
        url += '&category=$categoryId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        print('WooCommerce API: Fetched ${data.length} products');

        // Cache the first page of general products (Featured Products on Home Screen)
        if (page == 1 && perPage == 5 && categoryId == null) {
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('cached_featured_products', response.body);
          } catch (e) {
            print('Error saving products cache: $e');
          }
        }

        return data.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching products: $e');
      return [];
    }
  }

  Future<List<wc.category>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/wp-json/wc/v3/products/categories?per_page=100'),
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((c) => wc.category.fromJson(c)).toList();
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }

  Future<List<Testimonial>> getReviews() async {
    return await getTestimonialsFromWebsite();
  }

  Future<List<Testimonial>> getProductReviews(int productId) async {
    try {
      String url = '$_baseUrl/wp-json/wc/v3/products/reviews?per_page=20';
      if (productId > 0) {
        url += '&product=$productId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        print('WooCommerce API: Fetched ${data.length} reviews for Product ID: $productId');
        if (data.isNotEmpty) {
          return data.map((json) => Testimonial.fromJson(json)).toList();
        }
      }
      
      // Fallback to scraping only if it's general reviews or no API reviews found
      if (productId == 0) {
        return await getTestimonialsFromWebsite();
      }
      return [];
    } catch (e) {
      print('Error fetching reviews: $e');
      return productId == 0 ? await getTestimonialsFromWebsite() : [];
    }
  }

  Future<bool> createReview({
    required int productId,
    required String review,
    required String reviewer,
    required String reviewerEmail,
    required int rating,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/wp-json/wc/v3/products/reviews'),
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'product_id': productId,
          'review': review,
          'reviewer': reviewer,
          'reviewer_email': reviewerEmail,
          'rating': rating,
        }),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        print('Failed to create review: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error creating review: $e');
      return false;
    }
  }

  Future<List<Testimonial>> getTestimonialsFromWebsite() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));
      if (response.statusCode != 200) return Testimonial.fallbacks;

      String html = response.body;
      List<Testimonial> results = [];

      // Regex to find swiper slides in ElementsKit Testimonial
      final slideRegex = RegExp(r'<div class="swiper-slide">([\s\S]*?)<\/div>\s*<\/div>\s*<\/div>\s*<\/div>\s*<\/div>');
      // Improved regex with more precise matching for ElementsKit structure
      final itemRegex = RegExp(r'<div class="elementskit-single-testimonial-slider[\s\S]*?<\/div>\s*<\/div>\s*<\/div>\s*<\/div>');
      
      // Let's use a simpler approach since the HTML is complex
      // Extract based on author name blocks
      final testimonialRegex = RegExp(
        r'ekit-testimonial--avatar">[\s\S]*?src="([^"]+)"[\s\S]*?elementskit-author-name">([^<]+)<\/strong>[\s\S]*?elementskit-author-des">([^<]+)<\/span>[\s\S]*?elementskit-commentor-content">[\s\S]*?<p>([^<]+)<\/p>',
        multiLine: true
      );

      final matches = testimonialRegex.allMatches(html);
      int id = 1000; // Custom ID counter for scraped items

      for (var match in matches) {
        String image = match.group(1) ?? 'https://i.pravatar.cc/150';
        String name = (match.group(2) ?? 'Customer').trim();
        String role = (match.group(3) ?? 'Valued Customer').trim();
        String comment = (match.group(4) ?? '').trim();

        results.add(Testimonial(
          id: id++,
          name: name,
          role: role,
          comment: comment,
          image: image,
          rating: 5,
        ));
      }

      if (results.isEmpty) return Testimonial.fallbacks;
      return results;
    } catch (e) {
      print('Error scraping testimonials: $e');
      return Testimonial.fallbacks;
    }
  }

  Future<Order?> createOrder(Order order) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/wp-json/wc/v3/orders'),
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
        },
        body: json.encode(order.toJson()),
      );

      if (response.statusCode == 201) {
        return Order.fromJson(json.decode(response.body));
      } else {
        print('Failed to create order: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error creating order: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> createSubscription(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/wp-json/wc/v1/subscriptions'),
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
        },
        body: json.encode(data),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        print('Failed to create subscription: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error creating subscription: $e');
      return null;
    }
  }

  /// Cancels a subscription by setting its status to 'cancelled'
  /// Uses the WooCommerce Subscriptions REST API: PUT /wc/v1/subscriptions/{id}
  Future<bool> cancelSubscription(int subscriptionId) async {
    try {
      // Strip trailing slash from base URL to avoid double-slash issue
      final baseUrl = _baseUrl.endsWith('/') ? _baseUrl.substring(0, _baseUrl.length - 1) : _baseUrl;
      final url = '$baseUrl/wp-json/wc/v1/subscriptions/$subscriptionId';
      print('DEBUG: Cancelling subscription at $url');

      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
        },
        body: json.encode({'status': 'cancelled'}),
      );

      print('DEBUG: Cancel response ${response.statusCode}: ${response.body.substring(0, response.body.length.clamp(0, 200))}');

      if (response.statusCode == 200) {
        print('Subscription $subscriptionId cancelled successfully');
        return true;
      } else {
        print('Failed to cancel subscription $subscriptionId: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error cancelling subscription $subscriptionId: $e');
      return false;
    }
  }


  Future<Order?> getOrderById(int orderId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/wp-json/wc/v3/orders/$orderId'),
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return Order.fromJson(json.decode(response.body));
      } else {
        print('Failed to fetch order: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching order by ID: $e');
      return null;
    }
  }

  Future<List<String>> getOrderNotes(int orderId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/wp-json/wc/v3/orders/$orderId/notes'),
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((note) => note['note'].toString()).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching order notes: $e');
      return [];
    }
  }

  Future<List<Order>> getOrdersByCustomer(int customerId, {int perPage = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/wp-json/wc/v3/orders?customer=$customerId&per_page=$perPage'),
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Order.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load orders: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching orders: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getCustomerData(int customerId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/wp-json/wc/v3/customers/$customerId'),
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Failed to load customer data: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching customer data: $e');
      return null;
    }
  }

  Future<bool> cancelOrder(int orderId) async {
    return await updateOrderStatus(orderId, 'cancelled');
  }

  Future<bool> updateOrderStatus(int orderId, String status) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/wp-json/wc/v3/orders/$orderId'),
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
        },
        body: json.encode({'status': status}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Failed to update order status: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error updating order status: $e');
      return false;
    }
  }

  Future<bool> markOrderAsPaid(int orderId) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/wp-json/wc/v3/orders/$orderId'),
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
        },
        body: json.encode({'set_paid': true}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error marking order as paid: $e');
      return false;
    }
  }

  // --- Cart Store API ---

  String? _lastNonce;

  Future<void> _fetchNonce({String? token}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/wp-json/wc/store/v1/cart'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      _updateNonceFromHeaders(response.headers);
      print('DEBUG: Nonce Fetch - Status: ${response.statusCode} | Nonce Found: ${_lastNonce != null}');
    } catch (e) {
      print('Error fetching nonce: $e');
    }
  }

  void _updateNonceFromHeaders(Map<String, String> headers) {
    // Standardize headers to lowercase for easier lookup
    final normalizedHeaders = headers.map((key, value) => MapEntry(key.toLowerCase(), value));
    
    // Check various common header cases for the nonce
    final nonceHeader = normalizedHeaders['nonce'] ?? 
                        normalizedHeaders['x-wc-store-api-nonce'] ?? 
                        normalizedHeaders['x-nonce'];
    
    if (nonceHeader != null && nonceHeader.isNotEmpty) {
      _lastNonce = nonceHeader;
      print('DEBUG: Nonce Updated: $_lastNonce');
    }
  }

  Future<Map<String, dynamic>?> getStoreCart(String token, {bool isRetry = false}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/wp-json/wc/store/v1/cart'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          if (_lastNonce != null) ...{
            'Nonce': _lastNonce!,
            'X-WC-Store-API-Nonce': _lastNonce!,
          },
        },
      );

      if (response.statusCode == 200) {
        _updateNonceFromHeaders(response.headers);
        return json.decode(response.body);
      } else if (!isRetry && (response.statusCode == 401 || response.statusCode == 403)) {
        print('DEBUG: getStoreCart 401/403 - Trying with fresh nonce...');
        await _fetchNonce(token: token);
        return await getStoreCart(token, isRetry: true);
      } else {
        print('Store API Cart Get Error: ${response.statusCode} | Body: ${response.body}');
      }
    } catch (e) {
      print('Error fetching store cart: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> addToStoreCart(String token, int productId, int quantity, {Map<String, dynamic>? extraData, bool isRetry = false}) async {
    try {
      if (_lastNonce == null) await _fetchNonce(token: token);

      final Map<String, dynamic> body = {
        'id': productId,
        'quantity': quantity,
      };

      if (extraData != null) {
        body.addAll(extraData);
        // Also include in a 'request' field which many plugins expect
        body['request'] = extraData;
      }


      final response = await http.post(
        Uri.parse('$_baseUrl/wp-json/wc/store/v1/cart/add-item'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          if (_lastNonce != null) ...{
            'Nonce': _lastNonce!,
            'X-WC-Store-API-Nonce': _lastNonce!,
          },
        },
        body: json.encode(body),
      );


      if (response.statusCode == 200 || response.statusCode == 201) {
        _updateNonceFromHeaders(response.headers);
        print('Store API Add Success: ${response.statusCode}');
        return json.decode(response.body);
      } else if (!isRetry && (response.statusCode == 403 || response.statusCode == 401)) {
        // Try one more time with a fresh nonce if we got a 403/401
        print('DEBUG: addToStoreCart Error ${response.statusCode} - Retrying with fresh nonce...');
        await _fetchNonce(token: token);
        return await addToStoreCart(token, productId, quantity, extraData: extraData, isRetry: true);

      } else {
        print('Store API Add Error: ${response.statusCode} | Body: ${response.body}');
      }
    } catch (e) {
      print('Error adding to store cart: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> updateStoreCartItem(String token, String key, int quantity, {bool isRetry = false}) async {
    try {
      if (_lastNonce == null) await _fetchNonce(token: token);

      final response = await http.post(
        Uri.parse('$_baseUrl/wp-json/wc/store/v1/cart/update-item'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          if (_lastNonce != null) ...{
            'Nonce': _lastNonce!,
            'X-WC-Store-API-Nonce': _lastNonce!,
          },
        },
        body: json.encode({
          'key': key,
          'quantity': quantity,
        }),
      );

      if (response.statusCode == 200) {
        _updateNonceFromHeaders(response.headers);
        return json.decode(response.body);
      } else if (!isRetry && (response.statusCode == 401 || response.statusCode == 403)) {
        await _fetchNonce(token: token);
        return await updateStoreCartItem(token, key, quantity, isRetry: true);
      } else {
        print('Store API Cart Update Error: ${response.statusCode} | Body: ${response.body}');
      }
    } catch (e) {
      print('Error updating store cart item: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> removeStoreCartItem(String token, String key, {bool isRetry = false}) async {
    try {
      if (_lastNonce == null) await _fetchNonce(token: token);

      final response = await http.post(
        Uri.parse('$_baseUrl/wp-json/wc/store/v1/cart/remove-item'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          if (_lastNonce != null) ...{
            'Nonce': _lastNonce!,
            'X-WC-Store-API-Nonce': _lastNonce!,
          },
        },
        body: json.encode({
          'key': key,
        }),
      );

      if (response.statusCode == 200) {
        _updateNonceFromHeaders(response.headers);
        return json.decode(response.body);
      } else if (!isRetry && (response.statusCode == 401 || response.statusCode == 403)) {
        await _fetchNonce(token: token);
        return await removeStoreCartItem(token, key, isRetry: true);
      } else {
        print('Store API Cart Remove Error: ${response.statusCode} | Body: ${response.body}');
      }
    } catch (e) {
      print('Error removing store cart item: $e');
    }
  }

  Future<List<Subscription>> getSubscriptions(int customerId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/wp-json/wc/v1/subscriptions?customer=$customerId'),
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        print('WooCommerce API: Fetched ${data.length} subscriptions');
        return data.map((json) => Subscription.fromJson(json)).toList();
      } else {
        print('Failed to load subscriptions: ${response.statusCode} | ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error fetching subscriptions: $e');
      return [];
    }
  }

  Future<ReferralData> getReferralData(int userId, {String? token}) async {
    try {
      final customerData = await getCustomerData(userId);
      if (customerData == null) return ReferralData.empty();

      String utilization = '₹0.00';
      int referredUsers = 0;
      int couponsCount = 0;

      if (customerData['meta_data'] != null) {
        final meta = customerData['meta_data'] as List;
        for (var item in meta) {
          final key = item['key'].toString().toLowerCase();
          final val = item['value'];

          // Check for both WPLoyalty and MWB keys
          if (key == 'wployalty_total_utilization' || key == '_wployalty_total_utilization' || key == 'mwb_wcrp_total_utilization' || key == 'mwb_wcrp_referral_utilization') {
            utilization = '₹${val.toString()}';
          } else if (key == 'wployalty_total_referred_users' || key == '_wployalty_total_referred_users' || key == 'wployalty_referred_users_count' || key == 'mwb_wcrp_referred_users_count') {
            referredUsers = int.tryParse(val.toString()) ?? 0;
          } else if (key == 'wployalty_total_coupons' || key == '_wployalty_total_coupons' || key == 'mwb_wcrp_referral_coupons_count' || key == 'mwb_wcrp_user_referral_coupons') {
            couponsCount = int.tryParse(val.toString()) ?? 0;
          }
        }
      }

      List<ReferralCoupon> coupons = [];
      String? scrapedCode;
      if (token != null) {
        final result = await _fetchReferralCouponsFromWebsite(token);
        coupons = result['coupons'] as List<ReferralCoupon>;
        scrapedCode = result['referralCode'] as String?;
        final scrapedStats = result['stats'] as Map<String, dynamic>?;
        
        if (scrapedStats != null) {
          print('DEBUG: WooCommerceService - Scraped Stats: $scrapedStats');
          if (scrapedStats['utilization'] != null) utilization = scrapedStats['utilization'];
          if (scrapedStats['referredUsers'] != null) referredUsers = scrapedStats['referredUsers'];
          if (scrapedStats['couponsCount'] != null) couponsCount = scrapedStats['couponsCount'];
        }

        if (scrapedCode != null) {
          print('DEBUG: WooCommerceService - Scraped Referral Code: $scrapedCode');
        }

        if (coupons.isNotEmpty && couponsCount == 0) {
          couponsCount = coupons.length;
        }
      }

      return ReferralData(
        totalUtilization: utilization,
        totalReferredUsers: referredUsers,
        totalCoupons: couponsCount,
        coupons: coupons,
        scrapedReferralCode: scrapedCode,
      );
    } catch (e) {
      print('Error fetching referral data: $e');
      return ReferralData.empty();
    }
  }

  Future<Map<String, dynamic>> _fetchReferralCouponsFromWebsite(String token) async {
    try {
      final url = '$_baseUrl/my-account/referral_coupons/';
      print('DEBUG: WooCommerceService - Fetching Referral Website URL: $url');
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('DEBUG: WooCommerceService - Response Code: ${response.statusCode}');
      if (response.body.length > 200) {
        print('DEBUG: WooCommerceService - Response Body Preview: ${response.body.substring(0, 200).replaceAll('\n', ' ')}');
      }

      if (response.statusCode != 200) {
        print('Failed to fetch referral coupons page: ${response.statusCode}');
        // Try fallback with JWT in query param if simple-jwt-login is used
        final retryResponse = await http.get(Uri.parse('$url?jwt=$token'));
        if (retryResponse.statusCode != 200) return {'coupons': [], 'referralCode': null, 'stats': null};
        return {
          'coupons': _parseReferralCouponsHtml(retryResponse.body),
          'referralCode': _parseReferralCode(retryResponse.body),
          'stats': _parseReferralStats(retryResponse.body),
        };
      }

      return {
        'coupons': _parseReferralCouponsHtml(response.body),
        'referralCode': _parseReferralCode(response.body),
        'stats': _parseReferralStats(response.body),
      };
    } catch (e) {
      print('Error scraping referral coupons: $e');
      return {'coupons': [], 'referralCode': null, 'stats': null};
    }
  }

  Map<String, dynamic>? _parseReferralStats(String html) {
    try {
      final Map<String, dynamic> stats = {};
      
      // Scrape Total Utilization
      final utilRegex = RegExp(r'<span>Total Utilization<\/span>[\s\S]*?<h4>([\s\S]*?)<\/h4>');
      final utilMatch = utilRegex.firstMatch(html);
      if (utilMatch != null) {
        String rawUtil = utilMatch.group(1) ?? '';
        // Clean up HTML tags (like <bdi>, <span>) and entities
        String cleaned = _cleanHtml(rawUtil).replaceAll('&#8377;', '₹').trim();
        if (cleaned.isNotEmpty) stats['utilization'] = cleaned;
      }

      // Scrape Total Referred Users
      final refRegex = RegExp(r'<span>Total Referred Users<\/span>[\s\S]*?<h4>([\s\S]*?)<\/h4>');
      final refMatch = refRegex.firstMatch(html);
      if (refMatch != null) {
        stats['referredUsers'] = int.tryParse(_cleanHtml(refMatch.group(1) ?? '').trim()) ?? 0;
      }

      // Scrape Total Coupons
      final couponsRegex = RegExp(r'<span>Total Coupons<\/span>[\s\S]*?<h4>([\s\S]*?)<\/h4>');
      final couponsMatch = couponsRegex.firstMatch(html);
      if (couponsMatch != null) {
        stats['couponsCount'] = int.tryParse(_cleanHtml(couponsMatch.group(1) ?? '').trim()) ?? 0;
      }

      if (stats.isNotEmpty) {
        return stats;
      }
    } catch (e) {
      print('Error parsing referral stats: $e');
    }
    return null;
  }

  String? _parseReferralCode(String html) {
    try {
      // Look for patterns like https://winleafteas.com?ref=04KZY4Z
      final refLinkRegex = RegExp(r'\?ref=([a-zA-Z0-9]+)');
      final match = refLinkRegex.firstMatch(html);
      if (match != null) {
        return match.group(1);
      }
    } catch (e) {
      print('Error parsing referral code: $e');
    }
    return null;
  }

  List<ReferralCoupon> _parseReferralCouponsHtml(String html) {
    List<ReferralCoupon> results = [];
    try {
      print('DEBUG: WooCommerceService - Parsing Referral Coupons HTML (Length: ${html.length})');
      // Look for rows in the MWB referral table
      // The table usually has class mwb-crp-referral-table
      final tableRegex = RegExp(r'<table[^>]*class="[^"]*mwb-crp-referral-table[^"]*"[^>]*>([\s\S]*?)<\/table>');
      final tableMatch = tableRegex.firstMatch(html);
      
      if (tableMatch != null) {
        final tableHtml = tableMatch.group(1) ?? '';
        
        // Find all rows, including those in thead and tbody
        final rowRegex = RegExp(r'<tr[^>]*>([\s\S]*?)<\/tr>');
        final allRows = rowRegex.allMatches(tableHtml).toList();

        for (int i = 0; i < allRows.length; i++) {
          final rowHtml = allRows[i].group(1) ?? '';
          // Skip header rows (usually contains <th> or specific classes)
          if (rowHtml.contains('<th') || rowHtml.contains('mwb-wcrp-table-header')) {
            continue;
          }

          // Match both <td> and <th> just in case, but usually data is in <td>
          final cellRegex = RegExp(r'<t[dh][^>]*>([\s\S]*?)<\/t[dh]>');
          final cells = cellRegex.allMatches(rowHtml).toList();

          if (cells.length >= 5) {
            String code = _cleanHtml(cells[0].group(1) ?? '');
            String created = _cleanHtml(cells[1].group(1) ?? '');
            String expiry = cells.length > 2 ? _cleanHtml(cells[2].group(1) ?? '') : '';
            String event = cells.length > 3 ? _cleanHtml(cells[3].group(1) ?? '') : '';
            int referred = 0;
            if (cells.length > 4) {
              referred = int.tryParse(_cleanHtml(cells[4].group(1) ?? '')) ?? 0;
            }
            String status = cells.length > 5 ? _cleanHtml(cells[5].group(1) ?? '') : 'Active';

            if (code.isNotEmpty) {
              results.add(ReferralCoupon(
                code: code,
                createdDate: created,
                expiryDate: expiry,
                event: event,
                referredUsers: referred,
                status: status,
              ));
              print('DEBUG: WooCommerceService - Parsed Coupon: $code');
            }
          } else if (cells.isNotEmpty) {
             print('DEBUG: WooCommerceService - Row $i HTML: ${rowHtml.length > 100 ? rowHtml.substring(0, 100) : rowHtml}');
          }
        }
      }
      
      // Fallback for different table structure or WPLoyalty
      if (results.isEmpty) {
        final wplRegex = RegExp(r'wployalty-referral-table[\s\S]*?<tbody>([\s\S]*?)<\/tbody>');
        final wplMatch = wplRegex.firstMatch(html);
        if (wplMatch != null) {
          // Parse WPLoyalty structure if needed
        }
      }

      print('Scraped ${results.length} referral coupons from website');
    } catch (e) {
      print('Error parsing referral coupons HTML: $e');
    }
    return results;
  }

  String _cleanHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }


  Future<int> getCustomerPoints(int userId, {String? token, String? email}) async {
    try {
      // 1. Try Loyalty Balance API
      int balance = await getLoyaltyBalance(userId, token: token);
      if (balance > 0) return balance;

      // 2. Try Customer Metadata
      final customerData = await getCustomerData(userId);
      if (customerData != null) {
        final customer = Customer.fromJson(customerData);
        if (customer.points > 0) return customer.points;
      }

      // 3. Try Points History (which includes order fallback)
      final history = await getPointsHistory(userId, token: token, email: email);
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
        if (calculatedBalance > 0) return calculatedBalance;
      }
    } catch (e) {
      print('Error in getCustomerPoints: $e');
    }
    return 0;
  }

  Future<int> getLoyaltyBalance(int userId, {String? token}) async {
    final baseUrl = _baseUrl.endsWith('/') ? _baseUrl.substring(0, _baseUrl.length - 1) : _baseUrl;
    final List<String> endpoints = [
      '$baseUrl/wp-json/wployalty/v1/customer/points?user_id=$userId',
      '$baseUrl/wp-json/wployalty/v1/customer?user_id=$userId',
      '$baseUrl/wp-json/wplyalty/v1/customer/points?user_id=$userId',
      '$baseUrl/wp-json/wployalty/v1/customers/$userId',
      '$baseUrl/wp-json/wployalty/v1/customer/referral?user_id=$userId',
    ];

    // Run ALL endpoints IN PARALLEL — 3s cap (was 5s each × 5 = 25s worst case)
    try {
      final futures = endpoints.map((endpoint) async {
        try {
          final response = await http.get(
            Uri.parse(endpoint),
            headers: {
              'Authorization': token != null ? 'Bearer $token' : _authHeader,
              'Content-Type': 'application/json',
            },
          ).timeout(const Duration(seconds: 3));

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            if (data['points'] != null) return int.tryParse(data['points'].toString()) ?? 0;
            if (data['customer']?['points'] != null) {
              return int.tryParse(data['customer']['points'].toString()) ?? 0;
            }
            if (data['point_balance'] != null) return int.tryParse(data['point_balance'].toString()) ?? 0;
            if (data['points_balance'] != null) return int.tryParse(data['points_balance'].toString()) ?? 0;
          }
        } catch (_) {}
        return 0;
      }).toList();

      final results = await Future.wait(futures, eagerError: false)
          .timeout(const Duration(seconds: 3), onTimeout: () => List.filled(endpoints.length, 0));

      return results.firstWhere((r) => r > 0, orElse: () => 0);
    } catch (e) {
      return 0;
    }
  }

  Future<List<PointHistory>> getPointsHistory(int userId, {String? token, String? email}) async {
    try {
      final baseUrl = _baseUrl.endsWith('/') ? _baseUrl.substring(0, _baseUrl.length - 1) : _baseUrl;
      final List<String> endpoints = [
        if (email != null) '$baseUrl/wp-json/wployalty/v1/customer/points/history?email=$email',
        if (email != null) '$baseUrl/wp-json/wplyalty/v1/customer/points/history?email=$email',
        '$baseUrl/wp-json/wployalty/v1/customer/points/history?user_id=$userId',
        '$baseUrl/wp-json/wplyalty/v1/customer/points/history?user_id=$userId',
        '$baseUrl/wp-json/wployalty/v1/customer/history?user_id=$userId',
        '$baseUrl/wp-json/wplyalty/v1/points/history?user_id=$userId',
        '$baseUrl/wp-json/wployalty/v1/customer/points?user_id=$userId',
      ];

      // Run ALL endpoints IN PARALLEL — 3s cap (was sequential with no timeout = 10-30s!)
      final futures = endpoints.map((url) async {
        try {
          final response = await http.get(
            Uri.parse(url),
            headers: {
              if (token != null) 'Authorization': 'Bearer $token'
              else 'Authorization': _authHeader,
              'Content-Type': 'application/json',
            },
          ).timeout(const Duration(seconds: 3));

          if (response.statusCode == 200) {
            final decoded = json.decode(response.body);
            if (decoded is List && decoded.isNotEmpty) {
              print('WPLoyalty API: Got ${decoded.length} points history items from $url');
              return decoded.map((item) => PointHistory.fromJson(item)).toList();
            }
          }
        } catch (_) {}
        return <PointHistory>[];
      }).toList();

      final results = await Future.wait(futures, eagerError: false)
          .timeout(const Duration(seconds: 3), onTimeout: () => List.filled(endpoints.length, <PointHistory>[]));

      // Return the first non-empty result
      for (final result in results) {
        if (result.isNotEmpty) return result;
      }

      // Fallback: extract points from order meta_data
      print('WPLoyalty API: All endpoints failed. Extracting points from order meta_data.');
      final orders = await getOrdersByCustomer(userId, perPage: 50)
          .timeout(const Duration(seconds: 5), onTimeout: () => []);
      return orders.map((order) {
        int? actualPoints;
        if (order.metaData != null) {
          for (var item in order.metaData!) {
            final key = item['key'].toString().toLowerCase();
            final val = item['value'];
            if (key == '_wc_points_earned' ||
                key == 'wc_points_earned' ||
                key == '_wployalty_points_earned' ||
                key == 'wployalty_points_earned' ||
                key == '_wployalty_order_points' ||
                key == 'wployalty_order_points' ||
                key == '_wployalty_points' ||
                key == 'wployalty_points') {
              actualPoints = int.tryParse(val.toString());
              break;
            }
          }
        }
        if (actualPoints == null || actualPoints == 0) return null;
        return PointHistory(
          event: 'Points earned for purchase (Order #${order.number})',
          date: order.dateCreated != null ? order.dateCreated!.toString() : 'Unknown',
          points: '+$actualPoints',
        );
      }).whereType<PointHistory>().toList();

    } catch (e) {
      print('Error fetching points history: $e');
      return [];
    }
  }
}
