import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Сервис для управления фоновой музыкой
class AudioService extends StateNotifier<AudioState> {
  AudioService() : super(const AudioState());
  
  static const MethodChannel _channel = MethodChannel('quiz_app/audio');
  
  /// Включить музыку для страны
  Future<void> playCountryMusic(String countryKey) async {
    try {
      // Останавливаем предыдущую музыку
      await stopMusic();
      
      if (countryKey == 'japan') {
        // Включаем музыку Японии
        await _channel.invokeMethod('playMusic', {
          'assetPath': 'assets/sound/japan.mp3',
          'loop': true,
        });
        state = state.copyWith(
          isPlaying: true,
          currentCountry: 'japan',
          volume: 0.7, // Умеренная громкость
        );
      }
    } catch (e) {
      debugPrint('AudioService: Ошибка воспроизведения музыки: $e');
    }
  }
  
  /// Остановить музыку
  Future<void> stopMusic() async {
    try {
      await _channel.invokeMethod('stopMusic');
      state = const AudioState();
    } catch (e) {
      debugPrint('AudioService: Ошибка остановки музыки: $e');
    }
  }
  
  /// Установить громкость
  Future<void> setVolume(double volume) async {
    try {
      await _channel.invokeMethod('setVolume', {'volume': volume});
      state = state.copyWith(volume: volume);
    } catch (e) {
      debugPrint('AudioService: Ошибка установки громкости: $e');
    }
  }
  
  /// Пауза/возобновление
  Future<void> togglePause() async {
    try {
      if (state.isPlaying) {
        await _channel.invokeMethod('pauseMusic');
        state = state.copyWith(isPaused: true);
      } else {
        await _channel.invokeMethod('resumeMusic');
        state = state.copyWith(isPaused: false);
      }
    } catch (e) {
      debugPrint('AudioService: Ошибка паузы/возобновления: $e');
    }
  }
}

/// Состояние аудио сервиса
class AudioState {
  final bool isPlaying;
  final bool isPaused;
  final String? currentCountry;
  final double volume;
  
  const AudioState({
    this.isPlaying = false,
    this.isPaused = false,
    this.currentCountry,
    this.volume = 0.7,
  });
  
  AudioState copyWith({
    bool? isPlaying,
    bool? isPaused,
    String? currentCountry,
    double? volume,
  }) {
    return AudioState(
      isPlaying: isPlaying ?? this.isPlaying,
      isPaused: isPaused ?? this.isPaused,
      currentCountry: currentCountry ?? this.currentCountry,
      volume: volume ?? this.volume,
    );
  }
  
  bool get isCurrentlyJapan => currentCountry == 'japan';
}

/// Провайдер для аудио сервиса
final audioServiceProvider = StateNotifierProvider<AudioService, AudioState>(
  (ref) => AudioService(),
);

/// Хелпер для работы с аудио
class AudioHelper {
  static AudioService get(WidgetRef ref) => ref.read(audioServiceProvider.notifier);
  static AudioState getState(WidgetRef ref) => ref.read(audioServiceProvider);
  
  /// Включить музыку для страны
  static Future<void> playForCountry(WidgetRef ref, String countryKey) async {
    final audioService = get(ref);
    await audioService.playCountryMusic(countryKey);
  }
  
  /// Остановить музыку
  static Future<void> stopMusic(WidgetRef ref) async {
    final audioService = get(ref);
    await audioService.stopMusic();
  }
  
  /// Проверить, играет ли музыка для страны
  static bool isPlayingForCountry(WidgetRef ref, String countryKey) {
    final state = getState(ref);
    return state.isPlaying && state.currentCountry == countryKey;
  }
}