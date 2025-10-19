import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/profile/profile_providers.dart';
import '../auth/current_user.dart';
import '../progress/progress_store.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});
  @override
  ConsumerState<EditProfileScreen> createState() => _S();
}

class _S extends ConsumerState<EditProfileScreen> {
  final _name = TextEditingController();
  String? _avatarPath; // может быть asset или file path
  bool _japanUnlocked = false; // доступность специального аватара

  static const _avatarClassicMan = 'assets/images/profile/avatar/avatar_classic_man.png';
  static const _avatarClassicGirl = 'assets/images/profile/avatar/avatar_classic_girl.png';
  static const _avatarJapan = 'assets/images/profile/avatar/avatar_japan.png';

  @override
  void initState() {
    super.initState();
    final p = ref.read(profileProvider).valueOrNull;
    _name.text = p?.name ?? '';
    _avatarPath = p?.avatarPath;
    // Разрешаем только встроенные ассеты. Если ранее был установлен файл из галереи — игнорируем превью.
    if (_avatarPath != null && !_avatarPath!.startsWith('assets/')) {
      _avatarPath = null;
    }
    // Проверим доступность японского аватара: если есть прогресс в japan_classic
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userId = ref.read(currentUserProvider);
      try {
        final (stars, unlocked) = await ProgressStore.getLevelsProgress(userId, 'japan_classic', 10);
        // Японский аватар открывается ТОЛЬКО после прохождения всех 10 уровней (>=1 звезды на каждом)
        final allPassed = stars.every((s) => s > 0);
        if (mounted) {
          setState(() {
            _japanUnlocked = allPassed;
            // Если ранее был установлен японский аватар, но он не открыт — снимаем выбор
            if (!allPassed && _avatarPath == _avatarJapan) {
              _avatarPath = null;
            }
          });
        }
      } catch (_) {
        // Если не удалось прочитать — считаем закрытым
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Редактировать профиль')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 56,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: _avatarPath == null
                    ? null
                    : AssetImage(_avatarPath!),
                child: _avatarPath == null
                    ? Icon(Icons.person_outline, color: Colors.grey.shade700, size: 36)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Text('Встроенные аватары', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              'Собственные изображения отключены. Дополнительные аватары появятся в магазине позже.',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _BuiltInAvatarTile(
                  assetPath: _avatarClassicMan,
                  selected: _avatarPath == _avatarClassicMan,
                  onTap: () => setState(() => _avatarPath = _avatarClassicMan),
                ),
                const SizedBox(width: 12),
                _BuiltInAvatarTile(
                  assetPath: _avatarClassicGirl,
                  selected: _avatarPath == _avatarClassicGirl,
                  onTap: () => setState(() => _avatarPath = _avatarClassicGirl),
                ),
                const SizedBox(width: 12),
                _BuiltInAvatarTile(
                  assetPath: _avatarJapan,
                  selected: _avatarPath == _avatarJapan,
                  locked: !_japanUnlocked,
                  onTap: () {
                    if (_japanUnlocked) {
                      setState(() => _avatarPath = _avatarJapan);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Откройте в Японии: классика')), // краткая подсказка
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _name,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Никнейм',
                border: OutlineInputBorder(),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.save_outlined),
                label: const Text('Сохранить'),
                onPressed: () async {
                  final notifier = ref.read(profileProvider.notifier);
                  final newName = _name.text.trim();
                  if (newName.isNotEmpty) {
                    await notifier.rename(newName);
                  }
                  // Блокируем сохранение японского аватара, если он не открыт
                  if (_avatarPath == _avatarJapan && !_japanUnlocked) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Откройте в Японии: классика')),
                    );
                    return;
                  }

                  if (_avatarPath != null) {
                    await notifier.changeAvatar(_avatarPath!);
                  }
                  if (mounted) Navigator.pop(context);
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _BuiltInAvatarTile extends StatelessWidget {
  final String assetPath;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;
  const _BuiltInAvatarTile({
    required this.assetPath,
    required this.selected,
    this.locked = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: locked ? null : onTap,
      child: Stack(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: selected ? Colors.deepPurple : Colors.transparent, width: 2),
            ),
            child: CircleAvatar(
              backgroundImage: AssetImage(assetPath),
              backgroundColor: Colors.grey.shade200,
            ),
          ),
          if (locked)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.45),
                ),
                child: const Center(child: Icon(Icons.lock, color: Colors.white)),
              ),
            ),
        ],
      ),
    );
  }
}
