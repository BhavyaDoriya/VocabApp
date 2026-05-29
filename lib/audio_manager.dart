import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart'; // <-- 1. IMPORT FOUNDATION

class AudioManager {
  // The Singleton instance
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  
  // Dedicated players so BGM and SFX don't interrupt each other
  final AudioPlayer _bgmPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  bool _isBgmPlaying = false;

  // --- THE FIX: AUDIO CONTEXT CONFIGURATION ---
  AudioManager._internal() {
    // Tell the OS to allow audio mixing and NEVER steal audio focus
    // 2. ONLY APPLY THIS ON NATIVE APPS, IGNORE ON WEB
    if (!kIsWeb) {
      final audioContext = AudioContext(
        android: AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.none, // <-- THIS IS THE MAGIC KEY
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.ambient, // Allows mixing on iOS
          options: const { // <-- CHANGED TO CURLY BRACES AND ADDED const
            AVAudioSessionOptions.mixWithOthers,
          },
        ),
      );
      AudioPlayer.global.setAudioContext(audioContext);
    }
  }

  // --- BACKGROUND MUSIC ---
  Future<void> startBgm() async {
    if (_isBgmPlaying) return; // Don't restart if already playing
    
    _bgmPlayer.setReleaseMode(ReleaseMode.loop); // Loop endlessly
    await _bgmPlayer.setVolume(0.3); // Quiet background volume
    
    try {
      await _bgmPlayer.play(AssetSource('audio/bgm.mp3'));
      _isBgmPlaying = true;
    } catch (e) {
      print("Audio block: $e");
    }
  }

  Future<void> stopBgm() async {
    await _bgmPlayer.stop();
    _isBgmPlaying = false;
  }

  // --- SOUND EFFECTS ---
  
  // The light, snappy sound for the < > selectors
  Future<void> playClick() async {
    await _sfxPlayer.stop(); // Instantly kills any currently playing SFX
    await _sfxPlayer.setVolume(0.8);
    await _sfxPlayer.play(AssetSource('audio/click.mp3'), mode: PlayerMode.lowLatency);
  }

  // The heavy, satisfying gear sound for main INITIALIZE/ENGAGE buttons
  Future<void> playThump() async {
    await _sfxPlayer.stop(); // Instantly kills the long echo if you rapid-fire click
    await _sfxPlayer.setVolume(1.0);
    await _sfxPlayer.play(AssetSource('audio/thump.mp3'), mode: PlayerMode.lowLatency);
  }
}