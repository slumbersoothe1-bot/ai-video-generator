/// A district in the Smart Creator City.
class CityDistrict {
  const CityDistrict({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.accent,
    required this.achievementName,
    required this.achievementDescription,
  });

  final String id;
  final String name;
  final String description;
  final String icon;
  final List<int> gradient;
  final int accent;
  final String achievementName;
  final String achievementDescription;
}

/// All districts in the Smart Creator City.
const List<CityDistrict> kCityDistricts = [
  CityDistrict(
    id: 'viral_studio',
    name: 'The Viral Studio',
    description: 'Generate scroll-stopping hooks and viral scripts',
    icon: 'local_fire_department',
    gradient: [0xFFFF6B35, 0xFFFF8E53],
    accent: 0xFFFF6B35,
    achievementName: 'Viral Architect',
    achievementDescription: 'Generated 10 viral hooks',
  ),
  CityDistrict(
    id: 'ecommerce_hub',
    name: 'The E-Commerce Hub',
    description: 'Drop product images, get UGC-style video ads',
    icon: 'shopping_bag',
    gradient: [0xFF00D9A3, 0xFF00B884],
    accent: 0xFF00D9A3,
    achievementName: 'Commerce Catalyst',
    achievementDescription: 'Created 5 product video ads',
  ),
  CityDistrict(
    id: 'trend_tower',
    name: 'The Trend Tower',
    description: 'Ride the latest trends with trending-audio templates',
    icon: 'trending_up',
    gradient: [0xFF5B8DEF, 0xFF3B6FD4],
    accent: 0xFF5B8DEF,
    achievementName: 'Trendsetter',
    achievementDescription: 'Used 10 trending templates',
  ),
  CityDistrict(
    id: 'polyglot_plaza',
    name: 'The Polyglot Plaza',
    description: 'Multi-lingual scripts in 12+ languages',
    icon: 'language',
    gradient: [0xFFB47CE3, 0xFF9B59B6],
    accent: 0xFFB47CE3,
    achievementName: 'Global Voice',
    achievementDescription: 'Generated scripts in 5 languages',
  ),
  CityDistrict(
    id: 'creator_lab',
    name: 'The Creator Lab',
    description: 'AI-powered video generation from text prompts',
    icon: 'auto_awesome',
    gradient: [0xFF00D4FF, 0xFF0099CC],
    accent: 0xFF00D4FF,
    achievementName: 'Master Creator',
    achievementDescription: 'Generated 20 AI videos',
  ),
  CityDistrict(
    id: 'growth_garden',
    name: 'The Growth Garden',
    description: 'Refer friends, earn credits, grow your empire',
    icon: 'card_giftcard',
    gradient: [0xFF66BB6A, 0xFF43A047],
    accent: 0xFF66BB6A,
    achievementName: 'Growth Champion',
    achievementDescription: 'Referred 10 friends',
  ),
];

/// A local achievement the user can unlock.
class Achievement {
  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.requiredCount,
    this.unlocked = false,
    this.progress = 0,
  });

  final String id;
  final String name;
  final String description;
  final String icon;
  final int requiredCount;
  final bool unlocked;
  final int progress;

  Achievement copyWith({bool? unlocked, int? progress}) {
    return Achievement(
      id: id,
      name: name,
      description: description,
      icon: icon,
      requiredCount: requiredCount,
      unlocked: unlocked ?? this.unlocked,
      progress: progress ?? this.progress,
    );
  }
}

/// Default achievements tied to city districts.
const List<Achievement> kDefaultAchievements = kCityDistricts
    .map((d) => Achievement(
          id: d.id,
          name: d.achievementName,
          description: d.achievementDescription,
          icon: d.icon,
          requiredCount: d.id == 'creator_lab' ? 20 : 10,
        ))
    .toList();
