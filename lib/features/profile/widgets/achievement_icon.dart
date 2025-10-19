import 'package:flutter/material.dart';

class AchievementIcon extends StatelessWidget {
  final bool unlocked;
  final String title;
  final String description;
  const AchievementIcon({super.key, required this.unlocked, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    final color = unlocked ? Colors.amber : Colors.grey;
    return GestureDetector(
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
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: unlocked ? Colors.amber.withOpacity(0.15) : Colors.black12,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(Icons.emoji_events, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 10, color: unlocked ? Colors.black87 : Colors.black45),
          ),
        ],
      ),
    );
  }
}
