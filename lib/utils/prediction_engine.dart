import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'viral_hook_engine.dart';

/// A user's creation history entry for the mind-reading engine.
class CreationHistoryEntry {
  const CreationHistoryEntry({
    required this.prompt,
    required this.style,
    required this.niche,
    required this.timestamp,
  });

  final String prompt;
  final String style;
  final String niche;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
        'prompt': prompt,
        'style': style,
        'niche': niche,
        'timestamp': timestamp.toIso8601String(),
      };

  factory CreationHistoryEntry.fromJson(Map<String, dynamic> json) {
    return CreationHistoryEntry(
      prompt: json['prompt']?.toString() ?? '',
      style: json['style']?.toString() ?? '',
      niche: json['niche']?.toString() ?? '',
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

/// A prediction result from the mind-reading engine.
class IntentPrediction {
  const IntentPrediction({
    required this.prompt,
    required this.style,
    required this.niche,
    required this.confidence,
    required this.reason,
  });

  final String prompt;
  final String style;
  final String niche;
  final double confidence;
  final String reason;
}

/// The Mind-Reading Customer Intent Prediction Engine.
///
/// Analyzes the user's past selections, niche history, and creation patterns
/// to preemptively suggest ready-to-use scripts, templates, and hooks.
class PredictionEngine extends ChangeNotifier {
  PredictionEngine._();
  static final PredictionEngine instance = PredictionEngine._();

  static const _historyKey = 'creation_history';
  static const _maxHistory = 50;

  List<CreationHistoryEntry> _history = [];
  bool _loaded = false;

  List<CreationHistoryEntry> get history => List.unmodifiable(_history);
  bool get isLoaded => _loaded;

  /// Loads persisted history from local storage.
  Future<void> load() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_historyKey);
      if (json != null) {
        final list = jsonDecode(json) as List;
        _history = list
            .map((e) =>
                CreationHistoryEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      _history = [];
    }
    _loaded = true;
    notifyListeners();
  }

  /// Records a new creation in the history.
  Future<void> record({
    required String prompt,
    required String style,
    String? niche,
  }) async {
    final entry = CreationHistoryEntry(
      prompt: prompt,
      style: style,
      niche: niche ?? _inferNiche(prompt),
      timestamp: DateTime.now(),
    );
    _history.insert(0, entry);
    if (_history.length > _maxHistory) {
      _history = _history.sublist(0, _maxHistory);
    }
    notifyListeners();
    await _persist();
  }

  /// Generates predictions based on the user's history.
  List<IntentPrediction> predict({String? currentStyle}) {
    if (_history.isEmpty) return _coldStartPredictions(currentStyle);

    final nicheCounts = <String, int>{};
    final styleCounts = <String, int>{};
    final promptKeywords = <String, int>{};

    for (final entry in _history) {
      nicheCounts[entry.niche] = (nicheCounts[entry.niche] ?? 0) + 1;
      styleCounts[entry.style] = (styleCounts[entry.style] ?? 0) + 1;
      for (final word in entry.prompt.toLowerCase().split(' ')) {
        if (word.length > 4) {
          promptKeywords[word] = (promptKeywords[word] ?? 0) + 1;
        }
      }
    }

    final topNiche = nicheCounts.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
    final topStyle = currentStyle ??
        styleCounts.entries
            .reduce((a, b) => a.value >= b.value ? a : b)
            .key;

    final nicheCount = nicheCounts[topNiche] ?? 0;
    final confidence = (_history.length >= 10 ? 0.92 : 0.65 + nicheCount * 0.05)
        .clamp(0.0, 0.99);

    final hooks = ViralHookEngine.generate(
      niche: topNiche,
      count: 3,
    );

    return hooks.map(
      (h) => IntentPrediction(
        prompt: h.text,
        style: topStyle,
        niche: topNiche,
        confidence: confidence,
        reason: 'Based on ${nicheCount}x ${topNiche.toLowerCase()} creations',
      ),
    ).toList();
  }

  /// Returns the user's most-used niche, or null if no history.
  String? get dominantNiche {
    if (_history.isEmpty) return null;
    final counts = <String, int>{};
    for (final e in _history) {
      counts[e.niche] = (counts[e.niche] ?? 0) + 1;
    }
    return counts.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }

  /// Returns the user's most-used style, or null if no history.
  String? get dominantStyle {
    if (_history.isEmpty) return null;
    final counts = <String, int>{};
    for (final e in _history) {
      counts[e.style] = (counts[e.style] ?? 0) + 1;
    }
    return counts.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }

  List<IntentPrediction> _coldStartPredictions(String? style) {
    final niches = ['Fitness', 'Food', 'Tech', 'Lifestyle'];
    return niches.map((niche) {
      final hooks = ViralHookEngine.generate(niche: niche, count: 1);
      return IntentPrediction(
        prompt: hooks.first.text,
        style: style ?? 'Cinematic',
        niche: niche,
        confidence: 0.5,
        reason: 'Trending in your region right now',
      );
    }).toList();
  }

  String _inferNiche(String prompt) {
    final lower = prompt.toLowerCase();
    const nicheKeywords = {
      'Fitness': ['fitness', 'gym', 'workout', 'abs', 'muscle', 'diet', 'health'],
      'Fashion': ['fashion', 'outfit', 'style', 'clothing', 'dress', 'wardrobe'],
      'Food': ['food', 'recipe', 'cooking', 'kitchen', 'restaurant', 'chef', 'meal'],
      'Tech': ['tech', 'phone', 'app', 'ai', 'software', 'gadget', 'iphone'],
      'Travel': ['travel', 'beach', 'island', 'flight', 'hotel', 'vacation', 'trip'],
      'Business': ['business', 'startup', 'marketing', 'sales', 'money', 'hustle'],
      'Beauty': ['beauty', 'skincare', 'makeup', 'cosmetic', 'serum', 'glow'],
      'Gaming': ['game', 'gaming', 'player', 'level', 'xbox', 'playstation'],
      'Education': ['learn', 'study', 'education', 'course', 'book', 'school'],
      'Lifestyle': ['lifestyle', 'morning', 'routine', 'habit', 'self-care'],
      'Real Estate': ['house', 'home', 'property', 'apartment', 'real estate'],
      'Crypto': ['crypto', 'bitcoin', 'blockchain', 'token', 'coin', 'defi'],
    };
    for (final entry in nicheKeywords.entries) {
      for (final keyword in entry.value) {
        if (lower.contains(keyword)) return entry.key;
      }
    }
    return 'Lifestyle';
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(
        _history.map((e) => e.toJson()).toList(),
      );
      await prefs.setString(_historyKey, json);
    } catch (_) {
      // Non-critical — predictions still work in-session.
    }
  }

  /// Clears all history (for testing or user reset).
  Future<void> clear() async {
    _history = [];
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
    } catch (_) {}
  }
}
