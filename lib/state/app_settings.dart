import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Ba cách quản lý state giỏ hàng để so sánh khi demo.
enum CartMode {
  shared(
    'Chia sẻ',
    'Giỏ hàng nằm trong CartModel ở gốc app. Chỉ widget lắng nghe (badge, '
        'trang giỏ hàng) build lại khi giỏ đổi.',
  ),
  lifted(
    'Nâng lên cha',
    'HomePage tự setState mỗi khi giỏ đổi rồi truyền số lượng xuống badge. '
        'Cả màn hình build lại, kể cả các thẻ sản phẩm không liên quan.',
  ),
  local(
    'Cục bộ',
    'Mỗi thẻ sản phẩm tự giữ số lượng bằng setState. Badge, trang chi tiết '
        'và trang giỏ hàng không biết gì về số lượng đó.',
  );

  const CartMode(this.label, this.description);
  final String label;
  final String description;
}

/// Cài đặt dùng chung toàn app: chế độ tối, cách quản lý giỏ, hiện số lần build.
class AppSettings extends ChangeNotifier {
  bool _dark = false;
  CartMode _mode = CartMode.shared;
  bool _showBuilds = true;

  bool get dark => _dark;
  set dark(bool v) {
    if (v == _dark) return;
    _dark = v;
    notifyListeners();
  }

  CartMode get mode => _mode;
  set mode(CartMode v) {
    if (v == _mode) return;
    _mode = v;
    notifyListeners();
  }

  bool get showBuilds => _showBuilds;
  set showBuilds(bool v) {
    if (v == _showBuilds) return;
    _showBuilds = v;
    notifyListeners();
  }
}

class SettingsScope extends InheritedNotifier<AppSettings> {
  const SettingsScope({
    super.key,
    required AppSettings super.notifier,
    required super.child,
  });

  static AppSettings watch(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SettingsScope>()!.notifier!;

  static AppSettings read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<SettingsScope>()!.notifier!;
}

// ======================= Nhật ký vòng đời =======================

enum LogKind { lifecycle, setState, build, warn }

class LogEntry {
  LogEntry(this.source, this.message, this.kind) : time = DateTime.now();
  final String source;
  final String message;
  final LogKind kind;
  final DateTime time;
}

/// Ghi lại các bước vòng đời và setState để xem trong Bảng demo.
/// Các phương thức vòng đời có thể chạy giữa lúc Flutter đang build,
/// nên việc báo cho giao diện được dời sang sau frame hiện tại.
class AppLog extends ChangeNotifier {
  static const _max = 300;
  final List<LogEntry> entries = [];
  bool _pending = false;

  void add(String source, String message, {LogKind kind = LogKind.lifecycle}) {
    debugPrint('[$source] $message');
    entries.add(LogEntry(source, message, kind));
    if (entries.length > _max) entries.removeAt(0);
    _notify();
  }

  void clear() {
    entries.clear();
    _notify();
  }

  void _notify() {
    final phase = SchedulerBinding.instance.schedulerPhase;
    final inFrame = phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks;
    if (!inFrame) {
      notifyListeners();
      return;
    }
    if (_pending) return;
    _pending = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _pending = false;
      notifyListeners();
    });
  }
}

final appLog = AppLog();
