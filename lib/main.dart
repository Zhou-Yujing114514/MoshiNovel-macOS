import 'package:flutter/material.dart';

import 'app_state.dart';
import 'api_service.dart';
import 'theme.dart';
import 'views/root_view.dart';
import 'widgets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MoshiApp());
}

class MoshiApp extends StatefulWidget {
  const MoshiApp({super.key});

  @override
  State<MoshiApp> createState() => _MoshiAppState();
}

class _MoshiAppState extends State<MoshiApp> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await AppState.shared.init();
    // 拉取站点配置（失败不阻塞）
    try {
      final cfg = await ApiService.shared.fetchSiteConfig();
      AppState.shared.siteConfig = cfg;
    } catch (_) {}
    if (!mounted) return;
    setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.shared,
      builder: (context, _) {
        return MaterialApp(
          title: '摩柿小说下载站',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.build(AppState.shared.isDayMode
              ? Brightness.light
              : Brightness.dark),
          home: _ready ? const RootView() : const _Splash(),
        );
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    final app = AppState.shared;
    return Scaffold(
      backgroundColor: M.bg(app),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book, size: 56, color: AppColors.accent),
            const SizedBox(height: 16),
            Text(
              '摩柿小说下载站',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: M.text(app),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'MoshiNovel',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 3,
                color: M.muted(app),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
