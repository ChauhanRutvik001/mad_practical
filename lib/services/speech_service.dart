import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../utils/constants.dart';

class SpeechService {
  // Text-to-speech engine
  final FlutterTts _flutterTts = FlutterTts();

  // Speech-to-text engine
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;
  String _lastRecognizedWords = '';

  // Error states
  String? _lastError;

  // Callback for when speech is recognized
  Function(String)? _onSpeechResult;

  // Singleton pattern
  static final SpeechService _instance = SpeechService._internal();

  factory SpeechService() {
    return _instance;
  }

  SpeechService._internal();

  // Initialize both speech engines
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    bool speechInitialized = false;
    try {
      // For web, we need to specifically handle permissions
      if (kIsWeb) {
        // This ensures the browser will properly request microphone permission
        bool available = await _speech.initialize(
          onStatus: _onSpeechStatus,
          onError: _onSpeechError,
          debugLogging: true,
        );

        if (available) {
          // On web, we should check if the microphone permissions are granted
          var hasSpeech = await _speech.hasPermission;
          if (!hasSpeech) {
            print('No microphone permission granted');
            _lastError = 'Microphone permission not granted';
            speechInitialized = false;
          } else {
            _isInitialized = true;
            speechInitialized = true;
            print('Speech recognition initialized successfully on web');
          }
        } else {
          print('Speech recognition not available on this device/browser');
          _lastError = 'Speech recognition not available';
          speechInitialized = false;
        }
      } else {
        // Non-web initialization
        speechInitialized = await _speech.initialize(
          onStatus: _onSpeechStatus,
          onError: _onSpeechError,
          debugLogging: true,
        );

        if (speechInitialized) {
          _isInitialized = true;
          print('Speech recognition initialized successfully');
        } else {
          print('Speech recognition failed to initialize');
          _lastError = 'Failed to initialize speech recognition';
        }
      }
    } catch (e) {
      print('Error initializing speech recognition: $e');
      _lastError = 'Failed to initialize speech recognition: $e';
      speechInitialized = false;
    }

    // Initialize TTS
    try {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      print('Text-to-speech initialized successfully');
    } catch (e) {
      print('Error initializing text-to-speech: $e');
      _lastError = 'Failed to initialize text-to-speech: $e';
      // Continue anyway, as we can still use speech-to-text
    }

    return speechInitialized;
  }

  // Start listening for voice commands
  Future<bool> startListening(Function(String) onResult) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        _lastError = 'Speech recognition not initialized';
        return false;
      }
    }

    if (_isListening) {
      return true; // Already listening
    }

    _onSpeechResult = onResult;
    _lastRecognizedWords = '';

    try {
      // For web, we need to ensure we have permission before listening
      if (kIsWeb) {
        var hasSpeech = await _speech.hasPermission;
        if (!hasSpeech) {
          // Try to initialize again to trigger the browser permission prompt
          print('Requesting microphone permission');
          await _speech.initialize(
            onStatus: _onSpeechStatus,
            onError: _onSpeechError,
          );
          hasSpeech = await _speech.hasPermission;
          if (!hasSpeech) {
            _lastError = 'Microphone permission denied';
            print(_lastError);
            return false;
          }
        }
      }

      _isListening = await _speech.listen(
        onResult: _processRecognitionResult,
        listenFor: const Duration(seconds: 30), // Listen for up to 30 seconds
        pauseFor:
            const Duration(seconds: 5), // Auto-stop after 5 seconds of silence
        partialResults: true, // Get results as they come in
        localeId: 'en_US', // Use English
        cancelOnError: true,
      );

      return _isListening;
    } catch (e) {
      _lastError = 'Error starting speech recognition: $e';
      _isListening = false;
      return false;
    }
  }

  // Stop listening
  Future<bool> stopListening() async {
    if (!_isListening) return true;

    try {
      await _speech.stop();
      _isListening = false;
      return true;
    } catch (e) {
      _lastError = 'Error stopping speech recognition: $e';
      return false;
    }
  }

  // Speak text using TTS
  Future<bool> speak(String text) async {
    if (text.isEmpty) return false;

    try {
      // Pick a random feedback message if it's one of our standard types
      if (text.contains('Command processed')) {
        final successMessages = AppConstants.feedbackMessages['success']!;
        final randomIndex = DateTime.now().microsecond % successMessages.length;
        text = successMessages[randomIndex];
      } else if (text.contains('couldn\'t understand')) {
        final errorMessages = AppConstants.feedbackMessages['error']!;
        final randomIndex = DateTime.now().microsecond % errorMessages.length;
        text = errorMessages[randomIndex];
      }

      // Speak the text
      await _flutterTts.speak(text);
      return true;
    } catch (e) {
      _lastError = 'Error with text-to-speech: $e';
      return false;
    }
  }

  // Process the speech recognition results
  void _processRecognitionResult(SpeechRecognitionResult result) {
    String recognizedWords = result.recognizedWords;

    if (recognizedWords.isNotEmpty) {
      _lastRecognizedWords = recognizedWords;

      // If we have final results or sufficiently long partial results, call the callback
      if (result.finalResult ||
          (result.recognizedWords.length > 10 && result.confidence > 0.5)) {
        _onSpeechResult?.call(recognizedWords);
      }
    }
  }

  // Handle speech recognition status changes
  void _onSpeechStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      _isListening = false;

      // If we have recognized words, call the callback one more time
      if (_lastRecognizedWords.isNotEmpty && _onSpeechResult != null) {
        _onSpeechResult!(_lastRecognizedWords);
        _lastRecognizedWords = '';
      }
    }
  }

  // Handle speech recognition errors
  void _onSpeechError(dynamic error) {
    _isListening = false;
    _lastError = 'Speech recognition error: $error';
    print(_lastError);
  }

  // Get the most recent error
  String? get lastError => _lastError;

  // Check if the speech service is listening
  bool get isListening => _isListening;

  // Get a list of available voices
  Future<List<String>> getAvailableVoices() async {
    try {
      final voices = await _flutterTts.getVoices;
      final List<String> voiceNames = [];

      if (voices is List) {
        for (var voice in voices) {
          if (voice is Map && voice.containsKey('name')) {
            voiceNames.add(voice['name']!.toString());
          }
        }
      }

      return voiceNames;
    } catch (e) {
      _lastError = 'Error getting available voices: $e';
      return [];
    }
  }

  // Set TTS language
  Future<void> setLanguage(String language) async {
    try {
      await _flutterTts.setLanguage(language);
    } catch (e) {
      _lastError = 'Error setting language: $e';
    }
  }

  // Dispose resources
  void dispose() {
    stopListening();
    _flutterTts.stop();
  }
}
