import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/game_state_model.dart';

class GameScreen extends StatelessWidget {
  final GameStateModel initialState;
  const GameScreen({super.key, required this.initialState});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBg,
      appBar: AppBar(
        title: const Text('Plot Plot'),
        backgroundColor: AppColors.appBg,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🎲', style: TextStyle(fontSize: 64)),
            SizedBox(height: 16),
            Text(
              'Game Board Coming in Phase 3!',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}