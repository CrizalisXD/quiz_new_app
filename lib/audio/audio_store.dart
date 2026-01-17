import 'package:shared_preferences/shared_preferences.dart';
import 'audio_settings.dart';

class AudioStore {
  const AudioStore();

  // NOTE: ключи глобальные (не зависят от userId). Если нужно per-user — добавим префикс u:<id>|
  static const _kMusicVol = 'audio.music.volume';
  static const _kSfxVol = 'audio.sfx.volume';
  static const _kMusicOn = 'audio.music.enabled';
  static const _kSfxOn = 'audio.sfx.enabled';

  double _clamp01(num v) => v.clamp(0.0, 1.0).toDouble();

  Future<AudioSettings> load() async {
    final p = await SharedPreferences.getInstance();
    return AudioSettings(
      musicVolume: _clamp01(p.getDouble(_kMusicVol) ?? AudioSettings.defaults.musicVolume),
      sfxVolume: _clamp01(p.getDouble(_kSfxVol) ?? AudioSettings.defaults.sfxVolume),
      musicEnabled: p.getBool(_kMusicOn) ?? AudioSettings.defaults.musicEnabled,
      sfxEnabled: p.getBool(_kSfxOn) ?? AudioSettings.defaults.sfxEnabled,
    );
  }

  Future<void> save(AudioSettings s) async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_kMusicVol, _clamp01(s.musicVolume));
    await p.setDouble(_kSfxVol, _clamp01(s.sfxVolume));
    await p.setBool(_kMusicOn, s.musicEnabled);
    await p.setBool(_kSfxOn, s.sfxEnabled);
  }

  Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kMusicVol);
    await p.remove(_kSfxVol);
    await p.remove(_kMusicOn);
    await p.remove(_kSfxOn);
  }
}
