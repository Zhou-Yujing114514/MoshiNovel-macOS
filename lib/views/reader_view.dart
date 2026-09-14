import 'package:flutter/material.dart';

import '../api_service.dart';
import '../app_state.dart';
import '../models.dart';
import '../widgets.dart';

/// 在线阅读页：章节列表 + 正文
class ReaderView extends StatefulWidget {
  final int taskId;
  final String? bookTitle;

  const ReaderView({super.key, required this.taskId, this.bookTitle});

  @override
  State<ReaderView> createState() => _ReaderViewState();
}

class _ReaderViewState extends State<ReaderView> {
  bool _loading = true;
  String? _error;
  String _title = '';
  List<Chapter> _chapters = [];
  bool _downloading = false;

  // 阅读态
  int? _currentIndex;
  String _content = '';
  bool _contentLoading = false;
  double _fontSize = 17;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final meta = await ApiService.shared.fetchBookMeta(widget.taskId);
      final chapters = await ApiService.shared.fetchChapters(widget.taskId);
      if (!mounted) return;
      setState(() {
        _title = meta.title ?? widget.bookTitle ?? '';
        _chapters = chapters;
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

  Future<void> _openChapter(int index) async {
    setState(() {
      _currentIndex = index;
      _contentLoading = true;
      _content = '';
    });
    try {
      final text = await ApiService.shared
          .fetchChapterContent(widget.taskId, index);
      if (!mounted) return;
      setState(() {
        _content = text;
        _contentLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _contentLoading = false;
        _content = '加载失败: $e';
      });
    }
  }

  Future<void> _refreshChapter() async {
    if (_currentIndex == null) return;
    await _openChapter(_currentIndex!);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppState.shared;
    return Scaffold(
      appBar: AppBar(
        title: Text(_title.isEmpty ? '在线阅读' : _title,
            overflow: TextOverflow.ellipsis),
        actions: [
          if (_chapters.isNotEmpty && _currentIndex == null)
            TextButton(
              onPressed: () => _openChapter(0),
              child: const Text('开始阅读'),
            ),
        ],
      ),
      body: _buildBody(app),
    );
  }

  Widget _buildBody(AppState app) {
    if (_loading) return const LoadingView(hint: '加载书籍…');
    if (_error != null) {
      return Center(
        child: ErrorBanner(message: _error!, onRetry: _load),
      );
    }
    if (_chapters.isEmpty) {
      return const EmptyView(text: '暂无章节（任务可能还在下载中，请稍候刷新）');
    }

    // 阅读视图
    if (_currentIndex != null) {
      return Column(
        children: [
          Expanded(
            child: _contentLoading
                ? const LoadingView(hint: '加载章节…')
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            _currentChapterTitle(),
                            style: TextStyle(
                              fontSize: _fontSize + 3,
                              fontWeight: FontWeight.w700,
                              color: M.text(app),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _content,
                          style: TextStyle(
                            fontSize: _fontSize,
                            height: 1.9,
                            color: M.text(app),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          // 底部控制栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: M.card(app),
              border: Border(top: BorderSide(color: M.border(app))),
            ),
            child: Row(
              children: [
                IconButton(
                  tooltip: '上一章',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _currentIndex! > 0
                      ? () => _openChapter(_currentIndex! - 1)
                      : null,
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '${_currentIndex! + 1} / ${_chapters.length}',
                      style: TextStyle(fontSize: 12, color: M.muted(app)),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '目录',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.list_outlined),
                  onPressed: () => setState(() => _currentIndex = null),
                ),
                IconButton(
                  tooltip: '刷新本章',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.refresh),
                  onPressed: _refreshChapter,
                ),
                IconButton(
                  tooltip: '减小字号',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.text_decrease),
                  onPressed: _fontSize > 13
                      ? () => setState(() => _fontSize -= 1)
                      : null,
                ),
                IconButton(
                  tooltip: '增大字号',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.text_increase),
                  onPressed: _fontSize < 26
                      ? () => setState(() => _fontSize += 1)
                      : null,
                ),
              ],
            ),
          ),
        ],
      );
    }

    // 章节列表
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        itemCount: _chapters.length,
        separatorBuilder: (_, __) => const SizedBox(height: 2),
        itemBuilder: (context, i) {
          final ch = _chapters[i];
          return ListTile(
            dense: true,
            leading: Text(
              '${i + 1}',
              style: TextStyle(fontSize: 12, color: M.muted(app)),
            ),
            title: Text(
              ch.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, color: M.text(app)),
            ),
            onTap: () => _openChapter(i),
          );
        },
      ),
    );
  }

  String _currentChapterTitle() {
    final i = _currentIndex;
    if (i == null || i < 0 || i >= _chapters.length) return '';
    return _chapters[i].title;
  }
}
