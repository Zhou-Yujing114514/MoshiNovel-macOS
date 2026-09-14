import 'dart:convert';

import 'package:http/http.dart' as http;

import 'config.dart';
import 'models.dart';

/// API 服务（与 iOS 版 MoshiNovel 对齐，cookie 会话保持）
class ApiService {
  ApiService._();

  static final ApiService shared = ApiService._();

  final http.Client _client = http.Client();
  final Map<String, String> _cookies = {};

  String get baseUrl => ServerConfig.defaultBaseUrl;

  void setCookiesFromResponse(http.Response resp) {
    final setCookies = resp.headers['set-cookie'];
    if (setCookies == null || setCookies.isEmpty) return;
    // 可能存在多个 Set-Cookie（逗号分隔），逐个尝试解析
    for (final part in setCookies.split(',')) {
      final trimmed = part.trim();
      final eq = trimmed.indexOf('=');
      if (eq <= 0) continue;
      final name = trimmed.substring(0, eq).trim();
      final value = trimmed.substring(eq + 1).split(';').first.trim();
      if (name.isNotEmpty && value.isNotEmpty) {
        _cookies[name] = value;
      }
    }
  }

  Map<String, String> get cookieHeader {
    if (_cookies.isEmpty) return const {};
    return {
      'Cookie': _cookies.entries
          .map((e) => '${e.key}=${e.value}')
          .join('; '),
    };
  }

  void restoreCookies(Map<String, String> cookies) {
    _cookies
      ..clear()
      ..addAll(cookies);
  }

  Map<String, String> get allCookies => Map.of(_cookies);

  Future<http.Response> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool isForm = false,
  }) async {
    final uri = Uri.parse(ServerConfig.defaultBaseUrl + path);
    final req = http.Request(method, uri);
    if (isForm) {
      req.headers['Content-Type'] = 'application/x-www-form-urlencoded';
      if (body != null) {
        req.body = body.entries
            .map((e) =>
                '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value?.toString() ?? '')}')
            .join('&');
      }
    } else {
      req.headers['Content-Type'] = 'application/json';
      if (body != null) {
        req.body = jsonEncode(body);
      }
    }
    req.headers.addAll(cookieHeader);
    final streamed = await _client.send(req);
    final resp = await http.Response.fromStream(streamed);
    setCookiesFromResponse(resp);
    return resp;
  }

  T _decode<T>(http.Response resp, T Function(Map<String, dynamic>) fromJson) {
    if (resp.statusCode == 401) {
      throw ApiException(401, '未登录或登录已过期');
    }
    final dynamic data;
    try {
      data = jsonDecode(utf8.decode(resp.bodyBytes));
    } catch (_) {
      throw ApiException(resp.statusCode, '响应解析失败 (${resp.statusCode})');
    }
    if (data is! Map<String, dynamic>) {
      throw ApiException(resp.statusCode, '响应格式错误');
    }
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      final err = data['error'] as String?;
      throw ApiException(resp.statusCode, err ?? '服务器错误 (${resp.statusCode})');
    }
    return fromJson(data);
  }

  // MARK: - 站点信息
  Future<SiteConfig> fetchSiteConfig() async {
    final resp = await _send('GET', '/api/site');
    return _decode(resp, SiteConfig.fromJson);
  }

  // MARK: - 用户
  Future<User?> fetchMe() async {
    final resp = await _send('GET', '/api/me');
    if (resp.statusCode == 401) return null;
    return _decode(resp, MeResponse.fromJson).user;
  }

  Future<LoginResponse> login(String username, String password) async {
    final resp = await _send('POST', '/api/login',
        body: {'username': username, 'password': password});
    return _decode(resp, LoginResponse.fromJson);
  }

  Future<LoginResponse> register(String username, String password) async {
    final resp = await _send('POST', '/api/register',
        body: {'username': username, 'password': password});
    return _decode(resp, LoginResponse.fromJson);
  }

  Future<void> logout() async {
    try {
      await _send('POST', '/api/logout', body: const {});
    } catch (_) {}
    _cookies.clear();
  }

  // MARK: - 搜索
  Future<List<SearchResult>> searchBooks(String query) async {
    final encoded = Uri.encodeQueryComponent(query);
    final resp = await _send('GET', '/api/search?q=$encoded');
    return _decode(resp, SearchResponse.fromJson).items ?? [];
  }

  // MARK: - 任务
  Future<TaskListResponse> fetchTasks({String? bookId}) async {
    final path = (bookId != null && bookId.isNotEmpty)
        ? '/api/tasks?book_id=${Uri.encodeQueryComponent(bookId)}'
        : '/api/tasks';
    final resp = await _send('GET', path);
    return _decode(resp, TaskListResponse.fromJson);
  }

  Future<SubmitResponse> submitTask(String bookId, String format) async {
    final resp = await _send('POST', '/api/tasks',
        body: {'book_id': bookId, 'format': format});
    return _decode(resp, SubmitResponse.fromJson);
  }

  Future<void> cancelTask(int taskId) async {
    try {
      await _send('DELETE', '/api/tasks/$taskId');
    } catch (_) {}
  }

  // MARK: - 在线阅读
  Future<BookMeta> fetchBookMeta(int taskId) async {
    final resp = await _send('GET', '/api/book/$taskId/meta');
    return _decode(resp, BookMeta.fromJson);
  }

  Future<List<Chapter>> fetchChapters(int taskId) async {
    final resp = await _send('GET', '/api/book/$taskId/chapters');
    // 注意：/chapters 返回的是 JSON 数组，不是 {items: [...]} 对象
    final dynamic data;
    try {
      data = jsonDecode(utf8.decode(resp.bodyBytes));
    } catch (_) {
      throw ApiException(resp.statusCode, '响应解析失败 (${resp.statusCode})');
    }
    if (data is! List) {
      throw ApiException(resp.statusCode, '响应格式错误');
    }
    return data
        .map((e) => Chapter.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<String> fetchChapterContent(int taskId, int index) async {
    final resp = await _send('GET', '/api/book/$taskId/chapter/$index');
    return utf8.decode(resp.bodyBytes);
  }

  // MARK: - 管理
  Future<List<User>> fetchUsers() async {
    final resp = await _send('GET', '/api/admin/users');
    return _decode(resp, UserListResponse.fromJson).items ?? [];
  }

  Future<void> setUserTitle(String username, String title) async {
    final resp = await _send('POST', '/api/admin/set-title',
        body: {'username': username, 'title': title});
    _decode(resp, BasicResponse.fromJson);
  }

  Future<void> deleteUser(String username) async {
    final resp = await _send('POST', '/api/admin/delete-user',
        body: {'username': username});
    _decode(resp, BasicResponse.fromJson);
  }

  Future<void> clearRecords() async {
    final resp = await _send('POST', '/api/admin/clear', body: const {});
    _decode(resp, BasicResponse.fromJson);
  }

  Future<AdminInfo> fetchAdminInfo() async {
    final resp = await _send('GET', '/api/admin/info');
    return _decode(resp, AdminInfo.fromJson);
  }

  Future<AdminSettings> fetchAdminSettings() async {
    final resp = await _send('GET', '/api/admin/settings');
    return _decode(resp, AdminSettings.fromJson);
  }

  Future<void> saveAdminSettings(Map<String, dynamic> settings) async {
    final resp = await _send('POST', '/api/admin/settings', body: settings);
    _decode(resp, BasicResponse.fromJson);
  }

  Future<void> createUser(String username, String password) async {
    final resp = await _send('POST', '/api/admin/create-user',
        body: {'username': username, 'password': password});
    _decode(resp, BasicResponse.fromJson);
  }

  Future<void> setUserPassword(String username, String password) async {
    final resp = await _send('POST', '/api/admin/set-password',
        body: {'username': username, 'password': password});
    _decode(resp, BasicResponse.fromJson);
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}
