import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Central place for every sound the game makes:
///  • looping background music while a match is in progress
///  • the short dice-rattle SFX every time a player rolls
///  • a short "tap" SFX every time the token hops one tile forward
///
/// Kept as a single long-lived service (not per-screen) so music keeps
/// playing correctly even if widgets rebuild, and so we never end up with
/// two music tracks stacked on top of each other.
class SoundService {
  SoundService._internal();
  static final SoundService instance = SoundService._internal();

  final AudioPlayer _musicPlayer = AudioPlayer(playerId: 'bgm');
  final AudioPlayer _sfxPlayer = AudioPlayer(playerId: 'sfx');
  final AudioPlayer _movePlayer = AudioPlayer(playerId: 'move');
  final AudioPlayer _clickPlayer = AudioPlayer(playerId: 'click');
  final AudioPlayer _cashPlayer = AudioPlayer(playerId: 'cash');
  final AudioPlayer _rattlePlayer = AudioPlayer(playerId: 'rattle');
  final AudioPlayer _clackPlayer = AudioPlayer(playerId: 'clack');

  bool musicEnabled = true;
  bool sfxEnabled = true;

  bool _musicStarted = false;

  Future<void> _initOnce() async {
    if (_musicStarted) return;
    _musicStarted = true;
    await _musicPlayer.setReleaseMode(ReleaseMode.loop);
    await _rattlePlayer.setReleaseMode(ReleaseMode.loop);
    await _musicPlayer.setVolume(0.35);
    await _sfxPlayer.setVolume(1.0);
    await _movePlayer.setVolume(0.8);
    await _clickPlayer.setVolume(0.6);
    await _cashPlayer.setVolume(0.8);
    await _rattlePlayer.setVolume(1.0);
    await _clackPlayer.setVolume(1.0);
  }

  /// Starts (or resumes) the looping background track. Safe to call
  /// repeatedly — it won't restart a track that's already playing.
  Future<void> playBackgroundMusic() async {
    await _initOnce();
    if (!musicEnabled) return;
    if (_musicPlayer.state == PlayerState.playing) return;
    await _musicPlayer.play(AssetSource('sounds/background_music.mp3'));
  }

  Future<void> pauseBackgroundMusic() async {
    if (_musicPlayer.state == PlayerState.playing) {
      await _musicPlayer.pause();
    }
  }

  Future<void> resumeBackgroundMusic() async {
    if (!musicEnabled) return;
    if (_musicPlayer.state == PlayerState.paused) {
      await _musicPlayer.resume();
    } else {
      await playBackgroundMusic();
    }
  }

  Future<void> stopBackgroundMusic() async {
    await _musicPlayer.stop();
  }

  /// Same short dice-rattle-and-clatter clip used everywhere a die is
  /// rolled — the Ludo-style "thock" that plays the instant the dice
  /// starts tumbling.
  Future<void> playDiceRoll() async {
    if (!sfxEnabled) return;
    // .resume()/.play() on a dedicated sfx player means rapid re-rolls
    // (tap, tap, tap) restart the clip instantly instead of queueing.
    await _sfxPlayer.stop();
    await _sfxPlayer.play(AssetSource('sounds/dice_roll.mp3'));
  }

  /// Short "tap" that plays once per tile as the token hops forward,
  /// same idea as the per-step click in Ludo. Call this once for
  /// every single-tile hop, not once per whole move.
  Future<void> playTokenMove() async {
    if (!sfxEnabled) return;
    // A dedicated player (separate from the dice SFX player) so a hop
    // sound firing mid-dice-clip doesn't cut the dice sound off, and
    // vice versa. .stop() first so back-to-back hops each retrigger
    // cleanly instead of overlapping into a blur.
    await _movePlayer.stop();
    await _movePlayer.play(AssetSource('sounds/token_move.mp3'));
  }

  Future<void> playButtonClick() async {
    if (!sfxEnabled) return;
    await _clickPlayer.stop();
    await _clickPlayer.play(AssetSource('sounds/button_click.mp3'));
  }

  Future<void> playCashRegister() async {
    if (!sfxEnabled) return;
    await _cashPlayer.stop();
    await _cashPlayer.play(AssetSource('sounds/cash_register.mp3'));
  }

  Future<void> playDiceRattle() async {
    if (!sfxEnabled) return;
    await _clackPlayer.stop();
    await _rattlePlayer.play(AssetSource('sounds/dice_rattle.mp3'));
  }

  Future<void> playDiceLand() async {
    if (!sfxEnabled) return;
    await _rattlePlayer.stop();
    await _clackPlayer.stop();
    await _clackPlayer.play(AssetSource('sounds/dice_clack.mp3'));
  }

  Future<void> setMusicEnabled(bool enabled) async {
    musicEnabled = enabled;
    if (!enabled) {
      await pauseBackgroundMusic();
    } else {
      await resumeBackgroundMusic();
    }
  }

  void setSfxEnabled(bool enabled) {
    sfxEnabled = enabled;
  }

  Future<void> dispose() async {
    await _musicPlayer.dispose();
    await _sfxPlayer.dispose();
    await _movePlayer.dispose();
    await _clickPlayer.dispose();
    await _cashPlayer.dispose();
    await _rattlePlayer.dispose();
    await _clackPlayer.dispose();
    _musicStarted = false;
  }
}

/// Riverpod accessor so widgets can reach the same singleton via `ref`.
final soundServiceProvider = Provider<SoundService>((ref) => SoundService.instance);