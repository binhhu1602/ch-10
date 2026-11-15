import 'package:flutter/material.dart';

import '../state/app_settings.dart';
import '../state/cart_model.dart';
import '../widgets/cart_badge.dart';
import '../widgets/demo_drawer.dart';
import '../widgets/like_button.dart';
import '../widgets/quantity_stepper.dart';
import '../widgets/rebuild_flash.dart';
import 'cart_page.dart';

/// Màn hình chi tiết: ghi log đầy đủ vòng đời của State.
/// Mở trang → initState, didChangeDependencies, build.
/// Quay lại → deactivate, dispose (số lượng đang chọn mất theo).
class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({super.key, required this.product});
  final Product product;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _qty = 1; // state cục bộ của trang
  bool _buying = false;

  String get _name => widget.product.name;

  @override
  void initState() {
    super.initState();
    appLog.add('ProductDetail', 'initState() → mở trang "$_name", _qty = 1');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    appLog.add('ProductDetail',
        'didChangeDependencies() → Theme/CartScope/Settings sẵn sàng hoặc vừa đổi');
  }

  @override
  void didUpdateWidget(covariant ProductDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    appLog.add('ProductDetail', 'didUpdateWidget() → State giữ nguyên _qty = $_qty');
  }

  @override
  void deactivate() {
    appLog.add('ProductDetail', 'deactivate() → gỡ khỏi cây');
    super.deactivate();
  }

  @override
  void dispose() {
    appLog.add('ProductDetail', 'dispose() → trang "$_name" bị hủy, _qty = $_qty mất theo');
    super.dispose();
  }

  void _changeQty(int v) {
    setState(() => _qty = v);
    appLog.add('ProductDetail', 'setState(_qty = $v)', kind: LogKind.setState);
  }

  bool _addToCart() {
    final mode = SettingsScope.read(context).mode;
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    if (mode == CartMode.local) {
      appLog.add('ProductDetail',
          'Cách "Cục bộ": trang chi tiết không truy cập được số lượng trong ProductCard',
          kind: LogKind.warn);
      messenger.showSnackBar(const SnackBar(
        content: Text(
            'Cách "Cục bộ": không có giỏ hàng chung để thêm vào. Đây là giới hạn của state cục bộ.'),
      ));
      return false;
    }
    CartScope.read(context).add(widget.product, _qty);
    appLog.add('ProductDetail', 'CartModel.add("$_name", $_qty) → notifyListeners()',
        kind: LogKind.setState);
    messenger.showSnackBar(SnackBar(content: Text('Đã thêm $_qty × "$_name" vào giỏ')));
    return true;
  }

  /// Giả lập gọi API thanh toán 2 giây. Nếu người dùng bấm quay lại trong
  /// lúc chờ, State đã dispose → phải kiểm tra mounted trước khi setState.
  Future<void> _buyNow() async {
    setState(() => _buying = true);
    appLog.add('ProductDetail', 'Mua ngay: chờ 2 giây (giả lập gọi API)…',
        kind: LogKind.setState);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) {
      appLog.add('ProductDetail',
          'API trả về nhưng mounted == false → bỏ qua setState. Nếu gọi sẽ lỗi "setState() called after dispose()".',
          kind: LogKind.warn);
      return;
    }
    setState(() => _buying = false);
    if (_addToCart()) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CartPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = BuildCounter.hit('detail-${identityHashCode(this)}');
    appLog.add('ProductDetail', 'build() → _qty = $_qty', kind: LogKind.build);
    final p = widget.product;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      endDrawer: const DemoDrawer(),
      appBar: AppBar(
        title: Text(p.name),
        actions: [
          const CartBadgeButton(),
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
        label: 'DetailPage',
        radius: 0,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: 220,
                      decoration: BoxDecoration(
                        color: p.color.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Hero(
                        tag: 'product-${p.id}',
                        child: Icon(p.icon, size: 110, color: p.color),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: Text(p.name,
                              style: text.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w800)),
                        ),
                        LikeButton(productName: p.name, size: 28),
                      ],
                    ),
                    Text(p.category,
                        style: TextStyle(color: scheme.onSurfaceVariant)),
                    const SizedBox(height: 10),
                    Text(formatVnd(p.price),
                        style: text.titleLarge?.copyWith(
                            color: scheme.primary, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    Text(p.description, style: const TextStyle(height: 1.5)),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        const Text('Số lượng',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const Spacer(),
                        QuantityStepper(value: _qty, onChanged: _changeQty),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text('Tạm tính: ${formatVnd(p.price * _qty)}',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _buying ? null : _addToCart,
                            icon: const Icon(Icons.add_shopping_cart),
                            label: const Text('Thêm vào giỏ'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _buying ? null : _buyNow,
                            icon: _buying
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : const Icon(Icons.flash_on),
                            label: Text(_buying ? 'Đang xử lý…' : 'Mua ngay'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
