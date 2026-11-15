import 'package:flutter/material.dart';

import '../state/app_settings.dart';
import '../state/cart_model.dart';
import '../widgets/quantity_stepper.dart';
import '../widgets/rebuild_flash.dart';

/// Màn hình giỏ hàng: đọc CÙNG một CartModel với badge trên trang chủ.
/// Sửa số lượng ở đây thì badge cũng cập nhật theo.
class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool _paying = false;

  @override
  void initState() {
    super.initState();
    appLog.add('CartPage', 'initState() → mở giỏ hàng');
  }

  @override
  void dispose() {
    appLog.add('CartPage', 'dispose() → đóng giỏ hàng (dữ liệu vẫn còn trong CartModel)');
    super.dispose();
  }

  Future<void> _checkout(CartModel cart) async {
    final total = cart.total;
    setState(() => _paying = true);
    appLog.add('CartPage', 'Thanh toán: chờ 1.5 giây…', kind: LogKind.setState);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) {
      appLog.add('CartPage', 'mounted == false → bỏ qua setState', kind: LogKind.warn);
      return;
    }
    cart.clear();
    setState(() => _paying = false);
    appLog.add('CartPage', 'CartModel.clear() → badge về 0', kind: LogKind.setState);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 40),
        title: const Text('Đặt hàng thành công'),
        content: Text('Tổng thanh toán: ${formatVnd(total)}'),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = CartScope.watch(context); // lắng nghe giỏ hàng
    final mode = SettingsScope.read(context).mode;
    final n = BuildCounter.hit('cart-${identityHashCode(this)}');
    final scheme = Theme.of(context).colorScheme;
    final items = cart.items;

    return Scaffold(
      appBar: AppBar(title: Text('Giỏ hàng (${cart.count})')),
      body: RebuildFlash(
        count: n,
        label: 'CartPage',
        radius: 0,
        child: items.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.remove_shopping_cart_outlined,
                          size: 64, color: scheme.outline),
                      const SizedBox(height: 12),
                      const Text('Giỏ hàng đang trống',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      if (mode == CartMode.local) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Cách "Cục bộ": số lượng nằm trong từng thẻ sản phẩm nên trang giỏ hàng không đọc được.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: scheme.error),
                        ),
                      ],
                    ],
                  ),
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const Divider(height: 20),
                      itemBuilder: (context, i) {
                        final (p, q) = items[i];
                        return Row(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: p.color.withValues(alpha: 0.16),
                              child: Icon(p.icon, color: p.color),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  Text(formatVnd(p.price * q),
                                      style: TextStyle(color: scheme.primary)),
                                ],
                              ),
                            ),
                            QuantityStepper(
                              value: q,
                              min: 0,
                              onChanged: (v) {
                                cart.setQty(p, v);
                                appLog.add('CartPage',
                                    'CartModel.setQty("${p.name}", $v)',
                                    kind: LogKind.setState);
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: scheme.outlineVariant)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Tổng cộng',
                                    style: TextStyle(color: scheme.onSurfaceVariant)),
                                Text(formatVnd(cart.total),
                                    style: const TextStyle(
                                        fontSize: 20, fontWeight: FontWeight.w800)),
                              ],
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: _paying ? null : () => _checkout(cart),
                            icon: _paying
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.payment),
                            label: Text(_paying ? 'Đang thanh toán…' : 'Thanh toán'),
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
