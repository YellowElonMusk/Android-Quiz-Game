/// Audio service stub.
///
/// In a production build, integrate FlameAudio or audioplayers
/// to play bundled .wav/.mp3 files. For now, this is a no-op
/// placeholder that defines the API surface.
class AudioService {
  bool _musicEnabled = true;
  bool _sfxEnabled = true;

  bool get musicEnabled => _musicEnabled;
  bool get sfxEnabled => _sfxEnabled;

  void toggleMusic() {
    _musicEnabled = !_musicEnabled;
  }

  void toggleSfx() {
    _sfxEnabled = !_sfxEnabled;
  }

  void playPunch() {
    // TODO: flame_audio punchSfx
  }

  void playKick() {
    // TODO: flame_audio kickSfx
  }

  void playSuplex() {
    // TODO: flame_audio suplexSfx
  }

  void playHit() {
    // TODO: flame_audio hitSfx
  }

  void playKo() {
    // TODO: flame_audio koSfx
  }

  void playVictory() {
    // TODO: flame_audio victorySfx
  }

  void playCorrect() {
    // TODO: flame_audio correctSfx
  }

  void playWrong() {
    // TODO: flame_audio wrongSfx
  }

  void playBgMusic() {
    // TODO: flame_audio bgMusic loop
  }

  void stopBgMusic() {
    // TODO: flame_audio stop bgMusic
  }

  void dispose() {
    // TODO: dispose audio players
  }
}
