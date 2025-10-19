class Profile {
  final String id;
  final String? email;
  final String displayName;
  final bool isGuest;
  final DateTime createdAt;

  const Profile({
    required this.id,
    required this.displayName,
    required this.isGuest,
    required this.createdAt,
    this.email,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'displayName': displayName,
        'isGuest': isGuest,
        'createdAt': createdAt.toIso8601String(),
      };

  static Profile fromJson(Map<String, dynamic> m) => Profile(
        id: m['id'] as String,
        email: m['email'] as String?,
        displayName: m['displayName'] as String? ?? 'Player',
        isGuest: m['isGuest'] as bool? ?? true,
        createdAt: DateTime.tryParse(m['createdAt'] ?? '') ?? DateTime.now(),
      );
}
