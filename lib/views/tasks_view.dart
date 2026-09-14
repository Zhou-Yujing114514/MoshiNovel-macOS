import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../api_service.dart';
import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'reader_view.dart';

/// 任务页：我的提取 / 全站提取，5 秒自动刷新
class TasksView extends StatefulWidget {
  const TasksView({super.key});

  @override
  State<TasksView> createState() => _TasksViewState();
}

class _TasksViewState extends State<TasksView> {
  int _tab = 0; // 0=我的提取 1=全站提取
  List<DownloadTask> _all = [];
  bool _loading = false;
  String? _error;
  int? _downloadingTaskId;
  double _downloadProgress = 0;

  @override
  void initState() {
    super.initState();
    _load();
    TimerHelper.start(_load, 5);
  }

  @override
  void dispose() {
    TimerHelper.stop();
    super.dispose();
  }

  List<DownloadTask> get _visibleTasks {
    if (_tab == 0) {
      final me = AppState.shared.currentUser;
      if (me == null) return [];
      final uname = me.username.toLowerCase();
      return _all
          .where((t) => (t.username ?? '').toLowerCase() == uname)
          .toList();
    }
    return _all;
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resp = await ApiService.shared.fetchTasks();
      if (!mounted) return;
      AppState.shared.updateCounts(resp.running ?? 0, resp.queued ?? 0);
      setState(() {
        _all = resp.items ?? [];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _cancel(DownloadTask task) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('取消任务'),
        content: Text('确定取消「${task.title ?? '任务 #${task.id}'}」吗？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('再想想')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('取消任务')),
        ],
      ),
    );
    if (ok == true) {
      await ApiService.shared.cancelTask(task.id);
      _load();
    }
  }

  Future<void> _download(DownloadTask task) async {
    final urlStr = task.downloadUrl;
    if (urlStr == null || urlStr.isEmpty) return;
    final fullUrl = urlStr.startsWith('http')
        ? urlStr
        : 'https://morax.kdns.fr${urlStr.startsWith('/') ? urlStr : '/$urlStr'}';
    setState(() {
      _downloadingTaskId = task.id;
      _downloadProgress = 0;
    });
    try {
      final resp = await http.get(Uri.parse(fullUrl));
      if (resp.statusCode != 200) {
        throw Exception('下载失败 (${resp.statusCode})');
      }
      final bytes = resp.bodyBytes;
      final ext = _extensionFor(task.format);
      final suggested =
          '${task.title ?? 'book_${task.id}'}.$ext'.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      String? savePath;
      if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
        final loc = await getSaveLocation(
          suggestedName: suggested,
          acceptedTypeGroups: [
            XTypeGroup(
              label: task.format ?? 'file',
              extensions: [ext],
              mimeTypes: [ext == 'pdf' ? 'application/pdf' : 'application/octet-stream'],
            ),
          ],
        );
        if (loc != null) savePath = loc.path;
      } else {
        final dir = await getApplicationDocumentsDirectory();
        savePath = '${dir.path}/$suggested';
      }
      if (savePath == null) {
        if (mounted) setState(() => _downloadingTaskId = null);
        return; // 用户取消保存对话框
      }
      final file = File(savePath);
      await file.writeAsBytes(bytes);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已保存到 $savePath')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('下载失败: $e')),
      );
    } finally {
      if (mounted) setState(() => _downloadingTaskId = null);
    }
  }

  String _extensionFor(String? format) {
    switch ((format ?? '').toLowerCase()) {
      case 'epub':
        return 'epub';
      case 'pdf':
        return 'pdf';
      default:
        return 'txt';
    }
  }

  void _openReader(DownloadTask task) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReaderView(taskId: task.id, bookTitle: task.title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppState.shared;
    final tasks = _visibleTasks;
    return Scaffold(
      appBar: AppBar(title: const Text('下载任务')),
      body: Column(
        children: [
          // 顶部标签
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                _tabButton('我的提取', 0),
                _tabButton('全站提取', 1),
                const Spacer(),
                if (!app.isLoggedIn)
                  Text('未登录',
                      style: TextStyle(fontSize: 12, color: M.muted(app)))
                else
                  Text(
                    '运行 ${app.runningCount} · 排队 ${app.queuedCount}',
                    style: TextStyle(fontSize: 12, color: M.muted(app)),
                  ),
              ],
            ),
          ),
          if (_error != null)
            ErrorBanner(message: _error!, onRetry: _load),
          Expanded(
            child: _loading && tasks.isEmpty
                ? const LoadingView(hint: '加载任务中…')
                : tasks.isEmpty
                    ? const EmptyView(text: '暂无任务，去搜索页提交一个吧')
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: tasks.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) =>
                              _buildTaskCard(tasks[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton(String title, int index) {
    final app = AppState.shared;
    final selected = _tab == index;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected
            ? AppColors.accent.withOpacity(0.14)
            : M.card(app),
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () {
            setState(() => _tab = index);
            _load();
          },
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: selected ? AppColors.accent : M.muted(app),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(DownloadTask task) {
    final app = AppState.shared;
    final st = task.state;
    final progress = task.progress;
    return MCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  task.title ?? '任务 #${task.id}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: M.text(app),
                  ),
                ),
              ),
              _statusChip(st),
            ],
          ),
          if (task.author != null && task.author!.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text('作者：${task.author}',
                style: TextStyle(fontSize: 12, color: M.muted(app))),
          ],
          const SizedBox(height: 6),
          Text(
            '${(task.format ?? 'txt').toUpperCase()}'
            '${progress?.phase != null ? ' · ${progress!.phase}' : ''}'
            '${progress?.savedChapters != null ? ' · ${progress!.savedChapters}/${progress!.chapterTotal ?? '?'} 章' : ''}'
            '${task.error != null ? ' · ${task.error}' : ''}',
            style: TextStyle(fontSize: 12, color: M.muted(app)),
          ),
          if (st == TaskStatus.queued && task.position != null) ...[
            const SizedBox(height: 4),
            Text('队列位置 #${task.position}',
                style: TextStyle(fontSize: 12, color: AppColors.amber)),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              if (st == TaskStatus.done &&
                  task.downloadUrl != null &&
                  task.expired != true)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.green,
                    side: BorderSide(color: AppColors.green.withOpacity(0.6)),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onPressed: _downloadingTaskId == task.id
                      ? null
                      : () => _download(task),
                  icon: const Icon(Icons.download_outlined, size: 16),
                  label: Text(_downloadingTaskId == task.id
                      ? '下载中…'
                      : '下载文件'),
                ),
              if (st == TaskStatus.done) ...[
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: BorderSide(color: AppColors.accent.withOpacity(0.6)),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onPressed: () => _openReader(task),
                  icon: const Icon(Icons.menu_book_outlined, size: 16),
                  label: const Text('在线阅读'),
                ),
              ],
              const Spacer(),
              if (st == TaskStatus.queued || st == TaskStatus.running)
                IconButton(
                  tooltip: '取消任务',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.close, size: 18, color: AppColors.red),
                  onPressed: () => _cancel(task),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip(TaskStatus? st) {
    switch (st) {
      case TaskStatus.queued:
        return StatusChip(text: '排队中', color: AppColors.amber);
      case TaskStatus.running:
        return StatusChip(text: '下载中', color: AppColors.accent);
      case TaskStatus.done:
        return StatusChip(text: '已完成', color: AppColors.green);
      case TaskStatus.failed:
        return StatusChip(text: '失败', color: AppColors.red);
      case TaskStatus.canceled:
        return StatusChip(text: '已取消', color: AppColors.muted);
      default:
        return const SizedBox.shrink();
    }
  }
}

/// 简易周期定时器（每个页面单例，页面切换时重启）
class TimerHelper {
  static Timer? _timer;

  static void start(VoidCallback fn, int seconds) {
    stop();
    _timer = Timer.periodic(Duration(seconds: seconds), (_) => fn());
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
