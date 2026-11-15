import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:state_lab/main.dart';

Future<void> _pumpApp(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const ShopApp());
  await tester.pumpAndSettle();
}

Future<void> _openDrawerAndPick(WidgetTester tester, String mode) async {
  await tester.tap(find.byTooltip('Bảng demo'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(mode));
  await tester.pumpAndSettle();
  // Đổi mode tạo lại HomePage nên Bảng demo tự đóng.
  expect(find.text('Bảng demo'), findsNothing);
}

void main() {
  testWidgets('Chia sẻ: thêm vào giỏ cập nhật badge và trang giỏ hàng',
      (tester) async {
    await _pumpApp(tester, const Size(1200, 900));

    await tester.tap(find.byTooltip('Thêm vào giỏ').first);
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget); // badge

    await tester.tap(find.byTooltip('Giỏ hàng'));
    await tester.pumpAndSettle();
    expect(find.text('Giỏ hàng (1)'), findsOneWidget);

    await tester.tap(find.byTooltip('Tăng'));
    await tester.pumpAndSettle();
    expect(find.text('Giỏ hàng (2)'), findsOneWidget);

    await tester.tap(find.text('Thanh toán'));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Đặt hàng thành công'), findsOneWidget);
  });

  testWidgets('Cục bộ: thẻ tự nhớ nhưng badge không đổi', (tester) async {
    await _pumpApp(tester, const Size(1200, 900));
    await _openDrawerAndPick(tester, 'Cục bộ');

    await tester.tap(find.byTooltip('Thêm vào giỏ').first);
    await tester.pumpAndSettle();
    expect(find.text('Thẻ này nhớ: 1'), findsOneWidget);
    await tester.tap(find.byTooltip('Giỏ hàng'));
    await tester.pumpAndSettle();
    expect(find.text('Giỏ hàng đang trống'), findsOneWidget);
  });

  testWidgets('Nâng lên cha: badge vẫn đúng', (tester) async {
    await _pumpApp(tester, const Size(1200, 900));
    await _openDrawerAndPick(tester, 'Nâng lên cha');

    await tester.tap(find.byTooltip('Thêm vào giỏ').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Thêm vào giỏ').at(1));
    await tester.pumpAndSettle();
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('Trang chi tiết: Mua ngay rồi quay lại ngay không gây lỗi',
      (tester) async {
    await _pumpApp(tester, const Size(1200, 900));

    await tester.tap(find.text('Áo thun basic'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Tăng'));
    await tester.pumpAndSettle();
    expect(find.text('Tạm tính: 318.000 đ'), findsOneWidget);

    await tester.tap(find.text('Mua ngay'));
    await tester.pump();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Mini Shop'), findsOneWidget);
  });

  testWidgets('Tìm kiếm và lọc danh mục', (tester) async {
    await _pumpApp(tester, const Size(1200, 900));
    await tester.tap(find.text('Giày dép'));
    await tester.pumpAndSettle();
    expect(find.text('Giày thể thao'), findsOneWidget);
    expect(find.text('Áo thun basic'), findsNothing);

    await tester.enterText(find.byType(TextField), 'dép');
    await tester.pumpAndSettle();
    expect(find.text('Dép quai ngang'), findsOneWidget);
    expect(find.text('Giày thể thao'), findsNothing);
  });

  testWidgets('Không tràn layout ở bề ngang điện thoại', (tester) async {
    await _pumpApp(tester, const Size(390, 844));
    await tester.tap(find.text('Áo thun basic'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thêm vào giỏ'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Giỏ hàng'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Bảng demo'));
    await tester.pumpAndSettle();
  });
}
