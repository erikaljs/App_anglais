import 'package:flutter_tts/flutter_tts.dart';

/// Lit à voix haute un mot ou une phrase en anglais (synthèse vocale).
/// Utilisé sur les cartes, les phrases et les exemples de mini-leçon.
class TtsService {
  TtsService._();

  static final FlutterTts _tts = FlutterTts();
  static bool _preteInitialisee = false;

  static Future<void> _preparer() async {
    if (_preteInitialisee) return;
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    _preteInitialisee = true;
  }

  /// Lit [texte] en anglais. N'importe quelle lecture en cours est arrêtée
  /// d'abord, pour ne pas superposer deux voix.
  static Future<void> lire(String texte) async {
    await _preparer();
    await _tts.stop();
    await _tts.speak(texte);
  }
}
