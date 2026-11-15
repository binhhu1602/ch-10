import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../state/app_settings.dart';
import '../state/cart_model.dart';
import 'rebuild_flash.dart';

/// Bảng điều khiển dùng khi thuyết trình: đổi cách quản lý giỏ hàng,
/// bật/tắt lớp phủ số lần build và xem nhật ký vòng đời.
class DemoDrawer extends StatelessWidget {
  const DemoDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsScope.watch(context);
    final scheme = Theme.of(context).colorScheme;
    final width = math.min(400.0, MediaQuery.sizeOf(context).width * 0.92);

    return Drawer(
      width: width,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Bảng demo',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              Text('Cách quản lý giỏ hàng',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              SegmentedButton<CartMode>(
                showSelectedIcon: false,
                segments: [
                  for (final m in CartMode.values)
                    ButtonSegment(value: m, label: Text(m.label)),
                ],
                selected: {settings.mode},
                onSelectionChanged: (s) {
                  final m = s.first;
                  CartScope.read(context).clear();
                  BuildCounter.reset();
                  appLog.add('Demo', '— Đổi sang cách "${m.label}", xóa giỏ hàng —',
                      kind: LogKind.warn);
                  settings.mode = m;
                },
              ),
              const SizedBox(height: 8),
              Text(settings.mode.description,
                  style: const TextStyle(fontSize: 13, height: 1.45)),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Hiện số lần build'),
                subtitle: const Text('Khung nháy cam = widget vừa build lại'),
                value: settings.showBuilds,
                onChanged: (v) => settings.showBuilds = v,
              ),
              const Divider(),
              Row(
                children: [
                  Expanded(
                    child: Text('Nhật ký vòng đời & setState',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurfaceVariant)),
                  ),
                  TextButton(onPressed: appLog.clear, child: const Text('Xóa')),
                ],
              ),
              const SizedBox(height: 6),
              Expanded(
                child: ListenableBuilder(
                  listenable: appLog,
                  builder: (context, _) => _LogView(entries: appLog.entries),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogView extends StatelessWidget {
  const _LogView({required this.entries});
  final List<LogEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0E1828),
        borderRadius: BorderRadius.circular(10),
      ),
      child: entries.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Chưa có sự kiện. Hãy mở một sản phẩm, bấm tim hoặc thêm vào giỏ.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF7D8EA5)),
                ),
              ),
            )
          : ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(10),
              itemCount: entries.length,
              itemBuilder: (context, i) {
                final e = entries[entries.length - 1 - i];
                final color = switch (e.kind) {
                  LogKind.lifecycle => const Color(0xFF7FB8FF),
                  LogKind.setState => const Color(0xFFD7E2EF),
                  LogKind.build => const Color(0xFF9FDC9C),
                  LogKind.warn => const Color(0xFFFFA07A),
                };
                final t = '${e.time.minute.toString().padLeft(2, '0')}:'
                    '${e.time.second.toString().padLeft(2, '0')}';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(
                          text: '$t ',
                          style: const TextStyle(color: Color(0xFF7D8EA5))),
                      TextSpan(
                          text: '${e.source}: ',
                          style: TextStyle(
                              color: color, fontWeight: FontWeight.w700)),
                      TextSpan(text: e.message, style: TextStyle(color: color)),
                    ]),
                    style: const TextStyle(fontSize: 12, height: 1.4),
                  ),
                );
              },
            ),
    );
  }
}
