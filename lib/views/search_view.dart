import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../api_service.dart';
import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'reader_view.dart';

/// 搜索页：搜索小说、选择格式、提交任务 / 在线阅读预览
class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final TextEditingController _controller = TextEditingController();
  List<SearchResult> _results = [];
  bool _loading = false;
  String? _error;
  bool _submitting = false;

  Future<void> _search(String q) async {
    final query = q.trim();
    if (query.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await ApiService.shared.searchBooks(query);
      if (!mounted) return;
      setState(() {
        _results = items;
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

  Future<void> _submit(SearchResult book, String format) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final resp = await ApiService.shared.submitTask(book.id, format);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            resp.position != null
                ? '已提交：${book.title}（队列位置 #${resp.position}）'
                : '已提交：${book.title}',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('提交失败: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _preview(SearchResult book) async {
    // 预览：提交 epub 任务并进入阅读器（复用已完成的 epub 任务）
    try {
      final tasks = await ApiService.shared.fetchTasks(bookId: book.id);
      DownloadTask? reusable;
      if (tasks.items != null) {
        for (final t in tasks.items!) {
          if ((t.format ?? '').toLowerCase() == 'epub' && t.state == TaskStatus.done) {
            reusable = t;
            break;
          }
          if ((t.format ?? '').toLowerCase() == 'epub' &&
              (t.state == TaskStatus.queued || t.state == TaskStatus.running)) {
            reusable = t;
            break;
          }
        }
      }
      final int taskId;
      if (reusable != null) {
        taskId = reusable.id;
      } else {
        final resp = await ApiService.shared.submitTask(book.id, 'epub');
        final id = resp.id;
        if (id == null) throw Exception('提交预览任务失败');
        taskId = id;
      }
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReaderView(taskId: taskId, bookTitle: book.title),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('预览失败: $e')),
      );
    }
  }

  void _showFormatSheet(SearchResult book) {
    final app = AppState.shared;
    showModalBottomSheet(
      context: context,
      backgroundColor: M.card(app),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '选择下载格式 · ${book.title}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: M.text(app),
                ),
              ),
              const SizedBox(height: 16),
              for (final fmt in const [
                ('txt', 'TXT · 纯文本'),
                ('epub', 'EPUB · 电子书'),
                ('pdf', 'PDF · 文档'),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _submitting
                        ? null
                        : () {
                            Navigator.pop(ctx);
                            _submit(book, fmt.$1);
                          },
                    icon: const Icon(Icons.download_outlined, size: 18),
                    label: Text(fmt.$2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppState.shared;
    return Scaffold(
      appBar: AppBar(title: const Text('搜索小说')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.search,
                    onSubmitted: _search,
                    style: TextStyle(fontSize: 14, color: M.text(app)),
                    decoration: InputDecoration(
                      hintText: '书名 / 分享链接 / 书籍 ID',
                      hintStyle: TextStyle(color: M.muted(app)),
                      isDense: true,
                      filled: true,
                      fillColor: M.card(app),
                      prefixIcon: Icon(Icons.search, size: 20, color: M.muted(app)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: M.border(app)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: M.border(app)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                  ),
                  onPressed: () => _search(_controller.text),
                  child: const Text('搜索'),
                ),
              ],
            ),
          ),
          if (_error != null)
            ErrorBanner(message: _error!, onRetry: () => _search(_controller.text)),
          Expanded(
            child: _loading
                ? const LoadingView(hint: '搜索中…')
                : _results.isEmpty
                    ? const EmptyView(text: '输入关键词开始搜索')
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final book = _results[i];
                          return MCard(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _BookCover(cover: book.cover, title: book.title),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        book.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w600,
                                          color: M.text(app),
                                        ),
                                      ),
                                      if (book.author != null &&
                                          book.author!.isNotEmpty) ...[
                                        const SizedBox(height: 3),
                                        Text(
                                          book.author!,
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: M.muted(app)),
                                        ),
                                      ],
                                      if (book.intro != null &&
                                          book.intro!.isNotEmpty) ...[
                                        const SizedBox(height: 5),
                                        Text(
                                          book.intro!,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: M.muted(app)),
                                        ),
                                      ],
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          OutlinedButton.icon(
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: AppColors.green,
                                              side: BorderSide(
                                                  color: AppColors.green
                                                      .withOpacity(0.6)),
                                              padding: const EdgeInsets
                                                  .symmetric(horizontal: 12),
                                              visualDensity: VisualDensity
                                                  .compact,
                                            ),
                                            onPressed: _submitting
                                                ? null
                                                : () => _preview(book),
                                            icon: const Icon(
                                                Icons.menu_book_outlined,
                                                size: 16),
                                            label: const Text('阅读'),
                                          ),
                                          const SizedBox(width: 8),
                                          OutlinedButton.icon(
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor:
                                                  AppColors.accent,
                                              side: BorderSide(
                                                  color: AppColors.accent
                                                      .withOpacity(0.6)),
                                              padding: const EdgeInsets
                                                  .symmetric(horizontal: 12),
                                              visualDensity: VisualDensity
                                                  .compact,
                                            ),
                                            onPressed: _submitting
                                                ? null
                                                : () =>
                                                    _showFormatSheet(book),
                                            icon: const Icon(
                                                Icons.download_outlined,
                                                size: 16),
                                            label: const Text('下载'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _BookCover extends StatelessWidget {
  final String? cover;
  final String title;

  const _BookCover({required this.cover, required this.title});

  @override
  Widget build(BuildContext context) {
    final app = AppState.shared;
    if (cover == null || cover!.isEmpty) {
      return Container(
        width: 52,
        height: 68,
        decoration: BoxDecoration(
          color: M.card(app),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: M.border(app)),
        ),
        child: Icon(Icons.menu_book, size: 24, color: M.muted(app)),
      );
    }
    final url = cover!.startsWith('http')
        ? cover!
        : 'https://morax.kdns.fr${cover!.startsWith('/') ? cover! : '/$cover'}';
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: url,
        width: 52,
        height: 68,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          width: 52,
          height: 68,
          color: M.card(app),
        ),
        errorWidget: (_, __, ___) => Container(
          width: 52,
          height: 68,
          color: M.card(app),
          child: Icon(Icons.menu_book, size: 24, color: M.muted(app)),
        ),
      ),
    );
  }
}
