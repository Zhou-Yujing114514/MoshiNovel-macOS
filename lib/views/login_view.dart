import 'package:flutter/material.dart';

import '../api_service.dart';
import '../app_state.dart';
import '../theme.dart';
import '../widgets.dart';

/// 登录 / 注册页
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _user = TextEditingController();
  final TextEditingController _pass = TextEditingController();
  bool _registerMode = false;
  bool _busy = false;
  String? _error;

  Future<void> _submit() async {
    final username = _user.text.trim();
    final password = _pass.text;
    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = '请输入用户名和密码');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final resp = _registerMode
          ? await ApiService.shared.register(username, password)
          : await ApiService.shared.login(username, password);
      if (resp.user == null) {
        setState(() {
          _busy = false;
          _error = resp.error ?? '操作失败';
        });
        return;
      }
      AppState.shared.setUser(resp.user);
      await AppState.shared.persistSession();
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppState.shared;
    return Scaffold(
      appBar: AppBar(title: Text(_registerMode ? '注册' : '登录')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            TextField(
              controller: _user,
              style: TextStyle(fontSize: 14, color: M.text(app)),
              decoration: InputDecoration(
                labelText: '用户名',
                filled: true,
                fillColor: M.card(app),
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
            const SizedBox(height: 14),
            TextField(
              controller: _pass,
              obscureText: true,
              style: TextStyle(fontSize: 14, color: M.text(app)),
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: '密码',
                filled: true,
                fillColor: M.card(app),
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
            if (_error != null) ...[
              const SizedBox(height: 12),
              ErrorBanner(message: _error!),
            ],
            const SizedBox(height: 20),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _busy ? null : _submit,
              child: Text(_busy ? '请稍候…' : (_registerMode ? '注册并登录' : '登录')),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => setState(() {
                        _registerMode = !_registerMode;
                        _error = null;
                      }),
              child: Text(_registerMode ? '已有账号？去登录' : '没有账号？去注册'),
            ),
          ],
        ),
      ),
    );
  }
}
