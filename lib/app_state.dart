import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
import 'models.dart';

/// 应用全局状态
class AppState extends ChangeNotifier {
  AppState._();

  static final AppState shared = AppState._();

  User? currentUser;
  SiteConfig? siteConfig;
  bool isLoggedIn = false;
  bool isDayMode = false;
  int runningCount = 0;
  int queuedCount = 0;

  static const _dayModeKey = 'moshi_day_mode';
  static const _cookiesKey = 'moshi_cookies';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    isDayMode = prefs.getBool(_dayModeKey) ?? false;

    // 恢复会话 cookie
    final saved = prefs.getString(_cookiesKey);
    if (saved != null && saved.isNotEmpty) {
      try {
        final decoded = jsonDecode(saved);
        if (decoded is Map<String, dynamic>) {
          ApiService.shared.restoreCookies(
              decoded.map((k, v) => MapEntry(k, v.toString())));
          // 用 /api/me 验证会话是否有效
          try {
            final user = await ApiService.shared.fetchMe();
            if (user != null) {
              setUser(user);
            } else {
              ApiService.shared.restoreCookies({});
            }
          } catch (_) {
            ApiService.shared.restoreCookies({});
          }
        }
      } catch (_) {}
    }
  }

  Future<void> persistSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dayModeKey, isDayMode);
    final cookies = ApiService.shared.allCookies;
    if (cookies.isNotEmpty) {
      await prefs.setString(_cookiesKey, jsonEncode(cookies));
    } else {
      await prefs.remove(_cookiesKey);
    }
  }

  void setUser(User? user) {
    currentUser = user;
    isLoggedIn = user != null;
    notifyListeners();
  }

  Future<void> toggleDayMode() async {
    isDayMode = !isDayMode;
    notifyListeners();
    await persistSession();
  }

  void updateCounts(int running, int queued) {
    runningCount = running;
    queuedCount = queued;
    notifyListeners();
  }
}
