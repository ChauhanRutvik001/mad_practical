import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isListening = false;

  // Singleton instance
  static final SpeechService _instance = SpeechService._internal();

  factory SpeechService() {
    return _instance;
  }

  SpeechService._internal() {
    _initializeTts();
  }

  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
  }

  // Initialize speech recognition
  Future<bool> initialize() async {
    try {
      bool available = await _speech.initialize(
        onStatus: (status) {
          print('Speech recognition status: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
          }
        },
        onError: (errorNotification) {
          print('Speech recognition error: $errorNotification');
          _isListening = false;
        },
      );
      return available;
    } catch (e) {
      print('Error initializing speech recognition: $e');
      return false;
    }
  }

  // Start listening for voice input
  Future<void> startListening(Function(String) onResult) async {
    if (!_isListening) {
      _isListening = true;

      await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            _isListening = false;
            onResult(result.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        partialResults: false,
        localeId: "en_US",
        cancelOnError: true,
      );
    }
  }

  // Stop listening
  Future<void> stopListening() async {
    if (_isListening) {
      _isListening = false;
      await _speech.stop();
    }
  }

  // Check if the speech recognition is currently active
  bool get isListening => _isListening;

  // Speak the given text
  Future<void> speak(String text) async {
    if (text.isNotEmpty) {
      await _flutterTts.speak(text);
    }
  }

  // Stop speaking
  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
  }
}
