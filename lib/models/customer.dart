import 'order.dart';

class Customer {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String username;
  final int points;
  final String loyaltyTier;
  final String referralCode;
  final Address? billing;
  final Address? shipping;

  final String? avatarUrl;

  Customer({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.points,
    required this.loyaltyTier,
    required this.referralCode,
    this.avatarUrl,
    this.billing,
    this.shipping,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    // Extract points from meta_data if present
    int points = 0;
    String tier = 'Bronze Member';
    String referralCode = '';
    
    if (json['meta_data'] != null) {
      final meta = json['meta_data'] as List;
      for (var item in meta) {
        final key = item['key'].toString().toLowerCase();
        final val = item['value'];
        
        // Check for common points keys
        if (key == '_wc_points_balance' || 
            key == 'points_balance' || 
            key == 'wployalty_points' || 
            key == 'wplyalty_points' ||
            key == '_points_and_rewards' ||
            key == '_sumo_reward_points' ||
            key == '_yith_wc_points_rewards_balance') {
          points = int.tryParse(val.toString()) ?? 0;
        }
        
        // Check for common tier keys
        if (key == 'loyalty_tier' || 
            key == 'membership_tier' || 
            key == '_wployalty_tier' ||
            key == 'wplyalty_tier') {
          tier = val.toString();
        }

        // Check for referral code
        if (key == '_wployalty_referral_code' || 
            key == 'referral_code' || 
            key == 'wployalty_referral_code' ||
            key == 'mwb_wcrp_referral_code' ||
            key == 'mwb_wcrp_user_referral_code') {
          referralCode = val.toString();
        }
      }
    }

    // fallback check for direct fields if some plugins expose it directly
    if (points == 0 && json['points_balance'] != null) {
      points = int.tryParse(json['points_balance'].toString()) ?? 0;
    }

    return Customer(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      username: json['username'] ?? '',
      points: points,
      loyaltyTier: tier,
      referralCode: referralCode,
      avatarUrl: json['avatar_url'],
      billing: json['billing'] != null ? Address.fromJson(json['billing']) : null,
      shipping: json['shipping'] != null ? Address.fromJson(json['shipping']) : null,
    );
  }

  Customer copyWith({
    int? id,
    String? email,
    String? firstName,
    String? lastName,
    String? username,
    int? points,
    String? loyaltyTier,
    String? referralCode,
    String? avatarUrl,
    Address? billing,
    Address? shipping,
  }) {
    return Customer(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      points: points ?? this.points,
      loyaltyTier: loyaltyTier ?? this.loyaltyTier,
      referralCode: referralCode ?? this.referralCode,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      billing: billing ?? this.billing,
      shipping: shipping ?? this.shipping,
    );
  }
}
