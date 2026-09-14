import 'package:flutter/material.dart';

import '../api_service.dart';
import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'login_view.dart';

/// 我的页：用户信息、登录/注册、日夜间切换、管理员面板
class MineView extends StatefulWidget {
  const MineView({super.key});

  @override
  State<MineView> createState() => _MineViewState();
}

class _MineViewState extends State<MineView> {
  bool _adminLoading = false;
  String? _adminError;
  AdminInfo? _adminInfo;
  List<User> _users = [];

  @override
  void initState() {
    super.initState();
    _loadAdmin();
  }

  Future<void> _loadAdmin() async {
    final app = AppState.shared;
    if (app.currentUser?.isAdmin != true) return;
    setState(() {
      _adminLoading = true;
      _adminError = null;
    });
    try {
      final info = await ApiService.shared.fetchAdminInfo();
      final users = await ApiService.shared.fetchUsers();
      if (!mounted) return;
      setState(() {
        _adminInfo = info;
        _users = users;
        _adminLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _adminLoading = false;
        _adminError = e.toString();
      });
    }
  }

  Future<void> _logout() async {
    await ApiService.shared.logout();
    AppState.shared.setUser(null);
    await AppState.shared.persistSession();
    if (mounted) setState(() {});
  }

  void _showAdminPanel() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const _AdminPanel()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppState.shared;
    final user = app.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 用户卡片
          MCard(
            child: user == null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('未登录',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: M.text(app))),
                      const SizedBox(height: 6),
                      Text('登录后即可查看我的提取任务',
                          style:
                              TextStyle(fontSize: 12.5, color: M.muted(app))),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent,
                        ),
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const LoginView()),
                          );
                          if (mounted) setState(() {});
                          _loadAdmin();
                        },
                        icon: const Icon(Icons.login, size: 18),
                        label: const Text('登录 / 注册'),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor:
                                AppColors.accent.withOpacity(0.18),
                            child: Text(
                              user.username.isNotEmpty
                                  ? user.username[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.username,
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: M.text(app)),
                                ),
                                if (user.title != null &&
                                    user.title!.isNotEmpty)
                                  Text(user.title!,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: M.muted(app))),
                                Text(
                                  [
                                    if (user.isAdmin == true) '管理员',
                                    if (user.highRank == true) '高权限',
                                    if (user.isAdmin != true &&
                                        user.highRank != true)
                                      '普通用户',
                                  ].join(' · '),
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.green),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.red,
                              side: BorderSide(
                                  color: AppColors.red.withOpacity(0.6)),
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: _logout,
                            child: const Text('退出登录'),
                          ),
                        ],
                      ),
                      if (user.isAdmin == true) ...[
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.amber,
                            side: BorderSide(
                                color: AppColors.amber.withOpacity(0.6)),
                          ),
                          onPressed: _showAdminPanel,
                          icon: const Icon(Icons.admin_panel_settings_outlined,
                              size: 18),
                          label: const Text('站长管理'),
                        ),
                      ],
                    ],
                  ),
          ),
          const SizedBox(height: 14),
          // 设置卡片
          MCard(
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('日间模式',
                      style: TextStyle(
                          fontSize: 14, color: M.text(app))),
                  subtitle: Text('切换亮色 / 暗色主题',
                      style: TextStyle(
                          fontSize: 12, color: M.muted(app))),
                  value: app.isDayMode,
                  activeTrackColor: AppColors.accent,
                  onChanged: (_) => app.toggleDayMode(),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.info_outline, size: 20),
                  title: Text('站点信息',
                      style: TextStyle(
                          fontSize: 14, color: M.text(app))),
                  subtitle: Text(
                    _siteInfoText(),
                    style: TextStyle(fontSize: 12, color: M.muted(app)),
                  ),
                  onTap: _showSiteInfo,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _siteInfoText() {
    final cfg = AppState.shared.siteConfig;
    if (cfg == null) return '加载中…';
    final parts = <String>[
      if (cfg.siteTitle != null) cfg.siteTitle!,
      if (cfg.siteVersion != null) 'v${cfg.siteVersion}',
      if (cfg.siteOwner != null) cfg.siteOwner!,
    ];
    return parts.isEmpty ? '摩柿小说下载站' : parts.join(' · ');
  }

  void _showSiteInfo() {
    final cfg = AppState.shared.siteConfig;
    if (cfg == null) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('站点信息'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (cfg.siteTitle != null) Text('名称：${cfg.siteTitle}'),
            if (cfg.siteVersion != null) Text('版本：${cfg.siteVersion}'),
            if (cfg.siteOwner != null) Text('站长：${cfg.siteOwner}'),
            if (cfg.siteNotice != null) Text('公告：${cfg.siteNotice}'),
            if (cfg.disabled == true) const Text('状态：已禁用'),
            if (cfg.maintenance == true) const Text('状态：维护中'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('好的')),
        ],
      ),
    );
  }
}

/// 站长管理面板
class _AdminPanel extends StatefulWidget {
  const _AdminPanel();

  @override
  State<_AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<_AdminPanel> {
  bool _loading = true;
  String? _error;
  AdminInfo? _info;
  AdminSettings? _settings;
  List<User> _users = [];

  // 设置表单控制器
  final _titleCtrl = TextEditingController();
  final _ownerCtrl = TextEditingController();
  final _noticeCtrl = TextEditingController();
  final _versionCtrl = TextEditingController();
  final _maxQueueCtrl = TextEditingController();
  final _ttlCtrl = TextEditingController();
  bool _disabled = false;
  bool _maintenance = false;
  bool _saving = false;

  // 新建用户
  final _newUserCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _ownerCtrl.dispose();
    _noticeCtrl.dispose();
    _versionCtrl.dispose();
    _maxQueueCtrl.dispose();
    _ttlCtrl.dispose();
    _newUserCtrl.dispose();
    _newPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final info = await ApiService.shared.fetchAdminInfo();
      final settings = await ApiService.shared.fetchAdminSettings();
      final users = await ApiService.shared.fetchUsers();
      if (!mounted) return;
      _titleCtrl.text = settings.siteTitle ?? '';
      _ownerCtrl.text = settings.siteOwner ?? '';
      _noticeCtrl.text = settings.siteNotice ?? '';
      _versionCtrl.text = settings.siteVersion ?? '';
      _maxQueueCtrl.text = (settings.maxQueueLen ?? info.maxQueueLen ?? 50).toString();
      _ttlCtrl.text = (settings.downloadTtlHours ?? info.downloadTtlHours ?? 24).toString();
      _disabled = settings.disabled ?? false;
      _maintenance = settings.maintenance ?? false;
      setState(() {
        _info = info;
        _settings = settings;
        _users = users;
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

  Future<void> _saveSettings() async {
    setState(() => _saving = true);
    try {
      await ApiService.shared.saveAdminSettings({
        'site_title': _titleCtrl.text.trim(),
        'site_owner': _ownerCtrl.text.trim(),
        'site_notice': _noticeCtrl.text.trim(),
        'site_version': _versionCtrl.text.trim(),
        'max_queue_len': int.tryParse(_maxQueueCtrl.text.trim()) ?? 50,
        'download_ttl_hours': int.tryParse(_ttlCtrl.text.trim()) ?? 24,
        'disabled': _disabled,
        'maintenance': _maintenance,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('设置已保存')),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _createUser() async {
    final u = _newUserCtrl.text.trim();
    final p = _newPassCtrl.text;
    if (u.isEmpty || p.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入用户名和密码')),
      );
      return;
    }
    try {
      await ApiService.shared.createUser(u, p);
      _newUserCtrl.clear();
      _newPassCtrl.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已创建用户 $u')),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('创建失败: $e')),
      );
    }
  }

  Future<void> _setTitle(User u) async {
    final ctrl = TextEditingController(text: u.title ?? '');
    final newTitle = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('设置 ${u.username} 的头衔'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: '例如：站长'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('保存')),
        ],
      ),
    );
    if (newTitle == null) return;
    try {
      await ApiService.shared.setUserTitle(u.username, newTitle);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('设置失败: $e')),
      );
    }
  }

  Future<void> _resetPassword(User u) async {
    final ctrl = TextEditingController();
    final newPass = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('重置 ${u.username} 的密码'),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          decoration: const InputDecoration(hintText: '新密码'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: const Text('重置')),
        ],
      ),
    );
    if (newPass == null || newPass.isEmpty) return;
    try {
      await ApiService.shared.setUserPassword(u.username, newPass);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('密码已重置')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('重置失败: $e')),
      );
    }
  }

  Future<void> _deleteUser(User u) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除用户'),
        content: Text('确定删除用户 ${u.username} 吗？此操作不可恢复。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('删除')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiService.shared.deleteUser(u.username);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除失败: $e')),
      );
    }
  }

  Future<void> _clearRecords() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清空记录'),
        content: const Text('确定清空全部任务记录吗？此操作不可恢复。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('清空')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiService.shared.clearRecords();
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('清空失败: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppState.shared;
    final info = _info;
    return Scaffold(
      appBar: AppBar(title: const Text('站长管理')),
      body: _loading
          ? const LoadingView(hint: '加载管理数据…')
          : _error != null
              ? Center(
                  child: ErrorBanner(
                      message: _error!, onRetry: _load))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // 站点概览
                    MCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('站点概览',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: M.text(app))),
                          const SizedBox(height: 10),
                          _kv('任务总数', '${info?.tasks ?? '-'}'),
                          _kv('排队中', '${info?.queued ?? '-'}'),
                          _kv('下载中', '${info?.running ?? '-'}'),
                          _kv('用户数', '${info?.users ?? '-'}'),
                          _kv('队列上限', '${info?.maxQueueLen ?? '-'}'),
                          _kv('限流', '${info?.rateLimitPerIp ?? '-'} 次/${info?.rateLimitWindowMin ?? '-'} 分钟'),
                          _kv('下载保留', '${info?.downloadTtlHours ?? '-'} 小时'),
                          if (info?.tomatoAddr != null)
                            _kv('番茄地址', info!.tomatoAddr!),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    // 站点设置
                    MCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('站点设置',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: M.text(app))),
                          const SizedBox(height: 12),
                          _field(_titleCtrl, '站点名称'),
                          _field(_ownerCtrl, '站长'),
                          _field(_noticeCtrl, '公告'),
                          _field(_versionCtrl, '版本号'),
                          _field(_maxQueueCtrl, '队列上限', numeric: true),
                          _field(_ttlCtrl, '下载保留小时数', numeric: true),
                          const SizedBox(height: 6),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('禁用站点'),
                            value: _disabled,
                            onChanged: (v) =>
                                setState(() => _disabled = v ?? false),
                          ),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('维护模式'),
                            value: _maintenance,
                            onChanged: (v) =>
                                setState(() => _maintenance = v ?? false),
                          ),
                          const SizedBox(height: 8),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.accent,
                            ),
                            onPressed: _saving ? null : _saveSettings,
                            icon: const Icon(Icons.save_outlined, size: 18),
                            label: Text(_saving ? '保存中…' : '保存设置'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    // 用户管理
                    MCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('用户管理',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: M.text(app))),
                          const SizedBox(height: 10),
                          for (final u in _users)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              leading: CircleAvatar(
                                radius: 14,
                                backgroundColor:
                                    AppColors.accent.withOpacity(0.15),
                                child: Text(
                                  u.username.isNotEmpty
                                      ? u.username[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                      fontSize: 12, color: AppColors.accent),
                                ),
                              ),
                              title: Text(u.username,
                                  style: TextStyle(
                                      fontSize: 14, color: M.text(app))),
                              subtitle: Text(
                                [
                                  u.title ?? '',
                                  u.isAdmin == true ? '管理员' : '',
                                  u.highRank == true ? '高权限' : '',
                                ].where((s) => s.isNotEmpty).join(' · '),
                                style: TextStyle(
                                    fontSize: 12, color: M.muted(app)),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: '设头衔',
                                    icon: const Icon(Icons.edit_outlined,
                                        size: 18),
                                    onPressed: () => _setTitle(u),
                                  ),
                                  IconButton(
                                    tooltip: '重置密码',
                                    icon: const Icon(Icons.password_outlined,
                                        size: 18),
                                    onPressed: () => _resetPassword(u),
                                  ),
                                  IconButton(
                                    tooltip: '删除',
                                    icon: Icon(Icons.delete_outline,
                                        size: 18, color: AppColors.red),
                                    onPressed: () => _deleteUser(u),
                                  ),
                                ],
                              ),
                            ),
                          const Divider(height: 20),
                          Text('新建用户',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: M.text(app))),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _newUserCtrl,
                                  style: TextStyle(
                                      fontSize: 13, color: M.text(app)),
                                  decoration: InputDecoration(
                                    hintText: '用户名',
                                    isDense: true,
                                    filled: true,
                                    fillColor: M.card(app),
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _newPassCtrl,
                                  obscureText: true,
                                  style: TextStyle(
                                      fontSize: 13, color: M.text(app)),
                                  decoration: InputDecoration(
                                    hintText: '密码',
                                    isDense: true,
                                    filled: true,
                                    fillColor: M.card(app),
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton.filled(
                                tooltip: '创建',
                                icon: const Icon(Icons.add, size: 20),
                                onPressed: _createUser,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.red,
                        side: BorderSide(
                            color: AppColors.red.withOpacity(0.6)),
                      ),
                      onPressed: _clearRecords,
                      icon: const Icon(Icons.cleaning_services_outlined,
                          size: 18),
                      label: const Text('清空全部任务记录'),
                    ),
                  ],
                ),
    );
  }

  Widget _kv(String k, String v) {
    final app = AppState.shared;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
              width: 90,
              child: Text(k,
                  style: TextStyle(fontSize: 12.5, color: M.muted(app)))),
          Expanded(
            child: Text(v,
                style: TextStyle(fontSize: 12.5, color: M.text(app))),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label,
      {bool numeric = false}) {
    final app = AppState.shared;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        keyboardType: numeric ? TextInputType.number : TextInputType.text,
        style: TextStyle(fontSize: 13, color: M.text(app)),
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          filled: true,
          fillColor: M.card(app),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: M.border(app)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: M.border(app)),
          ),
        ),
      ),
    );
  }
}
