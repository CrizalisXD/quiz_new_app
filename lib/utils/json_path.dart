/// Унифицированный резолвер пути к JSON с вопросами.
/// Пример: jsonPath(locale:'ru', country:'japan', pack:'classic', total:100)
/// -> assets/questions/ru/japan/japan_classic_100.json
String jsonPath({
  required String locale,   // 'ru' | 'en'
  required String country,  // 'japan'
  required String pack,     // 'classic'
  required int total,       // 50 | 100
}) {
  final c = country.toLowerCase();
  final p = pack.toLowerCase();
  final t = total; // как есть (50, 100)
  return 'assets/questions/$locale/$c/${c}_${p}_$t.json';
}
