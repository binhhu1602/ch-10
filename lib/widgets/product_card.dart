import 'package:flutter/material.dart';

import '../screens/cart_page.dart';
import '../screens/product_detail_page.dart';
import '../state/app_settings.dart';
import '../state/cart_model.dart';
import 'like_button.dart';
import 'rebuild_flash.dart';

class ProductCard extends StatefulWidget {
  const ProductCard({super.key, required this.product, required this.mode});
  final Product product;
  final CartMode mode;

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  /// Chỉ dùng ở chế độ "Cục bộ": số lượng chỉ thẻ này biết.
  int _inCart = 0;
  late final String _id = 'card-${identityHashCode(this)}';

  void _add() {
    final p = widget.product;
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();

    if (widget.mode == CartMode.local) {
      setState(() => _inCart++);
      appLog.add(
        'ProductCard',
        'setState(_inCart = $_inCart) trong thẻ "${p.name}". Badge và giỏ hàng không biết!',
        kind: LogKind.warn,
      );
      messenger.showSnackBar(SnackBar(
        content: Text(
            'Thẻ "${p.name}" ghi nhận $_inCart, nhưng giỏ hàng vẫn trống (state cục bộ).'),
      ));
      return;
    }

    CartScope.read(context).add(p);
    appLog.add('ProductCard', 'CartModel.add("${p.name}") → notifyListeners()',
        kind: LogKind.setState);
    messenger.showSnackBar(SnackBar(
      content: Text('Đã thêm "${p.name}" vào giỏ'),
      action: SnackBarAction(
        label: 'Xem giỏ',
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const CartPage())),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final n = BuildCounter.hit(_id);
    final p = widget.product;
    final scheme = Theme.of(context).colorScheme;

    return RebuildFlash(
      count: n,
      label: 'Card',
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ProductDetailPage(product: p)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  color: p.color.withValues(alpha: 0.16),
                  child: Hero(
                    tag: 'product-${p.id}',
                    child: Icon(p.icon, size: 64, color: p.color),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(formatVnd(p.price),
                        style: TextStyle(
                            color: scheme.primary,
                            fontWeight: FontWeight.w700)),
                    if (widget.mode == CartMode.local)
                      Text('Thẻ này nhớ: $_inCart',
                          style: TextStyle(fontSize: 12, color: scheme.error)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 8, 6),
                child: Row(
                  children: [
                    LikeButton(productName: p.name),
                    const Spacer(),
                    IconButton.filledTonal(
                      tooltip: 'Thêm vào giỏ',
                      onPressed: _add,
                      icon: const Icon(Icons.add_shopping_cart, size: 20),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
