import 'dart:convert';

class LocalProfile {
  final String id;
  final String name;
  final String avatarPath; // локальный путь к файлу (или пустая строка)
  final int totalStars;

  const LocalProfile({
    required this.id,
    required this.name,
    required this.avatarPath,
    required this.totalStars,
  });

  LocalProfile copyWith({
    String? id,
    String? name,
    String? avatarPath,
    int? totalStars,
  }) {
    return LocalProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarPath: avatarPath ?? this.avatarPath,
      totalStars: totalStars ?? this.totalStars,
    );
  }

  factory LocalProfile.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? '').toString();
    final name = (json['name'] ?? '').toString();
    final avatarPath = (json['avatarPath'] ?? '').toString();
    final totalStarsRaw = json['totalStars'];
    final totalStars = (totalStarsRaw is int)
        ? totalStarsRaw
        : int.tryParse((totalStarsRaw ?? '0').toString()) ?? 0;

    return LocalProfile(
      id: id,
      name: name,
      avatarPath: avatarPath,
      totalStars: totalStars,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'avatarPath': avatarPath,
        'totalStars': totalStars,
      };

  // Опционально (удобно для отладки/логов)
  @override
  String toString() => jsonEncode(toJson());
}
