// Speech synthesis service for accessible voice guidance.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceService {
  VoiceService._();

  static final VoiceService instance = VoiceService._();

  final FlutterTts _flutterTts = FlutterTts();
  final List<String> _pendingMessages = <String>[];

  bool _isInitialized = false;
  bool _isDisposed = false;
  bool _isEnabled = true;
  bool _isProcessingQueue = false;

  double _speechRate = 0.5;
  double _pitch = 1.0;
  double _volume = 1.0;
  String _selectedLanguage = 'en-US';

  String? _lastError;
  String? _lastSpokenMessage;
  DateTime? _lastSpokenAt;

  static const Duration _duplicateWindow = Duration(seconds: 5);

  bool get isInitialized => _isInitialized;
  bool get isEnabled => _isEnabled;
  double get speechRate => _speechRate;
  double get pitch => _pitch;
  double get volume => _volume;
  String get selectedLanguage => _selectedLanguage;
  String? get lastError => _lastError;
  bool get isBusy => _isProcessingQueue || _pendingMessages.isNotEmpty;

  Future<void> initialize() async {
    if (_isDisposed || _isInitialized) {
      return;
    }

    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        await _flutterTts.setSharedInstance(true);
      }
      await _flutterTts.awaitSpeakCompletion(true);
      await setSpeechRate(_speechRate);
      await setPitch(_pitch);
      await setVolume(_volume);
      await selectLanguage(_selectedLanguage);

      _flutterTts.setErrorHandler((message) {
        _lastError = message;
        debugPrint('TTS Error: $message');
      });

      _flutterTts.setCompletionHandler(() {
        debugPrint('TTS completed.');
      });

      _lastError = null;
      _isInitialized = true;
    } catch (error) {
      _lastError = 'Unable to initialize voice synthesis.';
      debugPrint('TTS initialization failed: $error');
    }
  }

  Future<void> speak(String text, {bool isUrgent = false}) async {
    final message = text.trim();
    if (message.isEmpty || _isDisposed || !_isEnabled) {
      return;
    }

    if (isUrgent) {
      // Immediate hazard priority interrupt: clear non-urgent queue and cut off ongoing speech.
      _pendingMessages.clear();
      try {
        await _flutterTts.stop();
      } catch (_) {}
      _lastSpokenAt = null;
      _pendingMessages.add(message);
      _isProcessingQueue = false;
      unawaited(_processQueue());
      return;
    }

    if (_shouldSuppress(message)) {
      if (kDebugMode) {
        debugPrint('[VoiceService] Suppressed duplicate message: "$message"');
      }
      return;
    }

    _pendingMessages.add(message);
    if (kDebugMode) {
      debugPrint(
        '[VoiceService] Message queued: "$message" (pending=${_pendingMessages.length})',
      );
    }
    if (!_isProcessingQueue) {
      unawaited(_processQueue());
    }
  }

  Future<void> stop() async {
    if (_isDisposed) {
      return;
    }

    _pendingMessages.clear();
    try {
      await _flutterTts.stop();
    } catch (error) {
      _lastError = 'Unable to stop speech.';
      debugPrint('TTS stop failed: $error');
    }
  }

  Future<void> pause() async {
    if (_isDisposed) {
      return;
    }

    try {
      await _flutterTts.pause();
    } catch (error) {
      _lastError = 'Unable to pause speech.';
      debugPrint('TTS pause failed: $error');
    }
  }

  Future<void> resume() async {
    if (_isDisposed || _lastSpokenMessage == null) return;

    // Reset the suppression window before re-speaking so that if resume() is
    // called within 2 s of the last utterance the guard does not silently
    // drop the message — leaving the user with no audio after app resume.
    _lastSpokenAt = null;
    await speak(_lastSpokenMessage!);
  }

  Future<void> setSpeechRate(double value) async {
    _speechRate = value.clamp(0.0, 1.0);
    if (_isInitialized) {
      try {
        await _flutterTts.setSpeechRate(_speechRate);
      } catch (error) {
        _lastError = 'Unable to update speech rate.';
        debugPrint('TTS rate update failed: $error');
      }
    }
  }

  Future<void> setPitch(double value) async {
    _pitch = value.clamp(0.5, 2.0);
    if (_isInitialized) {
      try {
        await _flutterTts.setPitch(_pitch);
      } catch (error) {
        _lastError = 'Unable to update pitch.';
        debugPrint('TTS pitch update failed: $error');
      }
    }
  }

  Future<void> setVolume(double value) async {
    _volume = value.clamp(0.0, 1.0);
    if (_isInitialized) {
      try {
        await _flutterTts.setVolume(_volume);
      } catch (error) {
        _lastError = 'Unable to update volume.';
        debugPrint('TTS volume update failed: $error');
      }
    }
  }

  Future<void> selectLanguage(String languageCode) async {
    _selectedLanguage = languageCode;
    if (_isInitialized) {
      try {
        await _flutterTts.setLanguage(languageCode);
      } catch (error) {
        _lastError = 'Unable to change language.';
        debugPrint('TTS language change failed: $error');
      }
    }
  }

  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    if (!enabled) {
      await stop();
    }
  }

  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }

    _isDisposed = true;
    _pendingMessages.clear();
    try {
      await _flutterTts.stop();
    } catch (error) {
      debugPrint('TTS disposal failed: $error');
    }
  }

  Future<void> _processQueue() async {
    if (_isProcessingQueue) {
      return;
    }

    _isProcessingQueue = true;
    try {
      while (_pendingMessages.isNotEmpty) {
        final message = _pendingMessages.removeAt(0);
        await _speakMessage(message);
      }
    } finally {
      _isProcessingQueue = false;
    }
  }

  Future<void> _speakMessage(String message) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_isDisposed || !_isEnabled) {
      return;
    }

    try {
      await _flutterTts.speak(message);
      _lastSpokenMessage = message;
      _lastSpokenAt = DateTime.now();
      _lastError = null;
    } catch (error) {
      _lastError = 'Unable to speak the requested message.';
      debugPrint('TTS speak failed: $error');
    }
  }

  bool _shouldSuppress(String message) {
    if (_lastSpokenMessage == null || _lastSpokenAt == null) {
      return false;
    }

    final normalizedMessage = _normalizeText(message);
    final normalizedLastMessage = _normalizeText(_lastSpokenMessage!);
    final elapsed = DateTime.now().difference(_lastSpokenAt!);

    return normalizedMessage == normalizedLastMessage &&
        elapsed < _duplicateWindow;
  }

  String _normalizeText(String text) {
    return text.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}
