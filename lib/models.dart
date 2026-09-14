/// 数据模型（与 iOS 版 MoshiNovel 对齐）

// 站点配置
class SiteConfig {
  final String? siteTitle;
  final String? siteOwner;
  final String? siteNotice;
  final String? siteVersion;
  final bool? disabled;
  final bool? maintenance;

  SiteConfig({
    this.siteTitle,
    this.siteOwner,
    this.siteNotice,
    this.siteVersion,
    this.disabled,
    this.maintenance,
  });

  factory SiteConfig.fromJson(Map<String, dynamic> json) => SiteConfig(
        siteTitle: json['site_title'] as String?,
        siteOwner: json['site_owner'] as String?,
        siteNotice: json['site_notice'] as String?,
        siteVersion: json['site_version'] as String?,
        disabled: json['disabled'] as bool?,
        maintenance: json['maintenance'] as bool?,
      );
}

// 用户
class User {
  final String username;
  final bool? isAdmin;
  final bool? highRank;
  final String? title;
  final int? createdAt;

  User({
    required this.username,
    this.isAdmin,
    this.highRank,
    this.title,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        username: json['username'] as String? ?? '',
        isAdmin: json['is_admin'] as bool?,
        highRank: json['high_rank'] as bool?,
        title: json['title'] as String?,
        createdAt: (json['created_at'] as num?)?.toInt(),
      );
}

// 搜索结果
class SearchResult {
  final String id;
  final String title;
  final String? author;
  final String? cover;
  final String? intro;

  SearchResult({
    required this.id,
    required this.title,
    this.author,
    this.cover,
    this.intro,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) => SearchResult(
        id: json['book_id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        author: json['author'] as String?,
        cover: json['cover'] as String?,
        intro: json['intro'] as String?,
      );
}

// 任务进度
class TaskProgress {
  final int? chapterTotal;
  final int? savedChapters;
  final String? phase;

  TaskProgress({this.chapterTotal, this.savedChapters, this.phase});

  factory TaskProgress.fromJson(Map<String, dynamic> json) => TaskProgress(
        chapterTotal: (json['chapter_total'] as num?)?.toInt(),
        savedChapters: (json['saved_chapters'] as num?)?.toInt(),
        phase: json['phase'] as String?,
      );
}

// 任务状态
enum TaskStatus {
  queued,
  running,
  done,
  failed,
  canceled;

  static TaskStatus? from(String? s) {
    switch (s) {
      case 'queued':
        return TaskStatus.queued;
      case 'running':
        return TaskStatus.running;
      case 'done':
        return TaskStatus.done;
      case 'failed':
        return TaskStatus.failed;
      case 'canceled':
        return TaskStatus.canceled;
      default:
        return null;
    }
  }

  String get displayName {
    switch (this) {
      case TaskStatus.queued:
        return '排队中';
      case TaskStatus.running:
        return '下载中';
      case TaskStatus.done:
        return '已完成';
      case TaskStatus.failed:
        return '失败';
      case TaskStatus.canceled:
        return '已取消';
    }
  }
}

// 下载任务
class DownloadTask {
  final int id;
  final String? bookId;
  final String? title;
  final String? author;
  final String? format;
  final TaskStatus? state;
  final TaskProgress? progress;
  final int? position;
  final String? downloadUrl;
  final String? error;
  final int? createdAt;
  final String? username;
  final bool? expired;

  DownloadTask({
    required this.id,
    this.bookId,
    this.title,
    this.author,
    this.format,
    this.state,
    this.progress,
    this.position,
    this.downloadUrl,
    this.error,
    this.createdAt,
    this.username,
    this.expired,
  });

  factory DownloadTask.fromJson(Map<String, dynamic> json) => DownloadTask(
        id: (json['id'] as num?)?.toInt() ?? 0,
        bookId: json['book_id'] as String?,
        title: json['title'] as String?,
        author: json['author'] as String?,
        format: json['format'] as String?,
        state: TaskStatus.from(json['state'] as String?),
        progress: json['progress'] is Map
            ? TaskProgress.fromJson(json['progress'] as Map<String, dynamic>)
            : null,
        position: (json['position'] as num?)?.toInt(),
        downloadUrl: json['download_url'] as String?,
        error: json['error'] as String?,
        createdAt: (json['created_at'] as num?)?.toInt(),
        username: json['username'] as String?,
        expired: json['expired'] as bool?,
      );
}

// API 响应
class LoginResponse {
  final bool? ok;
  final String? error;
  final User? user;
  final String? token;

  LoginResponse({this.ok, this.error, this.user, this.token});

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
        ok: json['ok'] as bool?,
        error: json['error'] as String?,
        user: json['user'] is Map
            ? User.fromJson(json['user'] as Map<String, dynamic>)
            : null,
        token: json['token'] as String?,
      );
}

class MeResponse {
  final User? user;

  MeResponse({this.user});

  factory MeResponse.fromJson(Map<String, dynamic> json) => MeResponse(
        user: json['user'] is Map
            ? User.fromJson(json['user'] as Map<String, dynamic>)
            : null,
      );
}

class SubmitResponse {
  final bool? ok;
  final String? error;
  final int? id;
  final int? position;

  SubmitResponse({this.ok, this.error, this.id, this.position});

  factory SubmitResponse.fromJson(Map<String, dynamic> json) =>
      SubmitResponse(
        ok: json['ok'] as bool?,
        error: json['error'] as String?,
        id: (json['id'] as num?)?.toInt(),
        position: (json['position'] as num?)?.toInt(),
      );
}

class BasicResponse {
  final bool? ok;
  final String? error;

  BasicResponse({this.ok, this.error});

  factory BasicResponse.fromJson(Map<String, dynamic> json) =>
      BasicResponse(ok: json['ok'] as bool?, error: json['error'] as String?);
}

class TaskListResponse {
  final List<DownloadTask>? items;
  final int? running;
  final int? queued;

  TaskListResponse({this.items, this.running, this.queued});

  factory TaskListResponse.fromJson(Map<String, dynamic> json) =>
      TaskListResponse(
        items: (json['items'] as List?)
            ?.map((e) => DownloadTask.fromJson(e as Map<String, dynamic>))
            .toList(),
        running: (json['running'] as num?)?.toInt(),
        queued: (json['queued'] as num?)?.toInt(),
      );
}

class SearchResponse {
  final List<SearchResult>? items;

  SearchResponse({this.items});

  factory SearchResponse.fromJson(Map<String, dynamic> json) =>
      SearchResponse(
        items: (json['items'] as List?)
            ?.map((e) => SearchResult.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

// 在线阅读
class BookMeta {
  final String? title;
  final bool? downloading;
  final int? chapterCount;
  final int? total;

  BookMeta({this.title, this.downloading, this.chapterCount, this.total});

  factory BookMeta.fromJson(Map<String, dynamic> json) => BookMeta(
        title: json['title'] as String?,
        downloading: json['downloading'] as bool?,
        chapterCount: (json['chapter_count'] as num?)?.toInt(),
        total: (json['total'] as num?)?.toInt(),
      );
}

class Chapter {
  final String title;
  final String? href;

  Chapter({required this.title, this.href});

  factory Chapter.fromJson(Map<String, dynamic> json) =>
      Chapter(title: json['title'] as String? ?? '', href: json['href'] as String?);
}

// 管理员信息
class AdminInfo {
  final int? queued;
  final int? running;
  final int? tasks;
  final int? users;
  final String? siteTitle;
  final String? siteOwner;
  final int? maxQueueLen;
  final int? rateLimitPerIp;
  final int? rateLimitWindowMin;
  final int? downloadTtlHours;
  final String? tomatoAddr;
  final String? dataDir;
  final String? appAddr;

  AdminInfo({
    this.queued,
    this.running,
    this.tasks,
    this.users,
    this.siteTitle,
    this.siteOwner,
    this.maxQueueLen,
    this.rateLimitPerIp,
    this.rateLimitWindowMin,
    this.downloadTtlHours,
    this.tomatoAddr,
    this.dataDir,
    this.appAddr,
  });

  factory AdminInfo.fromJson(Map<String, dynamic> json) => AdminInfo(
        queued: (json['queued'] as num?)?.toInt(),
        running: (json['running'] as num?)?.toInt(),
        tasks: (json['tasks'] as num?)?.toInt(),
        users: (json['users'] as num?)?.toInt(),
        siteTitle: json['site_title'] as String?,
        siteOwner: json['site_owner'] as String?,
        maxQueueLen: (json['max_queue_len'] as num?)?.toInt(),
        rateLimitPerIp: (json['rate_limit_per_ip'] as num?)?.toInt(),
        rateLimitWindowMin: (json['rate_limit_window_min'] as num?)?.toInt(),
        downloadTtlHours: (json['download_ttl_hours'] as num?)?.toInt(),
        tomatoAddr: json['tomato_addr'] as String?,
        dataDir: json['data_dir'] as String?,
        appAddr: json['app_addr'] as String?,
      );
}

class AdminSettings {
  final String? siteTitle;
  final String? siteVersion;
  final String? siteOwner;
  final String? siteNotice;
  final int? maxQueueLen;
  final int? rateLimitPerIp;
  final int? rateLimitWindowMin;
  final int? downloadTtlHours;
  final bool? disabled;
  final bool? maintenance;

  AdminSettings({
    this.siteTitle,
    this.siteVersion,
    this.siteOwner,
    this.siteNotice,
    this.maxQueueLen,
    this.rateLimitPerIp,
    this.rateLimitWindowMin,
    this.downloadTtlHours,
    this.disabled,
    this.maintenance,
  });

  factory AdminSettings.fromJson(Map<String, dynamic> json) => AdminSettings(
        siteTitle: json['site_title'] as String?,
        siteVersion: json['site_version'] as String?,
        siteOwner: json['site_owner'] as String?,
        siteNotice: json['site_notice'] as String?,
        maxQueueLen: (json['max_queue_len'] as num?)?.toInt(),
        rateLimitPerIp: (json['rate_limit_per_ip'] as num?)?.toInt(),
        rateLimitWindowMin: (json['rate_limit_window_min'] as num?)?.toInt(),
        downloadTtlHours: (json['download_ttl_hours'] as num?)?.toInt(),
        disabled: json['disabled'] as bool?,
        maintenance: json['maintenance'] as bool?,
      );
}

class UserListResponse {
  final List<User>? items;
  final String? error;

  UserListResponse({this.items, this.error});

  factory UserListResponse.fromJson(Map<String, dynamic> json) =>
      UserListResponse(
        items: (json['items'] as List?)
            ?.map((e) => User.fromJson(e as Map<String, dynamic>))
            .toList(),
        error: json['error'] as String?,
      );
}
