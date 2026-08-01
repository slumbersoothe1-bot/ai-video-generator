import 'package:flutter/services.dart';

/// Centralized haptic feedback helper. Every meaningful tap, selection,
/// or state transition in the app fires a haptic so the UI feels physical
/// and responsive — the "Smart Village" mind-reading layer.
class Haptics {
  Haptics._();

  /// Light tap — used for button presses, chip selections, toggles.
  static void tap() => HapticFeedback.lightImpact();

  /// Medium impact — used for successful actions, confirmations.
  static void select() => HapticFeedback.mediumImpact();

  /// Heavy impact — used for major state changes, generation start.
  static void heavy() => HapticFeedback.heavyImpact();

  /// Selection tick — used for scrolling through options, sliders.
  static void tick() => HapticFeedback.selectionClick();

  /// Success pattern — two light taps in quick succession.
  static void success() {
    HapticFeedback.lightImpact();
    Future.delayed(const Duration(milliseconds: 80), () {
      HapticFeedback.lightImpact();
    });
  }

  /// Warning pattern — medium impact followed by light.
  static void warning() {
    HapticFeedback.mediumImpact();
    Future.delayed(const Duration(milliseconds: 100), () {
      HapticFeedback.lightImpact();
    });
  }

  /// Error pattern — three rapid medium impacts.
  static void error() {
    HapticFeedback.mediumImpact();
    Future.delayed(const Duration(milliseconds: 80), () {
      HapticFeedback.mediumImpact();
    });
    Future.delayed(const Duration(milliseconds: 160), () {
      HapticFeedback.mediumImpact();
    });
  }
}
