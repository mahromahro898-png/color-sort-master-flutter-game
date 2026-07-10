import 'dart:math'; // 👈 1. A biblioteca de aleatoriedade foi adicionada aqui
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _AppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      SoundService.pauseBackgroundMusic();
    } else if (state == AppLifecycleState.resumed) {
      SoundService.resumeBackgroundMusic();
    }
  }
}

class SoundService {
  static final AudioPlayer _bgPlayer = AudioPlayer();
  static final AudioPlayer _sfxPlayer = AudioPlayer();
  static final AudioPlayer _eventPlayer = AudioPlayer();
  static final AudioPlayer _pourPlayer = AudioPlayer();
  static bool isSfxMuted = false;

  static final _AppLifecycleObserver _observer = _AppLifecycleObserver();

  static bool _isInitialized = false;
  static bool _musicStarted = false;

  static const String _musicEnabledKey = 'music_enabled';

  // 👈 2. Adicionando a variável de aleatoriedade aqui
  static final Random _random = Random();

  static Future<bool> isMusicEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_musicEnabledKey) ?? true;
  }

  static Future<void> setMusicEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_musicEnabledKey, enabled);

    if (enabled) {
      await playBackgroundMusic();
    } else {
      await stopBackgroundMusic();
    }
  }

  static void initialize() {
    if (!_isInitialized) {
      WidgetsBinding.instance.addObserver(_observer);

      final context = AudioContext(
        android: AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.none,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.ambient,
        ),
      );

      _bgPlayer.setAudioContext(context);
      _sfxPlayer.setAudioContext(context);
      _eventPlayer.setAudioContext(context);
      _pourPlayer.setAudioContext(context);

      _setupAudioPlayers();

      _isInitialized = true;
      debugPrint('✅ SoundService initialized');
    }
  }

  static Future<void> _setupAudioPlayers() async {
    try {
      await _bgPlayer.setReleaseMode(ReleaseMode.loop);
      await _sfxPlayer.setReleaseMode(ReleaseMode.stop);
      await _eventPlayer.setReleaseMode(ReleaseMode.stop);
      await _pourPlayer.setReleaseMode(ReleaseMode.stop);

      await _bgPlayer.setVolume(0.12);
      await _sfxPlayer.setVolume(0.16);
      await _eventPlayer.setVolume(0.50);
      await _pourPlayer.setVolume(0.20);
    } catch (e) {
      debugPrint('❌ Audio setup error: $e');
    }
  }

  static Future<void> playBackgroundMusic() async {
    final enabled = await isMusicEnabled();
    if (!enabled) return;
    try {
      if (_musicStarted && _bgPlayer.state == PlayerState.playing) return;

      await _bgPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgPlayer.setVolume(0.12);
      await _bgPlayer.play(AssetSource('sounds/bg_music.mp3'));

      _musicStarted = true;
      debugPrint('✅ Background music started');
    } catch (e) {
      debugPrint('❌ Background music error: $e');
    }
  }

  static Future<void> pauseBackgroundMusic() async {
    try {
      if (_bgPlayer.state == PlayerState.playing) {
        await _bgPlayer.pause();
        debugPrint('⏸️ Background music paused');
      }
    } catch (e) {
      debugPrint('❌ Pause music error: $e');
    }
  }

  static Future<void> resumeBackgroundMusic() async {
    try {
      if (_musicStarted && _bgPlayer.state == PlayerState.paused) {
        await _bgPlayer.resume();
        debugPrint('▶️ Background music resumed');
      }
    } catch (e) {
      debugPrint('❌ Resume music error: $e');
    }
  }

  static Future<void> stopBackgroundMusic() async {
    try {
      await _bgPlayer.stop();
      _musicStarted = false;
    } catch (e) {
      debugPrint('❌ Stop music error: $e');
    }
  }

  // ----------------------------------------------------
  // 👈 Novas funções para reproduzir e parar o som de despejo
  // ----------------------------------------------------
  static Future<void> playPourSound() async {
    try {
      if (isSfxMuted) return;
      await _pourPlayer.stop();

      // 👈 3. Modificação inteligente: Escolher o arquivo de áudio aleatoriamente
      int randomNum = _random.nextInt(2); // Gera 0 ou 1
      String soundFile = randomNum == 0 ? 'pour.mp3' : 'pour2.mp3';

      await _pourPlayer.setReleaseMode(ReleaseMode.loop);

      // Reproduz o arquivo selecionado
      await _pourPlayer.play(AssetSource('sounds/$soundFile'));
    } catch (e) {
      debugPrint('❌ Pour sound error: $e');
    }
  }

  static Future<void> stopPourSound() async {
    try {
      await _pourPlayer.stop();
    } catch (e) {
      debugPrint('❌ Stop pour sound error: $e');
    }
  }
  // ----------------------------------------------------

  static Future<void> playWaterDrop() async {
    try {
      final player = AudioPlayer();

      await player.setVolume(0.14);
      await player.play(
        AssetSource('sounds/drop.mp3'),
        mode: PlayerMode.lowLatency,
      );

      player.onPlayerComplete.listen((event) {
        player.dispose();
      });
    } catch (e) {
      debugPrint('❌ Water drop error: $e');
    }
  }

  static Future<void> playWinSound() async {
    try {
      if (isSfxMuted) return;
      await _eventPlayer.stop();
      await _eventPlayer.setVolume(0.50);
      await _eventPlayer.play(AssetSource('sounds/win.mp3'));
    } catch (e) {
      debugPrint('❌ Win sound error: $e');
    }
  }

  static Future<void> playLoseSound() async {
    try {
      if (isSfxMuted) return;
      await _eventPlayer.stop();
      await _eventPlayer.setVolume(0.40);
      await _eventPlayer.play(AssetSource('sounds/lose.mp3'));
    } catch (e) {
      debugPrint('❌ Lose sound error: $e');
    }
  }

  static Future<void> dispose() async {
    try {
      WidgetsBinding.instance.removeObserver(_observer);
      await _bgPlayer.dispose();
      await _sfxPlayer.dispose();
      await _eventPlayer.dispose();
      await _pourPlayer.dispose();
      _isInitialized = false;
      _musicStarted = false;
    } catch (e) {
      debugPrint('❌ Dispose sound error: $e');
    }
  }
}