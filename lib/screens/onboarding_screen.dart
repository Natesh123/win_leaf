import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import 'home_screen.dart';
import '../providers/onboarding_provider.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  static final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'WinLeaf\nPURE TEA',
      subtitle: 'Good Chai. Good Mood.',
      image: 'assets/images/onboarding_1.png',
      buttonText: 'NEXT',
    ),
    OnboardingData(
      title: 'From Real Assam\nTea Gardens',
      subtitle: 'Stronger Taste, Richer Flavor',
      image: 'assets/images/onboarding_2.png',
      buttonText: 'GET STARTED',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OnboardingProvider(),
      child: Consumer<OnboardingProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            body: Stack(
              children: [
                // Background Image PageView
                PageView.builder(
                  controller: provider.pageController,
                  onPageChanged: (index) => provider.setCurrentPage(index),
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          _pages[index].image,
                          fit: BoxFit.cover,
                        ),
                        // Gradient Overlay for text readability
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.2),
                                Colors.black.withOpacity(0.0),
                                Colors.black.withOpacity(0.7),
                              ],
                              stops: const [0.0, 0.4, 1.0],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                
                // Text and Button Content
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Spacer(),
                        // Page Indicator
                        Row(
                          children: List.generate(
                            _pages.length,
                            (index) => Container(
                              margin: const EdgeInsets.only(right: 8),
                              height: 4,
                              width: provider.currentPage == index ? 24 : 12,
                              decoration: BoxDecoration(
                                color: provider.currentPage == index ? AppColors.primaryGold : Colors.white54,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Title
                        Text(
                          _pages[provider.currentPage].title,
                          style: GoogleFonts.montserrat(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Subtitle
                        Text(
                          _pages[provider.currentPage].subtitle,
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              provider.nextPage(_pages.length, () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                                );
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGold,
                              foregroundColor: AppColors.textDark,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                            ),
                            child: Text(
                              _pages[provider.currentPage].buttonText,
                              style: const TextStyle(
                                fontSize: 18,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String subtitle;
  final String image;
  final String buttonText;

  OnboardingData({
    required this.title,
    required this.subtitle,
    required this.image,
    required this.buttonText,
  });
}
