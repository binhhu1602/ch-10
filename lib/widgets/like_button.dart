import 'package:flutter/material.dart';

import '../state/app_settings.dart';
import 'rebuild_flash.dart';

/// STATE CỤC BỘ thuần: chỉ chính nút này cần biết đã thích hay chưa.
/// Mỗi LikeButton có State riêng, nên nút ở lưới sản phẩm và nút ở trang
/// chi tiết của cùng một sản phẩm KHÔNG đồng bộ với nhau.
class LikeButton extends StatefulWidget {
  const LikeButton({super.key, required this.productName, this.size = 22});
  final String productName;
  final double size;

  @override
  State<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton> {
  bool _liked = false;
  late final String _id = 'like-${identityHashCode(this)}';

  void _toggle() {
    setState(() => _liked = !_liked);
    appLog.add(
      'LikeButton',
      'setState(_liked = $_liked) cho "${widget.productName}" → chỉ nút này build lại',
      kind: LogKind.setState,
    );
  }

  @override
  Widget build(BuildContext context) {
    final n = BuildCounter.hit(_id);
    return RebuildFlash(
      count: n,
      label: 'Like',
      radius: 30,
      child: IconButton(
        tooltip: _liked ? 'Bỏ thích' : 'Thích',
        iconSize: widget.size,
        onPressed: _toggle,
        icon: Icon(
          _liked ? Icons.favorite : Icons.favorite_border,
          color: Colors.red,
        ),
      ),
    );
  }
}
