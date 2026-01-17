enum BgmKey {
  home,
  japan,
  egypt,
  brazil,
  france,
  norway,
}

enum SfxKey {
  click,
  reward,
  finish,
}

class AudioAssets {
  static const Map<BgmKey, String> bgm = {
    BgmKey.home: 'sound/home.mp3',
    BgmKey.japan: 'sound/japan.mp3',
    BgmKey.egypt: 'sound/egypt.mp3',
    BgmKey.brazil: 'sound/brazil.mp3',
    // добавь при необходимости:
    // BgmKey.france: 'sound/france.mp3',
    // BgmKey.norway: 'sound/norway.mp3',
  };

  static const Map<SfxKey, String> sfx = {
    SfxKey.click: 'sound/click.mp3',
    SfxKey.reward: 'sound/rewards.mp3',
    SfxKey.finish: 'sound/finish.mp3',
  };
}

// Совместимость с текущим AudioManager (если он использует функции)
String bgmAsset(BgmKey key) => 'assets/${AudioAssets.bgm[key]!}';
String sfxAsset(SfxKey key) => 'assets/${AudioAssets.sfx[key]!}';
