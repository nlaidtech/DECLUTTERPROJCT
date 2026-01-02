import 'package:audioplayers/audioplayers.dart';

/// Sound Service
/// Handles playing notification sounds for the app
class SoundService {
  // Singleton pattern
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  AudioPlayer? _audioPlayer;

  /// Play message notification sound
  Future<void> playMessageSound() async {
    try {
      // Create new player for each sound (more reliable)
      _audioPlayer?.dispose();
      _audioPlayer = AudioPlayer();
      
      // Use a reliable free notification sound
      const soundUrl = 'https://cdn.pixabay.com/audio/2022/03/24/audio_d1718ab41b.mp3';
      
      await _audioPlayer!.setVolume(1.0);
      await _audioPlayer!.play(UrlSource(soundUrl));
      
      print('🔔 Playing notification sound');
    } catch (e) {
      print('Error playing sound: $e');
    }
  }

  /// Dispose audio player
  void dispose() {
    _audioPlayer?.dispose();
  }
}
