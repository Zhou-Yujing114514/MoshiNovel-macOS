import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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

  // 会话 cookie 属于敏感凭证，使用系统安全存储（Keychain / Keystore / libsecret）
  static final _storage = FlutterSecureStorage(
    aOptions: const AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    isDayMode = prefs.getBool(_dayModeKey) ?? false;

    // 恢复会话 cookie（从安全存储读取）
    try {
      final saved = await _storage.read(key: _cookiesKey);
      if (saved != null && saved.isNotEmpty) {
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
              await _storage.delete(key: _cookiesKey);
            }
          } catch (_) {
            await _storage.delete(key: _cookiesKey);
          }
        }
      }
    } catch (_) {}
  }

  Future<void> persistSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dayModeKey, isDayMode);
    final cookies = ApiService.shared.allCookies;
    try {
      if (cookies.isNotEmpty) {
        await _storage.write(key: _cookiesKey, value: jsonEncode(cookies));
      } else {
        await _storage.delete(key: _cookiesKey);
      }
    } catch (_) {}
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
