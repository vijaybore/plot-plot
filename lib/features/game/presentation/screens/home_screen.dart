import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/providers/auth_provider.dart';
import 'setup_game_screen.dart';
import '../../../multiplayer/presentation/screens/lobby_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D0D1A), Color(0xFF1A1A2E), Color(0xFF0F3460)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, user?.displayName ?? 'Player', user?.photoUrl),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBoardPreview(context),
                      const SizedBox(height: 24),
                      _buildGameModeCards(context),
                      const SizedBox(height: 24),
                      _buildFeatureBadges(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String name, String? photoUrl) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha:0.3),
        border: Border(
          bottom: BorderSide(color: AppColors.appBorder, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Logo
          RichText(
            text: const TextSpan(children: [
              TextSpan(
                text: '🏠 PLOT ',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
              ),
              TextSpan(
                text: 'PLOT',
                style: TextStyle(color: AppColors.accent, fontSize: 20, fontWeight: FontWeight.w900),
              ),
            ]),
          ),
          const Spacer(),
          // Player info chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.appCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.primary.withValues(alpha:0.4)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.primary,
                  backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null
                      ? Text(name[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))
                      : null,
                ),
                const SizedBox(width: 8),
                Text(name,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoardPreview(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        color: AppColors.boardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.boardBorder, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // Board border tiles row simulation
            _buildMiniBoard(),
            // Center overlay with CTA
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🎲', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha:0.5),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: const Text(
                      'PLAY NOW',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniBoard() {
    // Simplified visual board border to match reference
    return CustomPaint(
      painter: _MiniBoardPainter(),
      child: const SizedBox.expand(),
    );
  }

  Widget _buildGameModeCards(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Choose Mode',
            style: TextStyle(
                color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _ModeCard(
                icon: '👥',
                title: 'Offline',
                subtitle: '2–7 Players\nPass & Play',
                color: AppColors.secondary,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SetupGameScreen(isOnline: false),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _ModeCard(
                icon: '🌐',
                title: 'Online',
                subtitle: 'Private Room\nWith Friends',
                color: AppColors.primary,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LobbyScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureBadges() {
    final items = [
      ('2–7', 'Players', Icons.people_outline),
      ('25/50/100', 'Plots', Icons.grid_view_rounded),
      ('🌾', 'Farms', null),
      ('🏢', 'Business', null),
      ('💰', 'Loans', null),
      ('🎡', 'Lucky Wheel', null),
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items.map((item) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.appCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.appBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.$3 != null)
                Icon(item.$3!, color: AppColors.accent, size: 16)
              else
                Text(item.$1, style: const TextStyle(fontSize: 14)),
              if (item.$3 != null) ...[
                const SizedBox(width: 6),
                Text(item.$1,
                    style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ],
              const SizedBox(width: 4),
              Text(item.$2,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Mini board painter ──
class _MiniBoardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = AppColors.boardBg;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Draw simplified tiles around the edge
    final tilePaint = Paint()..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = AppColors.boardBorder
      ..strokeWidth = 0.5;

    final colors = [
      AppColors.tileGreen, AppColors.tileOrange, AppColors.tileWhite,
      AppColors.tilePurple, AppColors.tileBlue, AppColors.tileYellow,
    ];

    const tileW = 30.0;
    const tileH = 28.0;
    const edgePad = 8.0;

    // Top row
    for (int i = 0; i < 7; i++) {
      final rect = Rect.fromLTWH(edgePad + i * tileW, edgePad, tileW, tileH);
      tilePaint.color = colors[i % colors.length].withValues(alpha:0.7);
      canvas.drawRect(rect, tilePaint);
      canvas.drawRect(rect, borderPaint);
    }
    // Bottom row
    for (int i = 0; i < 7; i++) {
      final rect = Rect.fromLTWH(edgePad + i * tileW, size.height - edgePad - tileH, tileW, tileH);
      tilePaint.color = colors[(i + 2) % colors.length].withValues(alpha:0.7);
      canvas.drawRect(rect, tilePaint);
      canvas.drawRect(rect, borderPaint);
    }
    // Left column
    for (int i = 0; i < 4; i++) {
      final rect = Rect.fromLTWH(edgePad, edgePad + tileH + i * tileH, tileW, tileH);
      tilePaint.color = colors[(i + 1) % colors.length].withValues(alpha:0.7);
      canvas.drawRect(rect, tilePaint);
      canvas.drawRect(rect, borderPaint);
    }
    // Right column
    for (int i = 0; i < 4; i++) {
      final rect = Rect.fromLTWH(size.width - edgePad - tileW, edgePad + tileH + i * tileH, tileW, tileH);
      tilePaint.color = colors[(i + 3) % colors.length].withValues(alpha:0.7);
      canvas.drawRect(rect, tilePaint);
      canvas.drawRect(rect, borderPaint);
    }

    // Center green area
    final greenPaint = Paint()..color = AppColors.boardGrass.withValues(alpha:0.6);
    final centerRect = Rect.fromLTWH(
      edgePad + tileW + 4,
      edgePad + tileH + 4,
      size.width - (edgePad + tileW + 4) * 2,
      size.height - (edgePad + tileH + 4) * 2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(centerRect, const Radius.circular(8)),
      greenPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Mode Card Widget ──
class _ModeCard extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withValues(alpha:0.2), color.withValues(alpha:0.05)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha:0.5), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 10),
            Text(title,
                style: TextStyle(
                    color: color, fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12, height: 1.4)),
          ],
        ),
      ),
    );
  }
}