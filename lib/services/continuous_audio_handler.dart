// lib/services/continuous_audio_handler.dart

import 'package:flutter/widgets.dart';
import 'package:just_audio/just_audio.dart';
import 'package:quran/quran.dart' as quran;
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
  int _playingSurah = 0; // ✅ الآية اللي شغالة فعلاً
  int _playingAyah = 0; // ✅ الآية اللي شغالة فعلاً
  bool _isPlayingContinuously = false;
  String _currentReciter = 'Alafasy_128kbps'; // ✅ حفظ القارئ الحالي

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
      // ✅ الاستماع لبدء التشغيل لتحديث الواجهة فوراً
      _audioPlayer.playerStateStream.listen((state) {
        // عند بدء التشغيل، تأكد من تحديث الواجهة
        if (state.processingState == ProcessingState.ready ||
            state.processingState == ProcessingState.buffering) {
          // لا شيء - الحالة محدثة بالفعل
        }

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

  /// ✅ تحديث القارئ أثناء التشغيل
  void updateReciter(String newReciter) {
    _currentReciter = newReciter;
    debugPrint('🎙️ تم تغيير القارئ إلى: $newReciter');
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
      _currentReciter = reciter; // ✅ حفظ القارئ

      // حفظ الحالة
      await _savePlaybackState();

      // بدء التشغيل
      return await _playNextAyah(surahNumber, startAyah);
    } catch (e) {
      debugPrint('❌ خطأ في بدء القراءة المستمرة: $e');
      return false;
    }
  }

  /// تشغيل الآية التالية تلقائياً
  Future<bool> _playNextAyah(int surahNumber, int ayahNumber) async {
    try {
      debugPrint(
        '🎵 جاري تشغيل: $surahNumber:$ayahNumber بصوت $_currentReciter',
      );

      // ✅ استخدام القارئ المحفوظ
      final url = _buildAudioUrl(surahNumber, ayahNumber, _currentReciter);

      // ✅ تحديث الآية اللي هتتشغل دلوقتي (للعرض فقط)
      _playingSurah = surahNumber;
      _playingAyah = ayahNumber;

      await _audioPlayer.setUrl(url);
      await _audioPlayer.play();

      // ✅ بعد التشغيل، حفظ الآية اللي فعلاً اتشغلت
      _currentSurah = surahNumber;
      _currentAyah = ayahNumber;

      // حفظ التقدم
      await _savePlaybackState();

      debugPrint('✅ تم تشغيل: $surahNumber:$ayahNumber');

      return true;
    } catch (e) {
      debugPrint('❌ خطأ في تشغيل الآية: $e');
      return false;
    }
  }

  /// معالج انتهاء الآية
  Future<void> _onAyahCompleted() async {
    try {
      if (!_isPlayingContinuously) return;

      // 🔄 الانتقال إلى الآية التالية تلقائياً
      int nextAyah = _currentAyah + 1;
      int totalAyahs = quran.getVerseCount(_currentSurah);

      if (nextAyah <= totalAyahs) {
        // الاستمرار في نفس السورة
        debugPrint('📖 الانتقال للآية التالية: $_currentSurah:$nextAyah');
        await _playNextAyah(_currentSurah, nextAyah);
      } else {
        // الانتقال إلى السورة التالية
        int nextSurah = _currentSurah + 1;
        if (nextSurah <= 114) {
          debugPrint('📖 الانتقال للسورة التالية: $nextSurah');
          await _playNextAyah(nextSurah, 1);
        } else {
          // انتهت القراءة - ختم القرآن!
          debugPrint('🎉 تم ختم القرآن الكريم!');
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
      await _audioPlayer.stop();
      await _audioPlayer.pause();
      _isPlayingContinuously = false;
      _currentSurah = 0;
      _currentAyah = 0;
      _playingSurah = 0;
      _playingAyah = 0;
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
      await prefs.setString('selected_reciter', _currentReciter);
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
  bool get isPlaying => _audioPlayer.playing && _isPlayingContinuously;
  bool get isContinuousReading => _isPlayingContinuously;
  int get currentSurah => _playingSurah > 0 ? _playingSurah : _currentSurah;
  int get currentAyah => _playingAyah > 0 ? _playingAyah : _currentAyah;
  String get currentReciter => _currentReciter;

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
