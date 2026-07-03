import 'package:flutter/services.dart';
import 'package:khmerkid/services/storage_service.dart';

class AppHaptics {
  static void lightImpact() {
    if (StorageService.isHapticsEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  static void mediumImpact() {
    if (StorageService.isHapticsEnabled) {
      HapticFeedback.mediumImpact();
    }
  }

  static void heavyImpact() {
    if (StorageService.isHapticsEnabled) {
      HapticFeedback.heavyImpact();
    }
  }

  static void selectionClick() {
    if (StorageService.isHapticsEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  static void vibrate() {
    if (StorageService.isHapticsEnabled) {
      HapticFeedback.vibrate();
    }
  }
}
