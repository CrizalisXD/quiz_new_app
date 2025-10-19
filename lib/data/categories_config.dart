// Configuration of subcategories for each country.

class SubcategoryConfig {
  final String key; // internal id
  final String label; // UI label (fallback; UI may override with l10n)
  final String imageAsset; // asset path (may fallback to country image)
  const SubcategoryConfig({required this.key, required this.label, required this.imageAsset});
}

// Helper removed (replaced by _fullSet)

// Full set of subcategories mirroring Japan's structure, using country image as placeholder.
List<SubcategoryConfig> _fullSet(String countryKey) => [
      SubcategoryConfig(key: 'classic', label: 'Классический', imageAsset: 'assets/images/categories/$countryKey.png'),
      SubcategoryConfig(key: 'hard', label: 'Сложный', imageAsset: 'assets/images/categories/$countryKey.png'),
      SubcategoryConfig(key: 'food', label: 'Еда и напитки', imageAsset: 'assets/images/categories/$countryKey.png'),
      SubcategoryConfig(key: 'games', label: 'Игры и развлечения', imageAsset: 'assets/images/categories/$countryKey.png'),
      SubcategoryConfig(key: 'cinema', label: 'Кино и анимация', imageAsset: 'assets/images/categories/$countryKey.png'),
      SubcategoryConfig(key: 'architecture', label: 'Архитектура', imageAsset: 'assets/images/categories/$countryKey.png'),
      SubcategoryConfig(key: 'legends', label: 'Легенды и мифы', imageAsset: 'assets/images/categories/$countryKey.png'),
      SubcategoryConfig(key: 'history_persons', label: 'История в личностях', imageAsset: 'assets/images/categories/$countryKey.png'),
      SubcategoryConfig(key: 'transport', label: 'Транспорт и технологии', imageAsset: 'assets/images/categories/$countryKey.png'),
      SubcategoryConfig(key: 'unexpected', label: 'Неожиданное', imageAsset: 'assets/images/categories/$countryKey.png'),
    ];

// Explicit list for Japan using provided dedicated assets.
const _japan = <SubcategoryConfig>[
  SubcategoryConfig(key: 'classic', label: 'Классический', imageAsset: 'assets/images/ui/japan_cat/japan_classic.png'),
  SubcategoryConfig(key: 'hard', label: 'Сложный', imageAsset: 'assets/images/ui/japan_cat/japan_hard.png'),
  SubcategoryConfig(key: 'food', label: 'Еда и напитки', imageAsset: 'assets/images/ui/japan_cat/japan_food.png'),
  SubcategoryConfig(key: 'games', label: 'Игры и развлечения', imageAsset: 'assets/images/ui/japan_cat/japan_games.png'),
  SubcategoryConfig(key: 'cinema', label: 'Кино и анимация', imageAsset: 'assets/images/ui/japan_cat/japan_cinema.png'),
  SubcategoryConfig(key: 'architecture', label: 'Архитектура', imageAsset: 'assets/images/ui/japan_cat/japan_architecture.png'),
  SubcategoryConfig(key: 'legends', label: 'Легенды и мифы', imageAsset: 'assets/images/ui/japan_cat/japan_legends.png'),
  SubcategoryConfig(key: 'history_persons', label: 'История в личностях', imageAsset: 'assets/images/ui/japan_cat/japan_history_persons.png'),
  SubcategoryConfig(key: 'transport', label: 'Транспорт и технологии', imageAsset: 'assets/images/ui/japan_cat/japan_transport.png'),
  SubcategoryConfig(key: 'unexpected', label: 'Неожиданное', imageAsset: 'assets/images/ui/japan_cat/japan_unexpected.png'),
];

/// Map countryKey -> ordered subcategories. First always classic, second always Профессионал.
final Map<String, List<SubcategoryConfig>> countrySubcategories = {
  'japan': _japan,
  // Mirror Japan structure for these countries (using generic images for now).
  'egypt': _fullSet('egypt'),
  'france': _fullSet('france'),
  'brazil': _fullSet('brazil'),
  'norway': _fullSet('norway'),
};
