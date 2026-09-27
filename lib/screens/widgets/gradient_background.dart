import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;

  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppColors.websiteBackground,
      child: child,
    );
  }
}
