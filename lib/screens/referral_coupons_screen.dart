import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../providers/referral_provider.dart';
import '../providers/profile_provider.dart';
import '../models/referral_data.dart';
import '../models/referral_coupon.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class ReferralCouponsScreen extends StatelessWidget {
  const ReferralCouponsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReferralProvider(),
      child: Consumer2<ReferralProvider, ProfileProvider>(
        builder: (context, provider, profileProvider, child) {
          return Scaffold(
            backgroundColor: const Color(0xFFFBFBFB),
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leadingWidth: 60,
              leading: Padding(
                padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.textDark, size: 20),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
              centerTitle: true,
              title: Text(
                'Referral Coupons', 
                style: GoogleFonts.montserrat(
                  color: const Color(0xFF1A1A1A), 
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                )
              ),
            ),
            body: provider.isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange))
              : RefreshIndicator(
                  onRefresh: provider.fetchData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTopBanner(),
                          const SizedBox(height: 24),
                          _buildStatsRow(provider.referralData),
                          const SizedBox(height: 24),
                          _buildReferralDetails(provider.referralData.coupons),
                          const SizedBox(height: 24),
                          _buildInviteSection(context, profileProvider, provider),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
          );
        },
      ),
    );
  }

  Widget _buildTopBanner() {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFFFF7E5F), Color(0xFFFEB47B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 20,
            top: 0,
            bottom: 0,
            right: 140,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Invite friends. Earn rewards.',
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'The more you refer, the more you earn!',
                  style: GoogleFonts.montserrat(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 10,
            top: 10,
            bottom: 10,
            child: Image.asset(
              'assets/images/referral_banner.png',
              width: 130,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(ReferralData data) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Utilization', 
            data.totalUtilization, 
            'Total rewards utilized',
            Icons.account_balance_wallet_outlined,
            const Color(0xFFFF5722),
          )
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Total Referred Users', 
            data.totalReferredUsers.toString(), 
            'Friends joined',
            Icons.people_outline,
            const Color(0xFF42A5F5),
          )
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Total Coupons', 
            data.totalCoupons.toString(), 
            'Coupons earned',
            Icons.confirmation_number_outlined,
            const Color(0xFF4CAF50),
          )
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String subtext, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            title, 
            style: GoogleFonts.montserrat(color: const Color(0xFF757575), fontSize: 9, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value, 
            style: GoogleFonts.montserrat(color: color, fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtext, 
            style: GoogleFonts.montserrat(color: const Color(0xFF9E9E9E), fontSize: 8),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReferralDetails(List<ReferralCoupon> coupons) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Container(
                width: 750, // Fixed width for all columns
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: const BoxDecoration(
                  color: Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    _buildTableHeader('Coupon', 120),
                    _buildTableHeader('Coupon Created', 140),
                    _buildTableHeader('Expiry Date', 120),
                    _buildTableHeader('Event', 120),
                    _buildTableHeader('Referred Users', 120),
                    _buildTableHeader('Redeem', 100),
                  ],
                ),
              ),
              // Data Rows or Empty Message
              if (coupons.isEmpty)
                Container(
                  width: 750,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: Text(
                    'No records available', 
                    style: GoogleFonts.montserrat(color: const Color(0xFF9E9E9E), fontSize: 13, fontWeight: FontWeight.w500)
                  ),
                )
              else
                Container(
                  width: 750,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: Column(
                    children: coupons.map((coupon) => _buildCouponTableRow(coupon)).toList(),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader(String text, double width) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: GoogleFonts.montserrat(
          fontSize: 11, 
          fontWeight: FontWeight.bold, 
          color: const Color(0xFF1976D2)
        ),
      ),
    );
  }

  Widget _buildCouponTableRow(ReferralCoupon coupon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF5F5F5))),
      ),
      child: Row(
        children: [
          _buildTableCell(coupon.code, 120, isBold: true),
          _buildTableCell(coupon.createdDate, 140),
          _buildTableCell(coupon.expiryDate, 120),
          _buildTableCell(coupon.event, 120),
          _buildTableCell(coupon.referredUsers.toString(), 120, color: const Color(0xFF42A5F5)),
          SizedBox(
            width: 100,
            child: _buildStatusBadge(coupon.status),
          ),
        ],
      ),
    );
  }

  Widget _buildTableCell(String text, double width, {bool isBold = false, Color? color}) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: GoogleFonts.montserrat(
          fontSize: 11, 
          fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          color: color ?? const Color(0xFF1A1A1A),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }


  Widget _buildCouponItem(ReferralCoupon coupon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Coupon Code',
                    style: GoogleFonts.montserrat(color: const Color(0xFF9E9E9E), fontSize: 10),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    coupon.code,
                    style: GoogleFonts.montserrat(color: const Color(0xFF1A1A1A), fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
              _buildStatusBadge(coupon.status),
            ],
          ),
          const Divider(height: 24, color: Color(0xFFF5F5F5)),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Created Date',
                      style: GoogleFonts.montserrat(color: const Color(0xFF9E9E9E), fontSize: 10),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      coupon.createdDate,
                      style: GoogleFonts.montserrat(color: const Color(0xFF1A1A1A), fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Expiry Date',
                      style: GoogleFonts.montserrat(color: const Color(0xFF9E9E9E), fontSize: 10),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      coupon.expiryDate,
                      style: GoogleFonts.montserrat(color: const Color(0xFF1A1A1A), fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Event',
                      style: GoogleFonts.montserrat(color: const Color(0xFF9E9E9E), fontSize: 10),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      coupon.event,
                      style: GoogleFonts.montserrat(color: const Color(0xFF1A1A1A), fontSize: 12, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Referred Users',
                      style: GoogleFonts.montserrat(color: const Color(0xFF9E9E9E), fontSize: 10),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      coupon.referredUsers.toString(),
                      style: GoogleFonts.montserrat(color: const Color(0xFF42A5F5), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    Color bgColor;
    
    switch (status.toLowerCase()) {
      case 'active':
      case 'redeem':
        color = const Color(0xFF4CAF50);
        bgColor = const Color(0xFFE8F5E9);
        break;
      case 'expired':
        color = const Color(0xFFF44336);
        bgColor = const Color(0xFFFFEBEE);
        break;
      default:
        color = const Color(0xFFFF9800);
        bgColor = const Color(0xFFFFF3E0);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.montserrat(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }


  Widget _buildInviteSection(BuildContext context, ProfileProvider profileProvider, ReferralProvider provider) {
    final customer = profileProvider.customer;
    if (customer == null) return const SizedBox.shrink();
    
    // Priority: 1. Scraped from website, 2. From Customer meta_data, 3. Fallback to REF+ID
    String referralCode = provider.referralData.scrapedReferralCode ?? '';
    if (referralCode.isEmpty) {
      referralCode = customer.referralCode.isNotEmpty ? customer.referralCode : 'REF${customer.id}';
    }
    
    final referralLink = 'https://winleafteas.com?ref=$referralCode';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Invite & Earn', 
          style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))
        ),
        const SizedBox(height: 4),
        Text(
          'Share your link and earn exciting rewards', 
          style: GoogleFonts.montserrat(color: const Color(0xFF757575), fontSize: 13)
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7F2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFD1B2), style: BorderStyle.solid),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.link, color: Color(0xFFFF5722), size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  referralLink, 
                  style: GoogleFonts.montserrat(color: const Color(0xFF1A1A1A), fontSize: 12, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                )
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: referralLink));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Referral link copied!'), duration: Duration(seconds: 2))
                  );
                },
                child: Text(
                  'Copy',
                  style: GoogleFonts.montserrat(color: const Color(0xFFFF5722), fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: () => _shareOnWhatsApp(context, referralLink),
            icon: const Icon(Icons.share_outlined, size: 18),
            label: Text(
              'Share Now', 
              style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16)
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5722),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _shareOnWhatsApp(BuildContext context, String link) async {
    final message = "Hey! Check out Win Leaf Tea. Use my referral link to sign up and get a discount coupon: $link";
    final whatsappUrl = Uri.parse("https://wa.me/?text=${Uri.encodeComponent(message)}");
    
    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch WhatsApp')),
        );
      }
    }
  }
}
