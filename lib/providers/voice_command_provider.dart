import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceCommandProvider extends ChangeNotifier {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool isListening = false;
  String command = "";
  bool _isProcessingCommand = false;
  Function(String)? onCommandExecuted;

  VoiceCommandProvider() {
    _initSpeech();
  }

  void _initSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'notListening' && !_isProcessingCommand) {
          _startListening();
        }
      },
    );
    if (available) {
      _startListening();
    }
  }

  void _startListening() async {
    // if (_isProcessingCommand || isListening) return;
    // await _speech.listen(
    //   onResult: (result) {
    //     String text = result.recognizedWords.toLowerCase();
    //     print(text);
    //     if (text.contains("eva")) {
    //       isListening = true;
    //       notifyListeners();
    //       _isProcessingCommand = true;
    //       _listenForCommand();
    //     }
    //   },
    //   listenFor: const Duration(seconds: 60),
    //   cancelOnError: false,
    //   localeId: 'pt_BR',
    // );
  }

  void _listenForCommand() async {
    await _speech.listen(
      onResult: (result) {
        command = result.recognizedWords;
        notifyListeners();
        if (onCommandExecuted != null) {
          onCommandExecuted!(command);
        }
      },
      listenFor: const Duration(seconds: 5),
      cancelOnError: false,
      localeId: 'pt_BR',
    );
    await Future.delayed(const Duration(seconds: 5));
    isListening = false;
    _isProcessingCommand = false;
    command = "";
    notifyListeners();
    _startListening();
  }
}