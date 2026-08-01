import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../game/presentation/screens/home_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _nameController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _playAsGuest() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Please enter your name first.');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.signInAsGuest(name);
      if (user != null && mounted) {
        ref.read(currentUserProvider.notifier).state = user;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      setState(() => _error = 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.signInWithGoogle();
      if (user != null && mounted) {
        ref.read(currentUserProvider.notifier).state = user;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      setState(() => _error = 'Google sign-in failed. Try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D0D1A),
              Color(0xFF1A1A2E),
              Color(0xFF0F3460),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const SizedBox(height: 60),
                _buildLogo(),
                const SizedBox(height: 48),
                _buildGuestSection(),
                const SizedBox(height: 14),
                _buildDivider(),
                const SizedBox(height: 14),
                _buildGoogleSection(),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  _buildError(),
                ],
                const SizedBox(height: 40),
                _buildFeatureList(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: AppColors.appCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.4),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Center(
            child: Text('🎲', style: TextStyle(fontSize: 48)),
          ),
        ),
        const SizedBox(height: 20),
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'PLOT ',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
              TextSpan(
                text: 'PLOT',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Buy, Build, Earn, Win!',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildGuestSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your name',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Enter your name...',
            prefixIcon: Icon(Icons.person_outline, color: AppColors.textHint),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _playAsGuest,
            icon: const Icon(Icons.sports_esports_outlined),
            label: const Text(
              'Play as Guest (Offline)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.secondary,
              side: const BorderSide(color: AppColors.secondary, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.textHint.withValues(alpha: 0.3))),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR',
            style: TextStyle(color: AppColors.textHint, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(child: Divider(color: AppColors.textHint.withValues(alpha: 0.3))),
      ],
    );
  }

  Widget _buildGoogleSection() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _signInWithGoogle,
        icon: const Text('G', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF4285F4))),
        label: const Text(
          'Continue with Google',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.warning, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(color: AppColors.warning, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureList() {
    return Column(
      children: [
        _featureRow('🏠', 'Buy plots and collect rent'),
        _featureRow('🌾', 'Manage farms and businesses'),
        _featureRow('🎡', 'Surprise and Lucky Wheel events'),
        _featureRow('🌐', 'Online multiplayer with friends'),
        _featureRow('🎤', 'Voice chat during games'),
      ],
    );
  }

  Widget _featureRow(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}