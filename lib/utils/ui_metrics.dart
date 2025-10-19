import 'package:flutter/material.dart';

/// Единый верхний отступ контента для экранов с `extendBodyBehindAppBar: true`.
/// Позволяет начинать список/контент сразу после AppBar без лишних 8dp.
double contentTopPadding(BuildContext context) {
  // Можно подстроить глобально в одном месте при необходимости.
  return MediaQuery.of(context).padding.top + kToolbarHeight - 4; // чуть плотнее визуально
}
