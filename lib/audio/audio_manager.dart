import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'audio_keys.dart';
import 'audio_settings.dart';
import 'audio_store.dart';

final audioStoreProvider = Provider<AudioStore>((ref) => const AudioStore());

final audioManagerProvider =
    AsyncNotifierProvider<AudioManager, AudioSettings>(AudioManager.new);

class AudioManager extends AsyncNotifier<AudioSettings> {
  final AudioPlayer _bgm = AudioPlayer(playerId: 'bgm');
  final AudioPlayer _sfx = AudioPlayer(playerId: 'sfx');

  BgmKey? _currentBgm;

  @override
  Future<AudioSettings> build() async {
    final store = ref.read(audioStoreProvider);
    final s = await store.load();

    await _applyToPlayers(s);

    ref.onDispose(() {
      _bgm.dispose();
      _sfx.dispose();
    });

    return s;
  }

  Future<void> _applyToPlayers(AudioSettings s) async {
    final music = s.musicEnabled ? s.musicVolume : 0.0;
    final sfx = s.sfxEnabled ? s.sfxVolume : 0.0;
    await _bgm.setVolume(music);
    await _sfx.setVolume(sfx);
  }

  Future<void> _persist(AudioSettings s) async {
    await ref.read(audioStoreProvider).save(s);
  }

  double _clamp01(double v) => v.clamp(0.0, 1.0);

  Future<void> _set(AudioSettings next, {required bool persist}) async {
    state = AsyncData(next);
    await _applyToPlayers(next);
    if (persist) await _persist(next);
  }

  // -------- Settings API (preview vs commit) --------
  Future<void> previewMusicVolume(double v) async {
    final cur = state.value ?? AudioSettings.defaults;
    final next = cur.copyWith(musicVolume: _clamp01(v));
    await _set(next, persist: false);
  }

  Future<void> commitMusicVolume(double v) async {
    final cur = state.value ?? AudioSettings.defaults;
    final next = cur.copyWith(musicVolume: _clamp01(v));
    await _set(next, persist: true);
  }

  Future<void> previewSfxVolume(double v) async {
    final cur = state.value ?? AudioSettings.defaults;
    final next = cur.copyWith(sfxVolume: _clamp01(v));
    await _set(next, persist: false);
  }

  Future<void> commitSfxVolume(double v) async {
    final cur = state.value ?? AudioSettings.defaults;
    final next = cur.copyWith(sfxVolume: _clamp01(v));
    await _set(next, persist: true);
  }

  // Back-compat: старые методы = commit
  Future<void> setMusicVolume(double v) => commitMusicVolume(v);
  Future<void> setSfxVolume(double v) => commitSfxVolume(v);

  Future<void> setMusicEnabled(bool on) async {
    final cur = state.value ?? AudioSettings.defaults;
    final next = cur.copyWith(musicEnabled: on);
    await _set(next, persist: true);

    if (!on) await _bgm.stop();
    if (on && _currentBgm != null) {
      await playBgm(_currentBgm!, restart: true);
    }
  }

  Future<void> setSfxEnabled(bool on) async {
    final cur = state.value ?? AudioSettings.defaults;
    final next = cur.copyWith(sfxEnabled: on);
    await _set(next, persist: true);
  }

  // -------- Play API --------
  Future<void> playBgm(BgmKey key, {bool restart = false}) async {
    final s = state.value ?? AudioSettings.defaults;
    if (!s.musicEnabled) {
      _currentBgm = key;
      return;
    }

    if (!restart && _currentBgm == key) return;

    final asset = AudioAssets.bgm[key];
    if (asset == null) return;

    _currentBgm = key;
    await _bgm.setReleaseMode(ReleaseMode.loop);
    await _bgm.play(AssetSource(asset));
  }

  Future<void> stopBgm() async {
    _currentBgm = null;
    await _bgm.stop();
  }

  Future<void> playSfx(SfxKey key) async {
    final s = state.value ?? AudioSettings.defaults;
    if (!s.sfxEnabled) return;

    final asset = AudioAssets.sfx[key];
    if (asset == null) return;

    // CHANGED: не даём наслаиваться нескольким SFX “параллельно” на одном плеере
    await _sfx.stop();
    await _sfx.play(AssetSource(asset));
  }
}
