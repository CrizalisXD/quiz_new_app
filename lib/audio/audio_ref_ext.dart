import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'audio_manager.dart';
import 'audio_keys.dart';

extension AudioRefX on WidgetRef {
	Future<void> playSfx(SfxKey key) => read(audioManagerProvider.notifier).playSfx(key);
	Future<void> playBgm(BgmKey key, {bool restart = false}) =>
			read(audioManagerProvider.notifier).playBgm(key, restart: restart);
	Future<void> stopBgm() => read(audioManagerProvider.notifier).stopBgm();
}
