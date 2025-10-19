// lib/utils/background_paths.dart
String _key(String s) =>
    s.trim().toLowerCase().replaceAll(' ', '_'); // "Japan" -> "japan"

String homeBackground() => 'assets/images/backgrounds/home/home.png';

String categoryBackground(String country) =>
    'assets/images/backgrounds/category/category_${_key(country)}.png';

String levelBackground(String country) =>
    'assets/images/backgrounds/level/level_${_key(country)}.png';

String quizBackground(String country) =>
    'assets/images/backgrounds/quiz/quiz_${_key(country)}.png';
