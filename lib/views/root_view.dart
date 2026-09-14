import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'mine_view.dart';
import 'search_view.dart';
import 'tasks_view.dart';

/// 主框架：底部导航（搜索 / 任务 / 我的）
class RootView extends StatefulWidget {
  const RootView({super.key});

  @override
  State<RootView> createState() => _RootViewState();
}

class _RootViewState extends State<RootView> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final app = AppState.shared;
    final pages = const [SearchView(), TasksView(), MineView()];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        backgroundColor: M.card(app),
        indicatorColor: AppColors.accent.withOpacity(0.18),
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: '搜索',
          ),
          NavigationDestination(
            icon: Icon(Icons.download_outlined),
            selectedIcon: Icon(Icons.download),
            label: '任务',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }
}
