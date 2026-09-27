import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Our Story',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroSection(),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('The Cricketer Behind the Cup'),
                  const SizedBox(height: 16),
                  _buildDescription(
                    'Our Founder Mr. Syed Mohammed was a former Cricketer who played for Assam in the Ranji Trophy and represented Royal Challengers Bangalore (RCB) in the Indian Premier League (IPL).',
                  ),
                  const SizedBox(height: 16),
                  _buildDescription(
                    'Mr. Syed Mohammed was not a regular tea consumer originally. However, during his playing days in Assam, he began to discover and appreciate the true essence of pure Assam tea. This passion grew until he became a dedicated tea lover.',
                  ),
                  const SizedBox(height: 16),
                  _buildDescription(
                    'So, he started to have a desire to get the best Assam tea across Tamil Nadu and all over the world.',
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Our Mission'),
                  const SizedBox(height: 16),
                  _buildDescription(
                    'Our mission is to deliver the finest quality Assam tea, directly procured from the best tea gardens, blended with expertise and passion.',
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Our Vision'),
                  const SizedBox(height: 16),
                  _buildDescription(
                    'Our vision is to be the leading provider of premium Assam tea, recognized globally for our commitment to quality, authenticity, and sustainability.',
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Core Values'),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildValueChip('Quality'),
                      _buildValueChip('Authenticity'),
                      _buildValueChip('Expertise'),
                      _buildValueChip('Sustainability'),
                      _buildValueChip('Customer Satisfaction'),
                    ],
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: const BoxDecoration(
        color: AppColors.primaryGold,
        image: DecorationImage(
          image: AssetImage('assets/images/home_banner.png'),
          fit: BoxFit.cover,
          opacity: 0.3,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  image: const DecorationImage(
                    image: AssetImage('assets/images/winleaf logo.png'),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Syed Mohammed',
              style: GoogleFonts.montserrat(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            Text(
              'Founder, Win Leaf Tea',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: AppColors.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.montserrat(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.primaryOrange,
      ),
    );
  }

  Widget _buildDescription(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        height: 1.6,
        color: AppColors.textDark,
      ),
    );
  }

  Widget _buildValueChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryOrange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryOrange.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.montserrat(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryOrange,
        ),
      ),
    );
  }
}
