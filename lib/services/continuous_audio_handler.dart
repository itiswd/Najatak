// lib/services/continuous_audio_handler.dart

import 'package:flutter/widgets.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// معالج الصوت المستمر
/// يضمن استمرار القراءة والصوت حتى مع إغلاق التطبيق
/// أو عند قفل الشاشة
class ContinuousAudioHandler {
  static final ContinuousAudioHandler _instance =
      ContinuousAudioHandler._internal();
  late AudioPlayer _audioPlayer;
  int _currentSurah = 0;
  int _currentAyah = 0;
  bool _isPlayingContinuously = false;

  factory ContinuousAudioHandler() {
    return _instance;
  }

  ContinuousAudioHandler._internal() {
    _audioPlayer = AudioPlayer();
    _setupAudioSession();
    _loadPlaybackState();
  }

  /// تهيئة معالج الصوت المستمر
  Future<void> initialize() async {
    try {
      await _setupAudioSession();
      await _loadPlaybackState();
      debugPrint('✅ تم تهيئة معالج الصوت المستمر بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة معالج الصوت: $e');
    }
  }

  /// تهيئة جلسة الصوت للعمل في الخلفية
  Future<void> _setupAudioSession() async {
    try {
      // ✅ السماح بالتشغيل حتى مع قفل الشاشة
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

  /// تحميل حالة التشغيل المحفوظة
  Future<void> _loadPlaybackState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentSurah = prefs.getInt('quran_playback_surah') ?? 0;
      _currentAyah = prefs.getInt('quran_playback_ayah') ?? 0;
      _isPlayingContinuously =
          prefs.getBool('is_playing_continuously') ?? false;

      if (_isPlayingContinuously && _currentSurah > 0) {
        debugPrint(
          '📖 استئناف القراءة من السورة $_currentSurah الآية $_currentAyah',
        );
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحميل حالة التشغيل: $e');
    }
  }

  /// بدء القراءة المستمرة من سورة معينة
  Future<bool> startContinuousReading({
    required int surahNumber,
    required int startAyah,
    required int totalAyahs,
    String reciter = 'Alafasy_128kbps',
  }) async {
    try {
      debugPrint('🔊 بدء قراءة مستمرة من السورة $surahNumber');

      _currentSurah = surahNumber;
      _currentAyah = startAyah;
      _isPlayingContinuously = true;

      // حفظ الحالة
      await _savePlaybackState();

      // بدء التشغيل
      return await _playNextAyah(surahNumber, startAyah, reciter);
    } catch (e) {
      debugPrint('❌ خطأ في بدء القراءة المستمرة: $e');
      return false;
    }
  }

  /// تشغيل الآية التالية تلقائياً
  Future<bool> _playNextAyah(
    int surahNumber,
    int ayahNumber,
    String reciter,
  ) async {
    try {
      final url = _buildAudioUrl(surahNumber, ayahNumber, reciter);

      debugPrint('🎵 تشغيل: $surahNumber:$ayahNumber');

      await _audioPlayer.setUrl(url);
      await _audioPlayer.play();

      _currentSurah = surahNumber;
      _currentAyah = ayahNumber;

      // حفظ التقدم
      await _savePlaybackState();

      return true;
    } catch (e) {
      debugPrint('❌ خطأ في تشغيل الآية: $e');
      return false;
    }
  }

  /// معالج انتهاء الآية
  Future<void> _onAyahCompleted() async {
    try {
      // 🔄 الانتقال إلى الآية التالية تلقائياً
      int nextAyah = _currentAyah + 1;

      if (nextAyah <= 286) {
        // مثال: السورة لها 286 آية
        // يجب جلب عدد الآيات من قاعدة البيانات
        await _playNextAyah(_currentSurah, nextAyah, 'Alafasy_128kbps');
      } else {
        // الانتقال إلى السورة التالية
        int nextSurah = _currentSurah + 1;
        if (nextSurah <= 114) {
          await _playNextAyah(nextSurah, 1, 'Alafasy_128kbps');
        } else {
          // انتهت القراءة
          await stopContinuousReading();
        }
      }
    } catch (e) {
      debugPrint('❌ خطأ في الانتقال للآية التالية: $e');
    }
  }

  /// إيقاف القراءة المستمرة
  Future<void> stopContinuousReading() async {
    try {
      await _audioPlayer.pause();
      _isPlayingContinuously = false;
      await _savePlaybackState();
      debugPrint('⏹️ تم إيقاف القراءة المستمرة');
    } catch (e) {
      debugPrint('❌ خطأ في إيقاف القراءة: $e');
    }
  }

  /// إعادة تشغيل القراءة
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

  /// حفظ حالة التشغيل
  Future<void> _savePlaybackState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('quran_playback_surah', _currentSurah);
      await prefs.setInt('quran_playback_ayah', _currentAyah);
      await prefs.setBool('is_playing_continuously', _isPlayingContinuously);
    } catch (e) {
      debugPrint('❌ خطأ في حفظ حالة التشغيل: $e');
    }
  }

  /// بناء رابط الصوت
  String _buildAudioUrl(int surahNumber, int ayahNumber, String reciter) {
    final surahStr = surahNumber.toString().padLeft(3, '0');
    final ayahStr = ayahNumber.toString().padLeft(3, '0');
    return 'https://everyayah.com/data/$reciter/$surahStr$ayahStr.mp3';
  }

  /// الحصول على حالة التشغيل الحالية
  bool get isPlaying => _audioPlayer.playing;
  bool get isContinuousReading => _isPlayingContinuously;
  int get currentSurah => _currentSurah;
  int get currentAyah => _currentAyah;

  /// الحصول على مجرى تدفق حالة المشغل
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;

  /// الحصول على مجرى تدفق المدة الزمنية
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;

  /// الحصول على مجرى تدفق الموضع
  Stream<Duration> get positionStream => _audioPlayer.positionStream;

  /// تنظيف الموارد
  Future<void> dispose() async {
    try {
      await _audioPlayer.dispose();
      debugPrint('🗑️ تم تنظيف موارد معالج الصوت');
    } catch (e) {
      debugPrint('❌ خطأ في تنظيف الموارد: $e');
    }
  }
}
