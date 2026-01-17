// Configuration of subcategories for each country.

class SubcategoryConfig {
  final String key; // internal id
  final String label; // UI label (optional fallback)
  final String imageAsset; // asset path

  const SubcategoryConfig({
    required this.key,
    required this.imageAsset,
    this.label = '', // CHANGED: можно не указывать label
  });
}

// REMOVE: генератор _fullSet больше не нужен

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

const _egypt = <SubcategoryConfig>[
  SubcategoryConfig(key: 'classic', imageAsset: 'assets/images/ui/egypt_cat/egypt_classic.png'),
  SubcategoryConfig(key: 'hard', imageAsset: 'assets/images/ui/egypt_cat/egypt_hard.png'),
  SubcategoryConfig(key: 'food', imageAsset: 'assets/images/ui/egypt_cat/egypt_food.png'),
  SubcategoryConfig(key: 'games', imageAsset: 'assets/images/ui/egypt_cat/egypt_games.png'),
  SubcategoryConfig(key: 'cinema', imageAsset: 'assets/images/ui/egypt_cat/egypt_cinema.png'),
  SubcategoryConfig(key: 'architecture', imageAsset: 'assets/images/ui/egypt_cat/egypt_architecture.png'),
  SubcategoryConfig(key: 'legends', imageAsset: 'assets/images/ui/egypt_cat/egypt_legends.png'),
  SubcategoryConfig(key: 'history_persons', imageAsset: 'assets/images/ui/egypt_cat/egypt_history_persons.png'),
  SubcategoryConfig(key: 'transport', imageAsset: 'assets/images/ui/egypt_cat/egypt_transport.png'),
  SubcategoryConfig(key: 'unexpected', imageAsset: 'assets/images/ui/egypt_cat/egypt_unexpected.png'),
];

const _france = <SubcategoryConfig>[
  SubcategoryConfig(key: 'classic', imageAsset: 'assets/images/ui/france_cat/france_classic.png'),
  SubcategoryConfig(key: 'hard', imageAsset: 'assets/images/ui/france_cat/france_hard.png'),
  SubcategoryConfig(key: 'food', imageAsset: 'assets/images/ui/france_cat/france_food.png'),
  SubcategoryConfig(key: 'games', imageAsset: 'assets/images/ui/france_cat/france_games.png'),
  SubcategoryConfig(key: 'cinema', imageAsset: 'assets/images/ui/france_cat/france_cinema.png'),
  SubcategoryConfig(key: 'architecture', imageAsset: 'assets/images/ui/france_cat/france_architecture.png'),
  SubcategoryConfig(key: 'legends', imageAsset: 'assets/images/ui/france_cat/france_legends.png'),
  SubcategoryConfig(key: 'history_persons', imageAsset: 'assets/images/ui/france_cat/france_history_persons.png'),
  SubcategoryConfig(key: 'transport', imageAsset: 'assets/images/ui/france_cat/france_transport.png'),
  SubcategoryConfig(key: 'unexpected', imageAsset: 'assets/images/ui/france_cat/france_unexpected.png'),
];

const _brazil = <SubcategoryConfig>[
  SubcategoryConfig(key: 'classic', imageAsset: 'assets/images/ui/brazil_cat/brazil_classic.png'),
  SubcategoryConfig(key: 'hard', imageAsset: 'assets/images/ui/brazil_cat/brazil_hard.png'),
  SubcategoryConfig(key: 'food', imageAsset: 'assets/images/ui/brazil_cat/brazil_food.png'),
  SubcategoryConfig(key: 'games', imageAsset: 'assets/images/ui/brazil_cat/brazil_games.png'),
  SubcategoryConfig(key: 'cinema', imageAsset: 'assets/images/ui/brazil_cat/brazil_cinema.png'),
  SubcategoryConfig(key: 'architecture', imageAsset: 'assets/images/ui/brazil_cat/brazil_architecture.png'),
  SubcategoryConfig(key: 'legends', imageAsset: 'assets/images/ui/brazil_cat/brazil_legends.png'),
  SubcategoryConfig(key: 'history_persons', imageAsset: 'assets/images/ui/brazil_cat/brazil_history_persons.png'),
  SubcategoryConfig(key: 'transport', imageAsset: 'assets/images/ui/brazil_cat/brazil_transport.png'),
  SubcategoryConfig(key: 'unexpected', imageAsset: 'assets/images/ui/brazil_cat/brazil_unexpected.png'),
];

const _norway = <SubcategoryConfig>[
  SubcategoryConfig(key: 'classic', imageAsset: 'assets/images/ui/norway_cat/norway_classic.png'),
  SubcategoryConfig(key: 'hard', imageAsset: 'assets/images/ui/norway_cat/norway_hard.png'),
  SubcategoryConfig(key: 'food', imageAsset: 'assets/images/ui/norway_cat/norway_food.png'),
  SubcategoryConfig(key: 'games', imageAsset: 'assets/images/ui/norway_cat/norway_games.png'),
  SubcategoryConfig(key: 'cinema', imageAsset: 'assets/images/ui/norway_cat/norway_cinema.png'),
  SubcategoryConfig(key: 'architecture', imageAsset: 'assets/images/ui/norway_cat/norway_architecture.png'),
  SubcategoryConfig(key: 'legends', imageAsset: 'assets/images/ui/norway_cat/norway_legends.png'),
  SubcategoryConfig(key: 'history_persons', imageAsset: 'assets/images/ui/norway_cat/norway_history_persons.png'),
  SubcategoryConfig(key: 'transport', imageAsset: 'assets/images/ui/norway_cat/norway_transport.png'),
  SubcategoryConfig(key: 'unexpected', imageAsset: 'assets/images/ui/norway_cat/norway_unexpected.png'),
];

final Map<String, List<SubcategoryConfig>> countrySubcategories = {
  'japan': _japan,
  'egypt': _egypt,
  'france': _france,
  'brazil': _brazil,
  'norway': _norway,
};
