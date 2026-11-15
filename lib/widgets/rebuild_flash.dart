import 'package:flutter/material.dart';

import '../state/app_settings.dart';

/// Đếm số lần build() thật của từng widget.
class BuildCounter {
  static final Map<String, int> _counts = {};
  static int hit(String id) => _counts[id] = (_counts[id] ?? 0) + 1;
  static void reset() => _counts.clear();
}

/// Lớp phủ để quan sát cập nhật giao diện: viền nháy cam mỗi khi widget vừa
/// build lại, kèm nhãn "tên ×n". Bật/tắt trong Bảng demo.
/// Luôn dùng Stack để bật/tắt lớp phủ không làm thay đổi cấu trúc cây.
class RebuildFlash extends StatelessWidget {
  const RebuildFlash({
    super.key,
    required this.count,
    required this.label,
    required this.child,
    this.radius = 12,
  });

  final int count;
  final String label;
  final Widget child;
  final double radius;

  static const flash = Color(0xFFF2A516);

  @override
  Widget build(BuildContext context) {
    final show = SettingsScope.watch(context).showBuilds;
    return Stack(
      children: [
        child,
        if (show) ...[
          Positioned.fill(
            child: IgnorePointer(
              child: TweenAnimationBuilder<double>(
                key: ValueKey(count),
                tween: Tween(begin: 1, end: 0),
                duration: const Duration(milliseconds: 900),
                builder: (context, t, _) => DecoratedBox(
                  decoration: BoxDecoration(
                    color: flash.withValues(alpha: 0.22 * t),
                    border: Border.all(
                      color: flash.withValues(alpha: 0.3 + 0.7 * t),
                      width: 1 + 1.5 * t,
                    ),
                    borderRadius: BorderRadius.circular(radius),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 3,
            right: 3,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xEE3A2A00),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$label ×$count',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFFD27A),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
