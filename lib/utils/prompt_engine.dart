import 'dart:math';

/// Predictive prompt engine — the "mind-reading" layer of the Smart Village
/// experience. Suggests prompts based on time of day, trending themes, and
/// the user's selected style, so creation feels telepathic.
class PromptEngine {
  PromptEngine._();

  /// Returns a curated list of prompt suggestions tailored to the current
  /// time of day and the selected visual style.
  static List<PromptSuggestion> suggestions({String? style}) {
    final hour = DateTime.now().hour;
    final timeOfDay = _timeOfDay(hour);

    final base = _timeBasedPrompts(timeOfDay);
    final styled = style != null ? _stylePrompts(style) : <PromptSuggestion>[];

    // Interleave: time-based first, then style-specific, then general.
    final all = <PromptSuggestion>[];
    all.addAll(base.take(3));
    all.addAll(styled.take(2));
    all.addAll(_generalPrompts.take(2));

    // Deduplicate by text.
    final seen = <String>{};
    return all.where((p) {
      if (seen.contains(p.text)) return false;
      seen.add(p.text);
      return true;
    }).toList();
  }

  static _TimeOfDay _timeOfDay(int hour) {
    if (hour >= 5 && hour < 12) return _TimeOfDay.morning;
    if (hour >= 12 && hour < 17) return _TimeOfDay.afternoon;
    if (hour >= 17 && hour < 21) return _TimeOfDay.evening;
    return _TimeOfDay.night;
  }

  static List<PromptSuggestion> _timeBasedPrompts(_TimeOfDay tod) {
    switch (tod) {
      case _TimeOfDay.morning:
        return const [
          PromptSuggestion(
            text: 'Golden sunrise over a misty mountain valley, birds soaring through dawn light',
            label: 'Morning glow',
            icon: 'wb_sunny',
          ),
          PromptSuggestion(
            text: 'A cozy cafe interior with steam rising from a fresh latte, soft morning light through windows',
            label: 'Cafe morning',
            icon: 'local_cafe',
          ),
          PromptSuggestion(
            text: 'Dewdrops glistening on a spider web in a lush green meadow at sunrise',
            label: 'Nature detail',
            icon: 'eco',
          ),
        ];
      case _TimeOfDay.afternoon:
        return const [
          PromptSuggestion(
            text: 'A futuristic cityscape with flying vehicles zooming between glass towers under a bright blue sky',
            label: 'Future city',
            icon: 'location_city',
          ),
          PromptSuggestion(
            text: 'Ocean waves crashing against dramatic cliffs, spray catching sunlight in slow motion',
            label: 'Ocean power',
            icon: 'waves',
          ),
          PromptSuggestion(
            text: 'A chef plating a gourmet dish with precision, steam and garnish in a modern kitchen',
            label: 'Culinary art',
            icon: 'restaurant',
          ),
        ];
      case _TimeOfDay.evening:
        return const [
          PromptSuggestion(
            text: 'Neon-lit Tokyo street at night, rain reflections on pavement, crowds under glowing signs',
            label: 'Neon night',
            icon: 'nights_stay',
          ),
          PromptSuggestion(
            text: 'A bonfire on a beach at sunset, flames dancing against an orange and purple sky',
            label: 'Beach fire',
            icon: 'local_fire_department',
          ),
          PromptSuggestion(
            text: 'A luxury sports car driving through a tunnel with streaking light trails',
            label: 'Night drive',
            icon: 'directions_car',
          ),
        ];
      case _TimeOfDay.night:
        return const [
          PromptSuggestion(
            text: 'A galaxy swirling above a desert canyon, stars reflecting in a still pool of water',
            label: 'Cosmic dreams',
            icon: 'auto_awesome',
          ),
          PromptSuggestion(
            text: 'A bioluminescent forest at midnight, glowing mushrooms and floating fireflies',
            label: 'Glowing forest',
            icon: 'forest',
          ),
          PromptSuggestion(
            text: 'Northern lights dancing over a snow-covered cabin, aurora reflecting on ice',
            label: 'Aurora night',
            icon: 'ac_unit',
          ),
        ];
    }
  }

  static List<PromptSuggestion> _stylePrompts(String style) {
    switch (style.toLowerCase()) {
      case 'cinematic':
        return const [
          PromptSuggestion(
            text: 'A lone warrior standing on a cliff edge, epic cinematic lighting, wind blowing their cape',
            label: 'Epic hero',
            icon: 'movie',
          ),
          PromptSuggestion(
            text: 'A spaceship descending through clouds toward an alien planet, dramatic scale and atmosphere',
            label: 'Sci-fi arrival',
            icon: 'rocket_launch',
          ),
        ];
      case '3d animation':
        return const [
          PromptSuggestion(
            text: 'A cute robot character exploring a colorful toy factory, playful and vibrant',
            label: 'Robot adventure',
            icon: 'smart_toy',
          ),
          PromptSuggestion(
            text: 'A magical floating island with waterfalls cascading into the clouds, Pixar-style',
            label: 'Floating island',
            icon: 'terrain',
          ),
        ];
      case 'anime':
        return const [
          PromptSuggestion(
            text: 'A young hero with flowing hair standing on a rooftop at sunset, cherry blossoms flying',
            label: 'Anime hero',
            icon: 'person',
          ),
          PromptSuggestion(
            text: 'A magical girl transforming with sparkling energy and ribbon effects, vibrant anime style',
            label: 'Magical girl',
            icon: 'auto_fix_high',
          ),
        ];
      case 'realistic':
        return const [
          PromptSuggestion(
            text: 'A close-up of a hummingbird hovering near a red flower, wings blurred in motion, photorealistic',
            label: 'Nature close-up',
            icon: 'flutter_dash',
          ),
          PromptSuggestion(
            text: 'A barista pouring latte art in slow motion, creamy texture and warm lighting, hyperreal',
            label: 'Latte art',
            icon: 'coffee',
          ),
        ];
      case 'cyberpunk':
        return const [
          PromptSuggestion(
            text: 'A cyberpunk hacker in a neon-lit alley, holographic screens floating around them, rain falling',
            label: 'Neon hacker',
            icon: 'code',
          ),
          PromptSuggestion(
            text: 'A megacorporation tower with giant holographic advertisements, flying cars passing by',
            label: 'Mega tower',
            icon: 'apartment',
          ),
        ];
      case 'watercolor':
        return const [
          PromptSuggestion(
            text: 'A watercolor painting of a Venetian canal at dawn, soft washes and gentle reflections',
            label: 'Venice dawn',
            icon: 'water',
          ),
          PromptSuggestion(
            text: 'A watercolor portrait of a fox in an autumn forest, warm earthy tones and loose brushwork',
            label: 'Forest fox',
            icon: 'pets',
          ),
        ];
      default:
        return const [];
    }
  }

  static const _generalPrompts = [
    PromptSuggestion(
      text: 'A time-lapse of a flower blooming from seed to full blossom on a windowsill',
      label: 'Blooming flower',
      icon: 'local_florist',
    ),
    PromptSuggestion(
      text: 'An astronaut floating inside a space station, Earth visible through the window',
      label: 'Space drift',
      icon: 'public',
    ),
    PromptSuggestion(
      text: 'A waterfall in a hidden tropical jungle, mist and rainbow in the spray',
      label: 'Hidden waterfall',
      icon: 'waterfall_chart',
    ),
  ];

  /// Returns a random "surprise me" prompt from the full catalog.
  static PromptSuggestion surprise({String? style}) {
    final all = suggestions(style: style);
    final rng = Random();
    return all[rng.nextInt(all.length)];
  }
}

enum _TimeOfDay { morning, afternoon, evening, night }

class PromptSuggestion {
  const PromptSuggestion({
    required this.text,
    required this.label,
    required this.icon,
  });

  final String text;
  final String label;
  final String icon;
}
