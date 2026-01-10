import 'package:audioplayers/audioplayers.dart';

class SoundManager {
  SoundManager._();

  static final AudioPlayer _musicPlayer = AudioPlayer()
    ..setReleaseMode(ReleaseMode.loop);
  static final AudioPlayer _sfxPlayer = AudioPlayer();

  /// Проигрывает фоновую музыку (зацикленно)
  static Future<void> playMusic(String assetPath) async {
    try {
      await _musicPlayer.stop();
      // AssetSource автоматически ищет в папке assets, поэтому убираем префикс, если он есть
      final path = assetPath.startsWith('assets/') 
          ? assetPath.substring('assets/'.length) 
          : assetPath;
      await _musicPlayer.play(AssetSource(path));
    } catch (_) {
      // Игнорируем ошибки (например, если файл не найден)
    }
  }

  /// Останавливает музыку
  static Future<void> stopMusic() => _musicPlayer.stop();

  /// Проигрывает короткий звуковой эффект (SFX)
  static Future<void> playSfx(String assetPath) async {
    try {
      await _sfxPlayer.stop(); // Останавливаем предыдущий звук, если был
      final path = assetPath.startsWith('assets/') 
          ? assetPath.substring('assets/'.length) 
          : assetPath;
      await _sfxPlayer.play(AssetSource(path));
    } catch (_) {
      // Игнорируем ошибки (например, если файл не найден)
    }
  }
}
