import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../core/app_colors.dart';
import 'auth_screen.dart';
import 'orders_screen.dart';
import 'about_us_screen.dart';
import '../services/url_launcher_service.dart';
import 'account_details_screen.dart';
import 'downloads_screen.dart';
import 'addresses_screen.dart';
import 'rewards_screen.dart';
import 'referral_coupons_screen.dart';
import 'subscriptions_screen.dart';
import '../providers/profile_provider.dart';
import 'home_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, provider, child) {
          return Scaffold(
            backgroundColor: AppColors.backgroundLight,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: const Text('Account', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
            ),
            body: RefreshIndicator(
              onRefresh: () => provider.checkStatus(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    provider.isLoggedIn ? _buildUserInfo(context, provider) : _buildLoginPrompt(context, provider),
                    const SizedBox(height: 32),
                    _buildPointsOverview(provider),
                    const SizedBox(height: 32),
                    _buildMenuSection(context, provider, 'MY ACCOUNT', [
                      _MenuItem(
                        icon: Icons.dashboard_outlined, 
                        title: 'Dashboard', 
                        onTap: () {},
                      ),
                      _MenuItem(
                        icon: Icons.shopping_bag_outlined, 
                        title: 'Orders',
                        onTap: () {
                          if (provider.isLoggedIn) {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen()));
                          } else {
                            _navigateToAuth(context, provider);
                          }
                        },
                      ),
                      _MenuItem(
                        icon: Icons.calendar_today_outlined, 
                        title: 'Subscriptions',
                        onTap: () {
                          if (provider.isLoggedIn) {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionsScreen()));
                          } else {
                            _navigateToAuth(context, provider);
                          }
                        },
                      ),
                      _MenuItem(
                        icon: Icons.cloud_download_outlined, 
                        title: 'Downloads',
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const DownloadsScreen()));
                        },
                      ),
                      _MenuItem(
                        icon: Icons.location_on_outlined, 
                        title: 'Addresses', 
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressesScreen()));
                        }
                      ),
                      _MenuItem(
                        icon: Icons.person_outline, 
                        title: 'Account details', 
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => AccountDetailsScreen(
                            firstName: provider.customer?.firstName,
                            lastName: provider.customer?.lastName,
                            email: provider.customer?.email,
                            username: provider.customer?.username,
                          )));
                        },
                      ),

                      _MenuItem(
                        icon: Icons.star_outline, 
                        title: 'Points', 
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const RewardsScreen()));
                        }
                      ),
                      _MenuItem(
                        icon: Icons.card_giftcard, 
                        title: 'Refer & Earn', 
                        onTap: () {
                          if (provider.isLoggedIn) {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const ReferralCouponsScreen()));
                          } else {
                            _navigateToAuth(context, provider);
                          }
                        }
                      ),
                    ]),
                    const SizedBox(height: 16),
                    _buildMenuSection(context, provider, 'SUPPORT', [
                      _MenuItem(
                        icon: Icons.history_edu_outlined, 
                        title: 'Our Story', 
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutUsScreen()));
                        },
                      ),
                      _MenuItem(
                        icon: Icons.help_outline_outlined, 
                        title: 'Support (WhatsApp)', 
                        onTap: () => UrlLauncherService().launchWhatsApp(message: "Hi, I need support with my order."),
                      ),
                    ]),
                    if (provider.isLoggedIn) ...[
                      const SizedBox(height: 40),
                      TextButton.icon(
                        onPressed: () => provider.logout(),
                        icon: const Icon(Icons.logout, color: Colors.red),
                        label: const Text('Log out', style: TextStyle(color: Colors.red)),
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Account'),
                              content: const Text('Are you sure you want to delete your account? This action cannot be undone.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    Navigator.pop(ctx);
                                    final success = await provider.deleteAccount();
                                    if (success) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Account deleted successfully')),
                                        );
                                        Navigator.of(context).pushAndRemoveUntil(
                                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                                          (route) => false,
                                        );
                                      }
                                    } else {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Failed to delete account')),
                                        );
                                      }
                                    }
                                  },
                                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.delete_forever, color: Colors.red),
                        label: const Text('Delete Account', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          );
        },
      );
  }

  Widget _buildLoginPrompt(BuildContext context, ProfileProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: AppColors.cardGrey),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardGrey.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_add_outlined, 
              size: 48, 
              color: AppColors.primaryOrange,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Join Win Leaf Tea', 
            style: TextStyle(
              fontWeight: FontWeight.w800, 
              fontSize: 20,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Sign in to track orders, manage addresses, and earn leaf points with every purchase.', 
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textGrey, 
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () => _navigateToAuth(context, provider),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text(
                'Login or Signup',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToAuth(BuildContext context, ProfileProvider provider) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
    if (result == true) {
      provider.checkStatus();
    }
  }

  void _showImageSourceSheet(BuildContext context, ProfileProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Profile Picture',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Choose how you want to select your photo',
              style: TextStyle(color: AppColors.textGrey, fontSize: 13),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceOption(
                  context, 
                  icon: Icons.camera_alt_outlined, 
                  label: 'Camera', 
                  onTap: () {
                    Navigator.pop(context);
                    provider.pickImage(ImageSource.camera);
                  }
                ),
                _buildSourceOption(
                  context, 
                  icon: Icons.photo_library_outlined, 
                  label: 'Gallery', 
                  onTap: () {
                    Navigator.pop(context);
                    provider.pickImage(ImageSource.gallery);
                  }
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardGrey.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primaryOrange, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context, ProfileProvider provider) {
    final avatarUrl = provider.customer?.avatarUrl;
    final displayName = provider.userName ?? 'Valued Customer';
    
    return Column(
      children: [
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryOrange,
                    AppColors.primaryOrangeLight,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryOrange.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 52,
                  backgroundColor: AppColors.cardGrey,
                  backgroundImage: provider.pickedImage != null 
                    ? FileImage(provider.pickedImage!) as ImageProvider
                    : (avatarUrl != null ? CachedNetworkImageProvider(avatarUrl) : null),
                  child: provider.pickedImage == null && avatarUrl == null 
                    ? const Icon(Icons.person, size: 60, color: AppColors.textGrey)
                    : null,
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 4,
              child: GestureDetector(
                onTap: () => _showImageSourceSheet(context, provider),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          displayName,
          style: const TextStyle(
            fontSize: 26, 
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildPointsOverview(ProfileProvider provider) {
    if (!provider.isLoggedIn) return const SizedBox.shrink();

    final points = provider.customer?.points ?? 0;
    final tier = provider.customer?.loyaltyTier ?? 'Bronze Member';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryOrange,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('LEAF POINTS', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
              provider.isLoading 
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('$points pts', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(tier, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, ProfileProvider provider, String title, List<_MenuItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(color: AppColors.textGrey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardGrey),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.cardGrey.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(item.icon, size: 20, color: AppColors.textDark),
                    ),
                    title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: item.subtitle != null ? Text(item.subtitle!, style: const TextStyle(fontSize: 12)) : null,
                    trailing: const Icon(Icons.chevron_right, color: AppColors.cardGrey),
                    onTap: item.onTap,
                  ),
                  if (idx < items.length - 1)
                    const Divider(height: 1, indent: 64, color: AppColors.cardGrey),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  _MenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });
}
