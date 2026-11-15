import 'package:flutter/material.dart';

import '../screens/cart_page.dart';
import '../state/cart_model.dart';
import 'rebuild_flash.dart';

/// Nút giỏ hàng trên AppBar.
/// - Nếu được truyền [count] (cách "Nâng lên cha"): chỉ hiển thị số cha đưa.
/// - Nếu không (cách "Chia sẻ"): tự lắng nghe CartModel bằng CartScope.watch,
///   nên khi giỏ đổi chỉ widget này build lại.
class CartBadgeButton extends StatelessWidget {
  const CartBadgeButton({super.key, this.count});
  final int? count;

  @override
  Widget build(BuildContext context) {
    final c = count ?? CartScope.watch(context).count;
    final n = BuildCounter.hit('CartBadge');
    return RebuildFlash(
      count: n,
      label: 'Badge',
      radius: 30,
      child: Padding(
        padding: const EdgeInsets.only(top: 6, right: 4),
        child: IconButton(
          tooltip: 'Giỏ hàng',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CartPage()),
            );
          },
          icon: Badge(
            isLabelVisible: c > 0,
            label: Text('$c'),
            child: const Icon(Icons.shopping_cart_outlined),
          ),
        ),
      ),
    );
  }
}
