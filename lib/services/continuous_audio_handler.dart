// lib/services/continuous_audio_handler.dart
// ✅ محسّن لحفظ واستئناف الموضع بشكل صحيح

import 'package:flutter/widgets.dart';
import 'package:just_audio/just_audio.dart';
import 'package:quran/quran.dart' as quran;
import 'package:shared_preferences/shared_preferences.dart';

class ContinuousAudioHandler {
  static final ContinuousAudioHandler _instance =
      ContinuousAudioHandler._internal();

  late AudioPlayer _audioPlayer;
  int _currentSurah = 0;
  int _currentAyah = 0;
  int _playingSurah = 0;
  int _playingAyah = 0;
  bool _isPlayingContinuously = false;
  String _currentReciter = 'Alafasy_128kbps';

  factory ContinuousAudioHandler() {
    return _instance;
  }

  ContinuousAudioHandler._internal() {
    _audioPlayer = AudioPlayer();
    _setupAudioSession();
    _loadPlaybackState();
  }

  Future<void> initialize() async {
    try {
      await _setupAudioSession();
      await _loadPlaybackState();
      debugPrint('✅ تم تهيئة معالج الصوت المستمر بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة معالج الصوت: $e');
    }
  }

  Future<void> _setupAudioSession() async {
    try {
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _onAyahCompleted();
        }
      });

      debugPrint('✅ تم تهيئة جلسة الصوت للعمل في الخلفية');
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة جلسة الصوت: $e');
    }
  }

  Future<void> _loadPlaybackState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentSurah = prefs.getInt('quran_playback_surah') ?? 0;
      _currentAyah = prefs.getInt('quran_playback_ayah') ?? 0;
      _isPlayingContinuously =
          prefs.getBool('is_playing_continuously') ?? false;
      _currentReciter =
          prefs.getString('selected_reciter') ?? 'Alafasy_128kbps';

      if (_isPlayingContinuously && _currentSurah > 0) {
        debugPrint(
          '📖 استئناف القراءة من السورة $_currentSurah الآية $_currentAyah',
        );
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحميل حالة التشغيل: $e');
    }
  }

  void updateReciter(String newReciter) {
    _currentReciter = newReciter;
    debugPrint('🎙️ تم تغيير القارئ إلى: $newReciter');
  }

  Future<bool> startContinuousReading({
    required int surahNumber,
    required int startAyah,
    required int totalAyahs,
    String reciter = 'Alafasy_128kbps',
  }) async {
    try {
      debugPrint('🔊 بدء قراءة مستمرة من السورة $surahNumber الآية $startAyah');

      _currentSurah = surahNumber;
      _currentAyah = startAyah;
      _isPlayingContinuously = true;
      _currentReciter = reciter;

      await _savePlaybackState();

      return await _playNextAyah(surahNumber, startAyah);
    } catch (e) {
      debugPrint('❌ خطأ في بدء القراءة المستمرة: $e');
      return false;
    }
  }

  Future<bool> _playNextAyah(int surahNumber, int ayahNumber) async {
    try {
      debugPrint(
        '🎵 جاري تشغيل: $surahNumber:$ayahNumber بصوت $_currentReciter',
      );

      final url = _buildAudioUrl(surahNumber, ayahNumber, _currentReciter);

      _playingSurah = surahNumber;
      _playingAyah = ayahNumber;

      await _audioPlayer.setUrl(url);
      await _audioPlayer.play();

      _currentSurah = surahNumber;
      _currentAyah = ayahNumber;

      await _savePlaybackState();

      debugPrint('✅ تم تشغيل: $surahNumber:$ayahNumber');

      return true;
    } catch (e) {
      debugPrint('❌ خطأ في تشغيل الآية: $e');
      return false;
    }
  }

  Future<void> _onAyahCompleted() async {
    try {
      if (!_isPlayingContinuously) return;

      int nextAyah = _currentAyah + 1;
      int totalAyahs = quran.getVerseCount(_currentSurah);

      if (nextAyah <= totalAyahs) {
        debugPrint('📖 الانتقال للآية التالية: $_currentSurah:$nextAyah');
        await _playNextAyah(_currentSurah, nextAyah);
      } else {
        int nextSurah = _currentSurah + 1;
        if (nextSurah <= 114) {
          debugPrint('📖 الانتقال للسورة التالية: $nextSurah');
          await _playNextAyah(nextSurah, 1);
        } else {
          debugPrint('🎉 تم ختم القرآن الكريم!');
          await stopContinuousReading();
        }
      }
    } catch (e) {
      debugPrint('❌ خطأ في الانتقال للآية التالية: $e');
    }
  }

  Future<void> stopContinuousReading() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.pause();
      _isPlayingContinuously = false;

      // ✅ لا نمسح الموضع عند الإيقاف - نحتفظ به للاستئناف
      // _currentSurah = 0;
      // _currentAyah = 0;
      _playingSurah = 0;
      _playingAyah = 0;

      await _savePlaybackState();
      debugPrint('⏹️ تم إيقاف القراءة المستمرة');
    } catch (e) {
      debugPrint('❌ خطأ في إيقاف القراءة: $e');
    }
  }

  Future<void> resumeContinuousReading() async {
    try {
      await _audioPlayer.play();
      _isPlayingContinuously = true;
      await _savePlaybackState();
      debugPrint('▶️ استئناف القراءة المستمرة');
    } catch (e) {
      debugPrint('❌ خطأ في استئناف القراءة: $e');
    }
  }

  Future<void> _savePlaybackState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('quran_playback_surah', _currentSurah);
      await prefs.setInt('quran_playback_ayah', _currentAyah);
      await prefs.setBool('is_playing_continuously', _isPlayingContinuously);
      await prefs.setString('selected_reciter', _currentReciter);

      debugPrint('💾 تم حفظ الموضع: سورة $_currentSurah، آية $_currentAyah');
    } catch (e) {
      debugPrint('❌ خطأ في حفظ حالة التشغيل: $e');
    }
  }

  String _buildAudioUrl(int surahNumber, int ayahNumber, String reciter) {
    final surahStr = surahNumber.toString().padLeft(3, '0');
    final ayahStr = ayahNumber.toString().padLeft(3, '0');
    return 'https://everyayah.com/data/$reciter/$surahStr$ayahStr.mp3';
  }

  // ✅ دالة جديدة للحصول على آخر موضع محفوظ
  Future<Map<String, int>?> getLastSavedPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final surah = prefs.getInt('quran_playback_surah') ?? 0;
      final ayah = prefs.getInt('quran_playback_ayah') ?? 0;

      if (surah > 0 && ayah > 0) {
        return {'surah': surah, 'ayah': ayah};
      }
      return null;
    } catch (e) {
      debugPrint('❌ خطأ في جلب آخر موضع: $e');
      return null;
    }
  }

  bool get isPlaying => _audioPlayer.playing && _isPlayingContinuously;
  bool get isContinuousReading => _isPlayingContinuously;
  int get currentSurah => _playingSurah > 0 ? _playingSurah : _currentSurah;
  int get currentAyah => _playingAyah > 0 ? _playingAyah : _currentAyah;
  String get currentReciter => _currentReciter;

  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Stream<Duration> get positionStream => _audioPlayer.positionStream;

  Future<void> dispose() async {
    try {
      await _audioPlayer.dispose();
      debugPrint('🗑️ تم تنظيف موارد معالج الصوت');
    } catch (e) {
      debugPrint('❌ خطأ في تنظيف الموارد: $e');
    }
  }
}
