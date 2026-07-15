import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/sound_service.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../auth/presentation/screens/login_screen.dart';

class SettingsModal extends ConsumerStatefulWidget {
  const SettingsModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const SettingsModal(),
    );
  }

  @override
  ConsumerState<SettingsModal> createState() => _SettingsModalState();
}

class _SettingsModalState extends ConsumerState<SettingsModal> {
  late bool _musicEnabled;
  late bool _sfxEnabled;

  @override
  void initState() {
    super.initState();
    final soundService = ref.read(soundServiceProvider);
    _musicEnabled = soundService.musicEnabled;
    _sfxEnabled = soundService.sfxEnabled;
  }

  void _logout() async {
    final auth = ref.read(authRepositoryProvider);
    await auth.signOut();
    ref.read(currentUserProvider.notifier).state = null;
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final soundService = ref.watch(soundServiceProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.appBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppColors.appBorder),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.appBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text('SETTINGS', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 20),
          _buildToggle(
            icon: Icons.music_note,
            title: 'Background Music',
            value: _musicEnabled,
            onChanged: (v) {
              setState(() => _musicEnabled = v);
              soundService.setMusicEnabled(v);
            },
          ),
          const SizedBox(height: 12),
          _buildToggle(
            icon: Icons.volume_up,
            title: 'Sound Effects (SFX)',
            value: _sfxEnabled,
            onChanged: (v) {
              setState(() => _sfxEnabled = v);
              soundService.setSfxEnabled(v);
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout, color: AppColors.warning),
              label: const Text('Log Out', style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.warning.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildToggle({required IconData icon, required String title, required bool value, required ValueChanged<bool> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.appCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.appBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accent, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600))),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.secondary,
            activeThumbColor: Colors.white,
          ),
        ],
      ),
    );
  }
}
