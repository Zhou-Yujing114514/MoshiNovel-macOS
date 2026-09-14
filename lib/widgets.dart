import 'package:flutter/material.dart';

import 'app_state.dart';
import 'theme.dart';

/// 主题辅助：根据日/夜模式取色
class M {
  static Color bg(AppState s) => s.isDayMode ? AppColors.dayBg : AppColors.bg;
  static Color card(AppState s) =>
      s.isDayMode ? AppColors.dayCard : AppColors.card;
  static Color border(AppState s) =>
      s.isDayMode ? AppColors.dayBorder : AppColors.border;
  static Color text(AppState s) =>
      s.isDayMode ? AppColors.dayText : AppColors.text;
  static Color muted(AppState s) =>
      s.isDayMode ? AppColors.dayMuted : AppColors.muted;
}

/// 通用卡片容器
class MCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const MCard({super.key, required this.child, this.padding, this.onTap});

  @override
  Widget build(BuildContext context) {
    final app = AppState.shared;
    return Material(
      color: M.card(app),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: M.border(app)),
          ),
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}

/// 页面加载指示
class LoadingView extends StatelessWidget {
  final String? hint;
  const LoadingView({super.key, this.hint});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (hint != null) ...[
            const SizedBox(height: 12),
            Text(hint!, style: const TextStyle(fontSize: 13)),
          ],
        ],
      ),
    );
  }
}

/// 空状态
class EmptyView extends StatelessWidget {
  final String text;
  const EmptyView({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          text,
          style: TextStyle(fontSize: 13, color: M.muted(AppState.shared)),
        ),
      ),
    );
  }
}

/// 错误提示条
class ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorBanner({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final app = AppState.shared;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.red.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 16, color: AppColors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 12.5, color: M.text(app)),
            ),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}

/// 状态徽标
class StatusChip extends StatelessWidget {
  final String text;
  final Color color;
  const StatusChip({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, color: color)),
    );
  }
}
