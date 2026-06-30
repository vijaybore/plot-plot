import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.bgMedium, AppColors.bgDark],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '🎲',
                style: TextStyle(fontSize: 80),
              ),
              SizedBox(height: 16),
              Text(
                'Plot Plot',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Property Trading Game',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 48),
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text(
                'Setting up...',
                style: TextStyle(color: AppColors.textHint),
              ),
            ],
          ),
        ),
      ),
    );
  }
}