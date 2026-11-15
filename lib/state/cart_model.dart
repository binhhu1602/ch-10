import 'package:flutter/material.dart';

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.icon,
    required this.color,
    required this.description,
  });

  final String id;
  final String name;
  final String category;
  final int price;
  final IconData icon;
  final Color color;
  final String description;
}

const categories = ['Tất cả', 'Áo', 'Giày dép', 'Phụ kiện'];

const products = [
  Product(
    id: 'ao-thun',
    name: 'Áo thun basic',
    category: 'Áo',
    price: 159000,
    icon: Icons.checkroom,
    color: Color(0xFF4F86C6),
    description: 'Cotton 100%, form rộng, thấm hút mồ hôi tốt.',
  ),
  Product(
    id: 'ao-khoac',
    name: 'Áo khoác gió',
    category: 'Áo',
    price: 450000,
    icon: Icons.dry_cleaning,
    color: Color(0xFF3E9C8F),
    description: 'Chống nước nhẹ, có mũ trùm, gấp gọn được.',
  ),
  Product(
    id: 'so-mi',
    name: 'Áo sơ mi',
    category: 'Áo',
    price: 320000,
    icon: Icons.checkroom_outlined,
    color: Color(0xFF8A6FBF),
    description: 'Vải kate ít nhăn, phù hợp đi học và đi làm.',
  ),
  Product(
    id: 'giay',
    name: 'Giày thể thao',
    category: 'Giày dép',
    price: 890000,
    icon: Icons.directions_run,
    color: Color(0xFFE0703A),
    description: 'Đế êm, nhẹ, phù hợp chạy bộ và đi bộ hằng ngày.',
  ),
  Product(
    id: 'dep',
    name: 'Dép quai ngang',
    category: 'Giày dép',
    price: 120000,
    icon: Icons.beach_access,
    color: Color(0xFFD4A72C),
    description: 'Cao su đúc nguyên khối, chống trơn trượt.',
  ),
  Product(
    id: 'balo',
    name: 'Balo laptop',
    category: 'Phụ kiện',
    price: 420000,
    icon: Icons.backpack,
    color: Color(0xFF5C6B7A),
    description: 'Ngăn chống sốc cho laptop 15.6 inch, có cổng sạc USB.',
  ),
  Product(
    id: 'mu',
    name: 'Mũ lưỡi trai',
    category: 'Phụ kiện',
    price: 99000,
    icon: Icons.sports_baseball,
    color: Color(0xFFC0504D),
    description: 'Khóa điều chỉnh phía sau, vải kaki thoáng khí.',
  ),
  Product(
    id: 'binh-nuoc',
    name: 'Bình nước giữ nhiệt',
    category: 'Phụ kiện',
    price: 150000,
    icon: Icons.local_drink,
    color: Color(0xFF2F8FB8),
    description: 'Inox 304, giữ lạnh 12 giờ, dung tích 500ml.',
  ),
];

Product productById(String id) => products.firstWhere((p) => p.id == id);

String formatVnd(int v) {
  final s = v.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return '$b đ';
}

/// STATE CHIA SẺ: giỏ hàng.
/// Tách khỏi giao diện; khi dữ liệu đổi thì notifyListeners() để báo
/// cho những widget đang lắng nghe build lại.
class CartModel extends ChangeNotifier {
  final Map<String, int> _qty = {};

  int get count => _qty.values.fold(0, (a, b) => a + b);

  int get total => _qty.entries
      .fold(0, (sum, e) => sum + productById(e.key).price * e.value);

  List<(Product, int)> get items =>
      [for (final e in _qty.entries) (productById(e.key), e.value)];

  bool get isEmpty => _qty.isEmpty;

  void add(Product p, [int n = 1]) {
    _qty[p.id] = (_qty[p.id] ?? 0) + n;
    notifyListeners();
  }

  void setQty(Product p, int q) {
    if (q <= 0) {
      _qty.remove(p.id);
    } else {
      _qty[p.id] = q;
    }
    notifyListeners();
  }

  void clear() {
    if (_qty.isEmpty) return;
    _qty.clear();
    notifyListeners();
  }
}

/// Đưa CartModel xuống cây widget (cơ chế Provider dùng bên trong).
class CartScope extends InheritedNotifier<CartModel> {
  const CartScope({
    super.key,
    required CartModel super.notifier,
    required super.child,
  });

  /// Đọc và đăng ký lắng nghe: widget gọi hàm này sẽ build lại khi giỏ đổi.
  static CartModel watch(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CartScope>()!.notifier!;

  /// Chỉ đọc, không lắng nghe: dùng trong onPressed, initState…
  static CartModel read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<CartScope>()!.notifier!;
}
