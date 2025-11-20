import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static bool _isInitialized = false;

  static AudioPlayer get player => _audioPlayer;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _audioPlayer.seek(Duration.zero);
        _audioPlayer.pause();
      }
    });

    _isInitialized = true;
  }

  static Future<void> playAyah(int surahNumber, int ayahNumber) async {
    try {
      await initialize();

      final surahStr = surahNumber.toString().padLeft(3, '0');
      final ayahStr = ayahNumber.toString().padLeft(3, '0');

      // استخدام مصدر صوتي (مثال: Mishary Rashid Alafasy)
      final url =
          'https://everyayah.com/data/Alafasy_128kbps/$surahStr$ayahStr.mp3';

      debugPrint('🎵 تشغيل الصوت: $url');

      await _audioPlayer.setUrl(url);
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('❌ خطأ في تشغيل الصوت: $e');
      rethrow;
    }
  }

  static Future<void> pause() async {
    await _audioPlayer.pause();
  }

  static Future<void> resume() async {
    await _audioPlayer.play();
  }

  static Future<void> stop() async {
    await _audioPlayer.stop();
  }

  static Future<void> dispose() async {
    await _audioPlayer.dispose();
  }

  static bool get isPlaying => _audioPlayer.playing;

  static Stream<Duration> get positionStream => _audioPlayer.positionStream;

  static Stream<Duration?> get durationStream => _audioPlayer.durationStream;

  static Stream<PlayerState> get playerStateStream =>
      _audioPlayer.playerStateStream;
}
