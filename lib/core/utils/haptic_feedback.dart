import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Utility class for haptic feedback on mobile devices
class HapticUtils {
  /// Light impact feedback (for taps, switches)
  static Future<void> lightImpact() async {
    if (!kIsWeb) {
      await HapticFeedback.lightImpact();
    }
  }
  
  /// Medium impact feedback (for button presses)
  static Future<void> mediumImpact() async {
    if (!kIsWeb) {
      await HapticFeedback.mediumImpact();
    }
  }
  
  /// Heavy impact feedback (for important actions)
  static Future<void> heavyImpact() async {
    if (!kIsWeb) {
      await HapticFeedback.heavyImpact();
    }
  }
  
  /// Selection feedback (for list items, switches)
  static Future<void> selectionClick() async {
    if (!kIsWeb) {
      await HapticFeedback.selectionClick();
    }
  }
  
  /// Vibrate feedback (for errors, warnings)
  static Future<void> vibrate() async {
    if (!kIsWeb) {
      await HapticFeedback.vibrate();
    }
  }
}
