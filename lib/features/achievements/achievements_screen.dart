import 'package:flutter/material.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});
  static const route = '/achievements';

  @override
  Widget build(BuildContext context) {
    // На данном этапе показываем 12 карточек-достижений (заглушки)
    return Scaffold(
      appBar: AppBar(title: const Text('Достижения')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.8,
        ),
        itemCount: 12,
        itemBuilder: (_, i) {
          final unlocked = i < 3; // первые 3 как пример
          return _AchievementTile(
            title: _title(i),
            description: _desc(i),
            unlocked: unlocked,
          );
        },
      ),
    );
  }

  static String _title(int i) => 'Бейдж #${i + 1}';
  static String _desc(int i) => 'Описание достижения номер ${i + 1}';
}

class _AchievementTile extends StatelessWidget {
  final String title;
  final String description;
  final bool unlocked;
  const _AchievementTile({required this.title, required this.description, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Material(
        color: unlocked ? Colors.amber.withOpacity(0.15) : Colors.black12,
        child: InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text(title),
                content: Text(description),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
                ],
              ),
            );
          },
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.emoji_events, color: unlocked ? Colors.amber : Colors.grey, size: 32),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: unlocked ? Colors.black87 : Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
