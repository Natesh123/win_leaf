import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SettingsProvider(),
      child: Consumer<SettingsProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            backgroundColor: AppColors.backgroundLight,
            appBar: AppBar(
              backgroundColor: AppColors.backgroundLight,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.textDark),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'Settings',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  _buildSection('ACCOUNT', [
                    _buildNavTile(Icons.person_outline, 'Edit Profile', () {}),
                    _buildNavTile(Icons.lock_outline, 'Change Password', () {}),
                    _buildNavTile(Icons.location_on_outlined, 'Manage Addresses', () {}),
                    _buildNavTile(Icons.credit_card_outlined, 'Payment Methods', () {}),
                  ]),
                  const SizedBox(height: 16),
                  _buildSection('NOTIFICATIONS', [
                    _buildToggleTile(Icons.notifications_outlined, 'Push Notifications', provider.notifications, (val) {
                      provider.setNotifications(val);
                    }),
                    _buildToggleTile(Icons.local_shipping_outlined, 'Order Updates', provider.orderUpdates, (val) {
                      provider.setOrderUpdates(val);
                    }),
                    _buildToggleTile(Icons.local_offer_outlined, 'Promotions & Offers', provider.promotions, (val) {
                      provider.setPromotions(val);
                    }),
                  ]),
                  const SizedBox(height: 16),
                  _buildSection('SUPPORT', [
                    _buildNavTile(Icons.help_outline_rounded, 'Help & FAQ', () {}),
                    _buildNavTile(Icons.chat_bubble_outline_rounded, 'Contact Us', () {}),
                    _buildNavTile(Icons.star_outline_rounded, 'Rate the App', () {}),
                  ]),
                  const SizedBox(height: 16),
                  _buildSection('APP', [
                    _buildNavTile(Icons.privacy_tip_outlined, 'Privacy Policy', () {}),
                    _buildNavTile(Icons.description_outlined, 'Terms of Service', () {}),
                    _buildInfoTile(Icons.info_outline_rounded, 'App Version', 'v1.0.0'),
                  ]),
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.logout, color: Colors.red),
                        label: const Text(
                          'Sign Out',
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red, width: 1.2),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textGrey,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
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
            children: tiles.asMap().entries.map((entry) {
              return Column(
                children: [
                  entry.value,
                  if (entry.key < tiles.length - 1)
                    const Divider(height: 1, indent: 56, color: AppColors.cardGrey),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildNavTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.cardGrey.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: AppColors.textDark),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.cardGrey),
      onTap: onTap,
    );
  }

  Widget _buildToggleTile(IconData icon, String title, bool value, ValueChanged<bool> onChanged) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.cardGrey.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: AppColors.textDark),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primaryOrange,
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String info) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.cardGrey.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: AppColors.textDark),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: Text(info, style: const TextStyle(color: AppColors.textGrey, fontSize: 13)),
    );
  }
}
