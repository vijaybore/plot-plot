import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioManager {
  // Singleton instance
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  final AudioPlayer _bgmPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  bool _isMuted = false;
  bool get isMuted => _isMuted;

  Future<void> init() async {
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    // Optional: Preload standard sounds if needed, but AudioCache handles most.
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    if (_isMuted) {
      _bgmPlayer.pause();
    } else {
      _bgmPlayer.resume();
    }
  }

  Future<void> playBgm(String assetPath) async {
    if (_isMuted) return;
    try {
      await _bgmPlayer.play(AssetSource(assetPath));
    } catch (e) {
      debugPrint('Error playing BGM: $e');
    }
  }

  Future<void> stopBgm() async {
    try {
      await _bgmPlayer.stop();
    } catch (e) {
      debugPrint('Error stopping BGM: $e');
    }
  }

  Future<void> playSfx(String assetPath) async {
    if (_isMuted) return;
    try {
      // Create a temporary player for overlapping SFX, or just use the single SFX player.
      // For short overlapping sounds (like multiple coin clinks), using a new instance or Pool is better.
      // Using a new instance for fire-and-forget sound effect:
      final player = AudioPlayer();
      await player.play(AssetSource(assetPath));
      player.onPlayerComplete.listen((_) => player.dispose());
    } catch (e) {
      debugPrint('Error playing SFX: $e');
    }
  }

  // Pre-defined SFX methods for common game events
  Future<void> playDiceRoll() async => playSfx('audio/dice_roll.mp3');
  Future<void> playCoinClink() async => playSfx('audio/coin_clink.mp3');
  Future<void> playPurchaseFanfare() async => playSfx('audio/fanfare.mp3');
  Future<void> playError() async => playSfx('audio/error.mp3');
}
