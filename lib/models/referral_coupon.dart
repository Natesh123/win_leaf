class ReferralCoupon {
  final String code;
  final String createdDate;
  final String expiryDate;
  final String event;
  final int referredUsers;
  final String status;

  ReferralCoupon({
    required this.code,
    required this.createdDate,
    required this.expiryDate,
    required this.event,
    required this.referredUsers,
    required this.status,
  });

  factory ReferralCoupon.fromJson(Map<String, dynamic> json) {
    return ReferralCoupon(
      code: json['code'] ?? '',
      createdDate: json['created_date'] ?? '',
      expiryDate: json['expiry_date'] ?? '',
      event: json['event'] ?? '',
      referredUsers: json['referred_users'] ?? 0,
      status: json['status'] ?? '',
    );
  }
}
