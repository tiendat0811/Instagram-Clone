import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
class ThemeProvider extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.system;

  bool get isDarkMode {
    if (themeMode == ThemeMode.system) {
      final brightness = SchedulerBinding.instance.window.platformBrightness;
      return brightness == Brightness.dark;
    } else {
      return themeMode == ThemeMode.dark;
    }
  }

  void toggleTheme(bool isOn) {
    themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}
class MyThemes{
  static final darkTheme = ThemeData(
    scaffoldBackgroundColor: Color.fromRGBO(0, 0, 0, 1),
    primaryColor: Colors.white,
    colorScheme: const ColorScheme.dark(),
    iconTheme: IconThemeData(color: Colors.white),
  );

  static final lightTheme = ThemeData(
    scaffoldBackgroundColor: Colors.white,
    primaryColor: Colors.black,
    colorScheme: const ColorScheme.light(),
    iconTheme: IconThemeData(color: Colors.black),
  );
}