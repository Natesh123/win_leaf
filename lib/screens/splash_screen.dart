import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'onboarding_screen.dart';
import '../core/app_colors.dart';
import 'widgets/gradient_background.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    _navigateToOnboarding();
  }

  @override
  void dispose() {
    super.dispose();
  }

  _navigateToOnboarding() async {
    await Future.delayed(const Duration(milliseconds: 1500)); // was 4s — reduced to 1.5s

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const OnboardingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  image: const DecorationImage(
                    image: AssetImage('assets/images/winleaf logo.png'),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              Text(
                "Pure Tea. Pure Moments.",
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 80),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.primaryGold, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.primaryGold, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.primaryGold, shape: BoxShape.circle)),
                ],
              ),
              const SizedBox(height: 24),

              Text(
                "LOADING...",
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



