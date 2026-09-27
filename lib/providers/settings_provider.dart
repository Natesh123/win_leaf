import 'package:flutter/material.dart';

class SettingsProvider extends ChangeNotifier {
  bool _notifications = true;
  bool _orderUpdates = true;
  bool _promotions = false;

  bool get notifications => _notifications;
  bool get orderUpdates => _orderUpdates;
  bool get promotions => _promotions;

  void setNotifications(bool value) {
    _notifications = value;
    notifyListeners();
  }

  void setOrderUpdates(bool value) {
    _orderUpdates = value;
    notifyListeners();
  }

  void setPromotions(bool value) {
    _promotions = value;
    notifyListeners();
  }
}
