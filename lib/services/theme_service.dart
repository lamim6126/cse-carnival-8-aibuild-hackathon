import 'package:flutter/material.dart';

class ThemeService {
  static final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.light);

  static void toggleTheme() {
    if (themeModeNotifier.value == ThemeMode.light) {
      themeModeNotifier.value = ThemeMode.dark;
    } else {
      themeModeNotifier.value = ThemeMode.light;
    }
  }
}
