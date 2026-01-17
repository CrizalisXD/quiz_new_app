class AudioSettings {
  final double musicVolume; // 0..1
  final double sfxVolume; // 0..1
  final bool musicEnabled;
  final bool sfxEnabled;

  const AudioSettings({
    required this.musicVolume,
    required this.sfxVolume,
    required this.musicEnabled,
    required this.sfxEnabled,
  });

  AudioSettings copyWith({
    double? musicVolume,
    double? sfxVolume,
    bool? musicEnabled,
    bool? sfxEnabled,
  }) {
    return AudioSettings(
      musicVolume: (musicVolume ?? this.musicVolume).clamp(0.0, 1.0),
      sfxVolume: (sfxVolume ?? this.sfxVolume).clamp(0.0, 1.0),
      musicEnabled: musicEnabled ?? this.musicEnabled,
      sfxEnabled: sfxEnabled ?? this.sfxEnabled,
    );
  }

  static const defaults = AudioSettings(
    musicVolume: 0.7,
    sfxVolume: 0.9,
    musicEnabled: true,
    sfxEnabled: true,
  );
}
