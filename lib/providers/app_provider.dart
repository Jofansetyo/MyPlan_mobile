import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppProvider extends ChangeNotifier {
  final SharedPreferences _prefs;

  AppProvider({required SharedPreferences prefs}) : _prefs = prefs {
    _loadFromPrefs();
  }

  void _loadFromPrefs() {
    // Tema
    final themeName = _prefs.getString('themeMode') ?? 'light';
    _themeMode = ThemeMode.values.firstWhere(
      (e) => e.name == themeName,
      orElse: () => ThemeMode.light,
    );

    // Notifikasi
    _deadlineReminder = _prefs.getBool('deadlineReminder') ?? true;
    _spendingWarning = _prefs.getBool('spendingWarning') ?? true;

    // Profil
    _userName = _prefs.getString('userName') ?? 'Pengguna';
    _age = _prefs.getString('age') ?? '-';
    _occupation = _prefs.getString('occupation') ?? '-';
    _city = _prefs.getString('city') ?? '-';
    _avatarPath = _prefs.getString('avatarPath');

    // Latar belakang
    _bgType = _prefs.getString('bgType') ?? 'color';
    final colorValue = _prefs.getInt('bgColor');
    _bgColor = colorValue != null ? Color(colorValue) : const Color(0xFFE4E4E4);
    _bgImagePath = _prefs.getString('bgImagePath');
    _bgVideoPath = _prefs.getString('bgVideoPath');
  }

  // ============ TEMA ============
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _prefs.setString('themeMode', mode.name);
    notifyListeners();
  }

  // ============ NOTIFIKASI ============
  bool _deadlineReminder = true;
  bool _spendingWarning = true;
  bool get deadlineReminder => _deadlineReminder;
  bool get spendingWarning => _spendingWarning;

  void toggleDeadlineReminder(bool v) {
    _deadlineReminder = v;
    _prefs.setBool('deadlineReminder', v);
    notifyListeners();
  }

  void toggleSpendingWarning(bool v) {
    _spendingWarning = v;
    _prefs.setBool('spendingWarning', v);
    notifyListeners();
  }

  // ============ PROFIL ============
  String _userName = 'Pengguna';
  String _age = '-';
  String _occupation = '-';
  String _city = '-';
  String? _avatarPath;

  String get userName => _userName;
  String get age => _age;
  String get occupation => _occupation;
  String get city => _city;
  String? get avatarPath => _avatarPath;

  void updateProfile({
    String? name,
    String? age,
    String? occupation,
    String? city,
    String? avatarPath,
  }) {
    if (name != null) {
      _userName = name;
      _prefs.setString('userName', name);
    }
    if (age != null) {
      _age = age;
      _prefs.setString('age', age);
    }
    if (occupation != null) {
      _occupation = occupation;
      _prefs.setString('occupation', occupation);
    }
    if (city != null) {
      _city = city;
      _prefs.setString('city', city);
    }
    if (avatarPath != null) {
      _avatarPath = avatarPath;
      _prefs.setString('avatarPath', avatarPath);
    }
    notifyListeners();
  }

  // ============ LATAR BELAKANG ============
  String _bgType = 'color';
  Color _bgColor = const Color(0xFFE4E4E4);
  String? _bgImagePath;
  String? _bgVideoPath;

  String get bgType => _bgType;
  Color get bgColor => _bgColor;
  String? get bgImagePath => _bgImagePath;
  String? get bgVideoPath => _bgVideoPath;

  void _saveBgToPrefs() {
    _prefs.setString('bgType', _bgType);
    _prefs.setInt('bgColor', _bgColor.toARGB32());
    if (_bgImagePath != null) {
      _prefs.setString('bgImagePath', _bgImagePath!);
    } else {
      _prefs.remove('bgImagePath');
    }
    if (_bgVideoPath != null) {
      _prefs.setString('bgVideoPath', _bgVideoPath!);
    } else {
      _prefs.remove('bgVideoPath');
    }
  }

  void setBgColor(Color color) {
    _bgType = 'color';
    _bgColor = color;
    _bgImagePath = null;
    _bgVideoPath = null;
    _saveBgToPrefs();
    notifyListeners();
  }

  void setBgImage(String path) {
    _bgType = 'image';
    _bgImagePath = path;
    _bgVideoPath = null;
    _saveBgToPrefs();
    notifyListeners();
  }

  void setBgVideo(String path) {
    _bgType = 'video';
    _bgVideoPath = path;
    _bgImagePath = null;
    _saveBgToPrefs();
    notifyListeners();
  }

  void resetBg() {
    _bgType = 'color';
    _bgColor = const Color(0xFFE4E4E4);
    _bgImagePath = null;
    _bgVideoPath = null;
    _saveBgToPrefs();
    notifyListeners();
  }
}
