import 'package:flutter/material.dart';

import '../state/app_settings.dart';
import '../state/cart_model.dart';
import '../widgets/cart_badge.dart';
import '../widgets/demo_drawer.dart';
import '../widgets/product_card.dart';
import '../widgets/rebuild_flash.dart';

/// Đọc cách quản lý giỏ hàng hiện tại và tạo HomePage tương ứng.
/// Key theo mode: đổi mode thì HomePage cũ bị dispose, tạo mới từ đầu.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    final mode = SettingsScope.watch(context).mode;
    return HomePage(key: ValueKey(mode), mode: mode);
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.mode});
  final CartMode mode;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // State cục bộ của màn hình: ô tìm kiếm và danh mục đang chọn.
  final _search = TextEditingController();
  String _query = '';
  String _category = categories.first;

  // Chỉ dùng ở cách "Nâng lên cha": màn hình tự lắng nghe giỏ hàng.
  CartModel? _listenedCart;

  @override
  void initState() {
    super.initState();
    appLog.add('HomePage', 'initState() → tạo TextEditingController');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.mode == CartMode.lifted && _listenedCart == null) {
      _listenedCart = CartScope.read(context)..addListener(_onCartChanged);
      appLog.add('HomePage',
          'didChangeDependencies() → đăng ký lắng nghe CartModel (state nâng lên màn hình cha)');
    }
  }

  void _onCartChanged() {
    if (!mounted) return;
    appLog.add('HomePage',
        'setState() vì giỏ hàng đổi → build lại CẢ màn hình', kind: LogKind.warn);
    setState(() {});
  }

  @override
  void dispose() {
    _listenedCart?.removeListener(_onCartChanged);
    _search.dispose();
    appLog.add('HomePage', 'dispose() → hủy controller, bỏ lắng nghe');
    super.dispose();
  }

  void _setQuery(String v) {
    setState(() => _query = v);
    appLog.add('HomePage', 'setState(_query = "$v")', kind: LogKind.setState);
  }

  void _setCategory(String c) {
    setState(() => _category = c);
    appLog.add('HomePage', 'setState(_category = "$c")', kind: LogKind.setState);
  }

  @override
  Widget build(BuildContext context) {
    final n = BuildCounter.hit('HomePage');
    final scheme = Theme.of(context).colorScheme;
    final q = _query.trim().toLowerCase();
    final shown = products
        .where((p) => _category == categories.first || p.category == _category)
        .where((p) => q.isEmpty || p.name.toLowerCase().contains(q))
        .toList();

    return Scaffold(
      endDrawer: const DemoDrawer(),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.storefront, color: scheme.primary),
            const SizedBox(width: 8),
            const Flexible(
              child: Text('Mini Shop',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
        actions: [
          const _DarkToggle(),
          CartBadgeButton(
            // Cách "Nâng lên cha": HomePage đọc số lượng rồi truyền xuống.
            // Cách khác: để badge tự lắng nghe CartModel.
            count: widget.mode == CartMode.lifted
                ? CartScope.read(context).count
                : null,
          ),
          Builder(
            builder: (context) => IconButton(
              tooltip: 'Bảng demo',
              onPressed: () => Scaffold.of(context).openEndDrawer(),
              icon: const Icon(Icons.tune),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RebuildFlash(
        count: n,
        label: 'HomePage',
        radius: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.mode != CartMode.shared)
              Container(
                color: widget.mode == CartMode.local
                    ? scheme.errorContainer
                    : scheme.tertiaryContainer,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text(
                  'Đang demo cách "${widget.mode.label}": ${widget.mode.description}',
                  style: TextStyle(
                    fontSize: 13,
                    color: widget.mode == CartMode.local
                        ? scheme.onErrorContainer
                        : scheme.onTertiaryContainer,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: TextField(
                controller: _search,
                onChanged: _setQuery,
                decoration: InputDecoration(
                  hintText: 'Tìm sản phẩm…',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Xóa',
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _search.clear();
                            _setQuery('');
                          },
                        ),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  for (final c in categories)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(c),
                        selected: c == _category,
                        onSelected: (_) => _setCategory(c),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: shown.isEmpty
                  ? const Center(child: Text('Không tìm thấy sản phẩm phù hợp'))
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 230,
                        mainAxisExtent: 262,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: shown.length,
                      itemBuilder: (context, i) => ProductCard(
                        key: ValueKey(shown[i].id),
                        product: shown[i],
                        mode: widget.mode,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DarkToggle extends StatelessWidget {
  const _DarkToggle();

  @override
  Widget build(BuildContext context) {
    final settings = SettingsScope.watch(context);
    return IconButton(
      tooltip: settings.dark ? 'Giao diện sáng' : 'Giao diện tối',
      onPressed: () => settings.dark = !settings.dark,
      icon: Icon(settings.dark ? Icons.light_mode : Icons.dark_mode),
    );
  }
}
