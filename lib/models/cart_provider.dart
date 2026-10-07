import 'dart:convert';
import 'package:flutter/material.dart';
import 'cart_item.dart';
import '../services/woocommerce_service.dart';
import '../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';



class CartProvider extends ChangeNotifier {
  // Singleton instance
  static final CartProvider _instance = CartProvider._internal();
  factory CartProvider() => _instance;
  CartProvider._internal();


  final List<CartItem> _items = [];
  final WooCommerceService _wooService = WooCommerceService();
  final AuthService _authService = AuthService();
  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;


  List<CartItem> get items => List.unmodifiable(_items);

  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalAmount =>
      _items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));

  Future<void> addItem(CartItem newItem) async {
    final existingIndex =
        _items.indexWhere((item) => item.id == newItem.id && item.subtitle == newItem.subtitle);
    
    if (existingIndex >= 0) {
      await increaseQty(newItem.name, subtitle: newItem.subtitle);
    } else {
      _items.add(newItem);
      notifyListeners();
      
      // Sync with server if logged in
      final token = await _getToken();
      print('DEBUG: Cart Sync - Token: ${token != null ? "FOUND" : "NOT FOUND"}');
      if (token != null) {
        print('DEBUG: Cart Sync - Adding product ${newItem.id} to server cart with extraData: ${newItem.extraData}');
        final result = await _wooService.addToStoreCart(token, newItem.id, newItem.quantity, extraData: newItem.extraData);

        if (result != null) {
          print('DEBUG: Cart Sync - Successfully added to server. Updating keys...');
          _updateKeysFromResponse(result);
        } else {
          print('DEBUG: Cart Sync - FAILED to add to server cart (result is null)');
        }
      }

    }
  }

  Future<void> removeItem(String name, {String? subtitle}) async {
    final item = _items.firstWhere((item) => item.name == name && (subtitle == null || item.subtitle == subtitle));
    final key = item.cartKey;
    
    _items.removeWhere((item) => item.name == name && (subtitle == null || item.subtitle == subtitle));
    notifyListeners();

    final token = await _getToken();
    if (token != null && key != null) {
      await _wooService.removeStoreCartItem(token, key);
    }
  }

  Future<void> increaseQty(String name, {String? subtitle}) async {
    final idx = _items.indexWhere((item) => item.name == name && (subtitle == null || item.subtitle == subtitle));
    if (idx >= 0) {
      _items[idx].quantity += 1;
      final key = _items[idx].cartKey;
      final qty = _items[idx].quantity;
      notifyListeners();

      final token = await _getToken();
      if (token != null && key != null) {
        await _wooService.updateStoreCartItem(token, key, qty);
      } else if (token != null && key == null) {
        // If we don't have a key but are logged in, try to add it (fallback)
        await _wooService.addToStoreCart(token, _items[idx].id, 1);
      }
    }
  }

  Future<void> decreaseQty(String name, {String? subtitle}) async {
    final idx = _items.indexWhere((item) => item.name == name && (subtitle == null || item.subtitle == subtitle));
    if (idx >= 0) {
      if (_items[idx].quantity > 1) {
        _items[idx].quantity -= 1;
        final key = _items[idx].cartKey;
        final qty = _items[idx].quantity;
        notifyListeners();

        final token = await _getToken();
        if (token != null && key != null) {
          await _wooService.updateStoreCartItem(token, key, qty);
        }
      } else {
        await removeItem(name, subtitle: subtitle);
      }
    }
  }

  Future<void> loadCartFromServer() async {
    final token = await _getToken();
    if (token == null) return;

    _isSyncing = true;
    notifyListeners();

    try {
      final cartData = await _wooService.getStoreCart(token);
      if (cartData != null && cartData['items'] != null) {
        final List<CartItem> serverItems = [];

        for (var itemJson in cartData['items']) {
          int qty = 1;
          if (itemJson['quantity'] is Map) {
            qty = itemJson['quantity']['value'] ?? 1;
          } else if (itemJson['quantity'] is int) {
            qty = itemJson['quantity'];
          }

          String name = itemJson['name'];
          String subtitle = '';
          double price = double.parse(itemJson['prices']['price'].toString()) / 100;
          final regularPrice = double.parse(itemJson['prices']['regular_price'].toString()) / 100;
          final permalink = itemJson['permalink'] ?? '';
          
          // Basic parsing for server version
          final bool hasSubscriptionIndicator = name.contains('Plan') || subtitle.contains('Plan');
          final intervalMatch = RegExp(r'(\d+)[_-]?(month|year)').firstMatch(permalink + name + subtitle);

          if (hasSubscriptionIndicator || intervalMatch != null) {
            if (intervalMatch != null) {
              int months = int.parse(intervalMatch.group(1)!);
              String period = intervalMatch.group(2)!;
              if (period == 'year') months = 12;

              // billingPrice = amount charged per billing cycle (e.g. ₹252 every 3 months)
              if (months == 3) {
                final billing = (regularPrice * 0.9).roundToDouble();
                subtitle = '3 Months Plan – ₹${billing.toStringAsFixed(2)} every 3 months';
                price = billing;
              } else if (months == 6) {
                final billing = (regularPrice * 0.85).roundToDouble();
                subtitle = '6 Months Plan – ₹${billing.toStringAsFixed(2)} every 6 months';
                price = billing;
              } else if (months == 12) {
                final billing = (regularPrice * 0.8).roundToDouble();
                subtitle = 'Yearly Plan – ₹${billing.toStringAsFixed(2)} / year';
                price = billing;
              }
            } else if (permalink.contains('convert_to_sub') && price < (regularPrice * 0.95)) {
              final billing = (regularPrice * 0.9).roundToDouble();
              subtitle = '3 Months Plan – ₹${billing.toStringAsFixed(2)} every 3 months';
              price = billing;
            }

          } else if (name.contains(' - ')) {
            final parts = name.split(' - ');
            name = parts[0];
            subtitle = parts[1];
          }

          // price is already parsed above

          final newServerItem = CartItem(
            id: itemJson['id'],
            name: name,
            subtitle: subtitle,
            imagePath: (itemJson['images'] as List).isNotEmpty ? itemJson['images'][0]['src'] : '',
            price: price, 
            quantity: qty,
            cartKey: itemJson['key'],
          );

          // SMART SYNC: If we have a local version of this product that is a subscription,
          // and the server version is NOT (yet), keep the local version's info.
          final localMatchIdx = _items.indexWhere((it) => it.id == itemJson['id'] && it.subtitle.contains('Plan'));
          
          if (localMatchIdx >= 0 && !subtitle.contains('Plan')) {
            print('DEBUG: Smart Sync - Preserving local subscription for $name');
            serverItems.add(_items[localMatchIdx].copyWith(
              cartKey: itemJson['key'],
              quantity: qty,
            ));
          } else {
            serverItems.add(newServerItem);
          }
        }
        
        _items.clear();
        _items.addAll(serverItems);
      }
    } catch (e) {
      print('Error loading cart from server: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  void _updateKeysFromResponse(Map<String, dynamic> response) {
    if (response['items'] != null) {
      for (var itemJson in response['items']) {
        final idx = _items.indexWhere((it) => it.id == itemJson['id']);
        if (idx >= 0) {
          _items[idx].cartKey = itemJson['key'];
        }
      }
      notifyListeners();
    }
  }


  void clear() {
    _items.clear();
    notifyListeners();
  }
}
