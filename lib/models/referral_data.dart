import 'referral_coupon.dart';

class ReferralData {
  final String totalUtilization;
  final int totalReferredUsers;
  final int totalCoupons;
  final String? scrapedReferralCode;
  final List<ReferralCoupon> coupons;

  ReferralData({
    required this.totalUtilization,
    required this.totalReferredUsers,
    required this.totalCoupons,
    required this.coupons,
    this.scrapedReferralCode,
  });

  factory ReferralData.empty() {
    return ReferralData(
      totalUtilization: '₹0.00',
      totalReferredUsers: 0,
      totalCoupons: 0,
      coupons: [],
      scrapedReferralCode: null,
    );
  }
}
