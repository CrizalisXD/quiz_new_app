import 'dart:io';

import 'package:flutter/material.dart';

class PlayerHudMeta {
  final String name;
  final int level;
  final String rankLabel;
  final String? avatarPath;  // локальный файл
  final String? avatarAsset; // ассет

  const PlayerHudMeta({
    required this.name,
    required this.level,
    required this.rankLabel,
    this.avatarPath,
    this.avatarAsset,
  });

  static const empty = PlayerHudMeta(
    name: 'guest',
    level: 1,
    rankLabel: 'Бронза I',
    avatarPath: null,
    avatarAsset: 'assets/ui/icons/ic_placeholder.png', // при необходимости поправь путь
  );
}

ImageProvider resolveAvatarProvider({
  String? avatarPath,
  String? avatarAsset,
  String placeholderAsset = 'assets/ui/icons/ic_placeholder.png',
}) {
  if (avatarPath != null && avatarPath.isNotEmpty) {
    final f = File(avatarPath);
    if (f.existsSync()) return FileImage(f);
  }
  if (avatarAsset != null && avatarAsset.isNotEmpty) {
    return AssetImage(avatarAsset);
  }
  return AssetImage(placeholderAsset);
}
