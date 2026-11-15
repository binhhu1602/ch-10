# Chủ đề 10. Cơ sở quản lý trạng thái và cập nhật giao diện trong Flutter

Sản phẩm demo đi kèm: ứng dụng **Mini Shop** trong thư mục `lib/` của project này.

---

## Phần 1. Cơ sở lý thuyết

### 1.1. Khái niệm state và mối quan hệ giữa state với giao diện

**State (trạng thái)** là mọi dữ liệu có thể thay đổi trong lúc ứng dụng chạy và ảnh hưởng tới những gì người dùng nhìn thấy. Ví dụ: số lượng sản phẩm trong giỏ, nội dung ô tìm kiếm, danh mục đang chọn, sản phẩm đã được bấm tim hay chưa, đang tải dữ liệu hay đã tải xong.

Flutter xây dựng giao diện theo kiểu **khai báo (declarative)**. Lập trình viên không ra lệnh sửa từng thành phần ("đổi chữ của nhãn này thành 5"). Lập trình viên chỉ mô tả giao diện trông như thế nào ứng với một trạng thái cho trước:

```
UI = f(state)
```

Giao diện là kết quả của một hàm (`build()`) nhận vào trạng thái hiện tại. Khi trạng thái đổi, Flutter gọi lại `build()` để tạo mô tả giao diện mới, so sánh với mô tả cũ và chỉ vẽ lại phần khác biệt.

| Kiểu mệnh lệnh (imperative) | Kiểu khai báo (Flutter) |
|---|---|
| `label.setText("5")` | `Text('$count')` |
| Lập trình viên tự nhớ phải sửa những view nào | Chỉ đổi dữ liệu và gọi `setState()` |
| Dữ liệu và giao diện dễ lệch nhau | Giao diện luôn được suy ra từ state |

Phía sau một widget có 4 lớp đối tượng:

- **Widget**: bản mô tả cấu hình, bất biến (immutable), nhẹ, được tạo lại liên tục mỗi lần build.
- **Element**: đại diện cho vị trí của widget trong cây, tồn tại lâu và nối Widget với State.
- **State**: đối tượng tồn tại lâu, gắn với Element, giữ dữ liệu qua nhiều lần `build()`.
- **RenderObject**: lo việc bố cục (layout) và vẽ (paint); chỉ được cập nhật ở phần thay đổi.

Nhờ tách như vậy, việc tạo lại Widget mỗi lần build rất rẻ. Dữ liệu cần giữ lại thì nằm trong State, không mất khi Widget được tạo lại.

### 1.2. StatelessWidget, StatefulWidget, vòng đời State và setState

#### StatelessWidget

- Không có State riêng. Mọi dữ liệu đến từ tham số `final` do widget cha truyền vào.
- Chỉ có phương thức `build()`.
- Không thể tự cập nhật. Giao diện chỉ đổi khi widget cha build lại và truyền tham số mới.
- Dùng cho: icon, chữ, thẻ hiển thị dữ liệu được truyền vào.

```dart
class Greeting extends StatelessWidget {
  final String name;
  const Greeting({super.key, required this.name});

  @override
  Widget build(BuildContext context) => Text('Xin chào, $name!');
}
```

#### StatefulWidget

- Gồm hai lớp: lớp widget (bất biến) và lớp `State` (giữ dữ liệu thay đổi được).
- Tự cập nhật giao diện bằng cách gọi `setState()`.
- Có vòng đời đầy đủ, dùng để khởi tạo và giải phóng tài nguyên.
- Dùng cho: form, checkbox, bộ đếm, animation, đồng hồ, màn hình cần gọi API khi mở.

```dart
class LikeButton extends StatefulWidget {
  const LikeButton({super.key});
  @override
  State<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton> {
  bool _liked = false;

  @override
  Widget build(BuildContext context) => IconButton(
        icon: Icon(_liked ? Icons.favorite : Icons.favorite_border),
        onPressed: () => setState(() => _liked = !_liked),
      );
}
```

| Tiêu chí | StatelessWidget | StatefulWidget |
|---|---|---|
| Dữ liệu | Tham số `final` từ cha | Biến trong State, thay đổi được |
| Tự cập nhật UI | Không | Có, qua `setState()` |
| Vòng đời | Chỉ `build()` | `initState`, `didChangeDependencies`, `build`, `didUpdateWidget`, `deactivate`, `dispose` |

#### Vòng đời của State

| Thứ tự | Phương thức | Khi nào được gọi | Thường dùng để |
|---|---|---|---|
| 1 | `createState()` | Widget lần đầu được gắn vào cây | Tạo đối tượng State (gọi 1 lần) |
| 2 | `initState()` | Ngay sau khi State được tạo | Khởi tạo controller, Timer, đăng ký listener, gọi API |
| 3 | `didChangeDependencies()` | Sau `initState`, và mỗi khi InheritedWidget mà widget phụ thuộc (Theme, MediaQuery, Provider…) thay đổi | Đọc dữ liệu từ InheritedWidget |
| 4 | `build()` | Sau các bước trên, và sau mỗi lần `setState` / `didUpdateWidget` / `didChangeDependencies` | Trả về cây widget từ state hiện tại |
| ↺ | `setState(fn)` | Khi lập trình viên muốn đổi dữ liệu | Chạy `fn`, đánh dấu Element "dirty" để frame sau gọi lại `build()` |
| ↺ | `didUpdateWidget(old)` | Widget cha build lại và truyền một widget cấu hình mới cùng loại, cùng key | So sánh cấu hình cũ/mới; State vẫn được giữ nguyên |
| 5 | `deactivate()` | Widget bị gỡ khỏi cây (có thể được gắn lại trong cùng frame) | Hiếm khi dùng |
| 6 | `dispose()` | Widget bị gỡ vĩnh viễn | Hủy Timer, StreamSubscription, AnimationController, TextEditingController |

#### Luồng cập nhật khi gọi setState

```
Sự kiện (onPressed)
  → setState(() { thay đổi dữ liệu })
  → Element được đánh dấu dirty (markNeedsBuild)
  → Frame kế tiếp: Flutter gọi build() của các Element dirty
  → So sánh cây widget mới với cây cũ (cùng loại + cùng key → cập nhật, không tạo lại)
  → Chỉ RenderObject thay đổi mới được layout/paint lại
```

#### Các quy tắc khi dùng setState

1. **Chỉ gọi khi `mounted == true`.** Sau `dispose()`, gọi `setState` sẽ ném lỗi `setState() called after dispose()`. Lỗi này hay gặp khi `await` một API xong thì người dùng đã rời màn hình.
2. **Không gọi trong `build()`.** Làm vậy gây vòng lặp build vô hạn, Flutter báo lỗi *setState() or markNeedsBuild() called during build*.
3. **Đổi dữ liệu bên trong callback và callback phải đồng bộ**, không truyền hàm `async`.
4. **Giải phóng tài nguyên trong `dispose()`** để tránh rò rỉ bộ nhớ.

### 1.3. Phân biệt trạng thái cục bộ với trạng thái cần chia sẻ

| | Trạng thái cục bộ (ephemeral / local state) | Trạng thái chia sẻ (app state / shared state) |
|---|---|---|
| Ai dùng | Chỉ một widget | Nhiều widget, nhiều màn hình |
| Ví dụ | Tab đang chọn, nút tim, ẩn/hiện mật khẩu, tiến độ animation, số lượng đang chọn trên một trang | Giỏ hàng, người dùng đăng nhập, chế độ sáng/tối, ngôn ngữ, thông báo chưa đọc |
| Cách quản lý | `StatefulWidget` + `setState` | Nâng state lên cha chung (lifting state up), `InheritedWidget`, `ChangeNotifier`, Provider, Riverpod, BLoC… |
| Vòng đời dữ liệu | Mất khi widget bị `dispose` | Sống lâu hơn từng màn hình |

Câu hỏi để phân loại: *"Có widget nào khác, hoặc màn hình nào khác, cần đọc hay sửa dữ liệu này không?"* Nếu không thì đó là state cục bộ. Nếu có thì đó là state cần chia sẻ.

---

## Phần 2. Ứng dụng demo: Mini Shop

### 2.1. Mô tả

Mini Shop là một ứng dụng bán hàng nhỏ gồm 3 màn hình:

- **Trang chủ:** ô tìm kiếm, lọc theo danh mục, lưới sản phẩm, nút tim, nút thêm vào giỏ, badge giỏ hàng.
- **Chi tiết sản phẩm:** chọn số lượng, thêm vào giỏ, mua ngay (giả lập gọi API 2 giây).
- **Giỏ hàng:** sửa số lượng, xóa, tổng tiền, thanh toán.

Ứng dụng có thêm **Bảng demo** (nút ⚙ góc phải trên) dùng khi thuyết trình:

- Chuyển giữa 3 cách quản lý giỏ hàng: **Chia sẻ**, **Nâng lên cha** và **Cục bộ**.
- Bật/tắt lớp phủ **số lần build**. Mỗi widget có nhãn `Tên ×n`, và khung nháy cam là widget vừa chạy lại `build()`.
- Xem **nhật ký vòng đời và setState** theo thời gian thực (cũng in ra Debug Console).

### 2.2. Ánh xạ khái niệm vào mã nguồn

| Khái niệm | Thể hiện trong app | File |
|---|---|---|
| StatelessWidget | `QuantityStepper`: không giữ số lượng, nhận `value` và báo `onChanged` cho cha | `lib/widgets/quantity_stepper.dart` |
| StatelessWidget đọc state chia sẻ | `CartBadgeButton`: tự lắng nghe `CartModel` | `lib/widgets/cart_badge.dart` |
| StatefulWidget + setState (cục bộ) | `LikeButton` (`_liked`), `HomePage` (`_query`, `_category`), `ProductDetailPage` (`_qty`) | `lib/widgets/like_button.dart`, `lib/screens/...` |
| Vòng đời State đầy đủ | `ProductDetailPage` ghi log `initState`, `didChangeDependencies`, `build`, `didUpdateWidget`, `deactivate`, `dispose` | `lib/screens/product_detail_page.dart` |
| `dispose()` giải phóng tài nguyên | `HomePage` hủy `TextEditingController` và bỏ lắng nghe giỏ hàng | `lib/screens/home_page.dart` |
| Kiểm tra `mounted` sau `await` | Nút **Mua ngay** và **Thanh toán** | `product_detail_page.dart`, `cart_page.dart` |
| State chia sẻ | `CartModel extends ChangeNotifier` + `CartScope extends InheritedNotifier` | `lib/state/cart_model.dart` |
| State toàn cục | Chế độ sáng/tối trong `AppSettings`, đọc ở `MaterialApp` | `lib/state/app_settings.dart`, `lib/main.dart` |
| Nâng state lên cha (lifting state up) | Cách "Nâng lên cha": `HomePage` lắng nghe giỏ, `setState`, truyền `count` xuống badge | `lib/screens/home_page.dart` |

### 2.3. Ba cách quản lý giỏ hàng

**Cách A – Cục bộ.** Mỗi `ProductCard` tự giữ `_inCart` và gọi `setState`.
Kết quả: thẻ hiện "Thẻ này nhớ: n", nhưng badge vẫn là 0 và trang giỏ hàng trống. Trang chi tiết cũng không thêm được vào giỏ. State cục bộ không chia sẻ được cho widget anh em hay màn hình khác.

**Cách B – Nâng lên cha.** `HomePage` lắng nghe `CartModel`, mỗi lần giỏ đổi thì `setState` rồi truyền `count` xuống `CartBadgeButton`.
Kết quả: dữ liệu đúng, nhưng mỗi lần thêm vào giỏ thì **toàn bộ** `HomePage`, mọi `ProductCard` và mọi `LikeButton` đều nháy cam (build lại), dù chúng không dùng số lượng giỏ.

**Cách C – Chia sẻ.** `CartModel` nằm ở gốc app, cung cấp qua `CartScope` (`InheritedNotifier`, cũng là cơ chế bên trong package Provider).
- Widget cần hiển thị dữ liệu dùng `CartScope.watch(context)` để đăng ký lắng nghe.
- Widget chỉ cần gọi hành động dùng `CartScope.read(context)` nên không đăng ký.

Kết quả: thêm vào giỏ thì **chỉ badge** build lại. Trang giỏ hàng và badge luôn đồng bộ. Giỏ hàng vẫn còn khi chuyển màn hình.

### 2.4. Kịch bản demo đề xuất (khoảng 7 phút)

1. **UI = f(state).** Gõ vào ô tìm kiếm và chọn danh mục. Chỉ ra `HomePage ×n` tăng: `setState(_query)` làm `build()` chạy lại và lưới sản phẩm được lọc theo state mới.
2. **State cục bộ.** Bấm tim một sản phẩm: chỉ khung `Like` nháy. Mở Bảng demo để thấy log `setState(_liked = true)`.
3. **StatelessWidget.** Mở trang chi tiết, bấm +/−. `QuantityStepper` không giữ số; trang cha giữ `_qty` và build lại.
4. **Vòng đời.** Mở Bảng demo trên trang chi tiết: log `initState → didChangeDependencies → build`. Bấm +, log `setState → build`. Quay lại trang chủ: log `deactivate → dispose`, số lượng đã chọn mất theo. Bật/tắt chế độ tối: log `didChangeDependencies` (Theme đổi).
5. **mounted.** Vào chi tiết, bấm **Mua ngay** rồi quay lại ngay. Sau 2 giây log báo `mounted == false → bỏ qua setState`.
6. **Cách A – Cục bộ.** Đổi sang "Cục bộ", thêm vào giỏ: badge không đổi, giỏ hàng trống.
7. **Cách B – Nâng lên cha.** Đổi sang "Nâng lên cha", thêm vào giỏ: cả màn hình nháy cam.
8. **Cách C – Chia sẻ.** Đổi về "Chia sẻ", thêm vào giỏ: chỉ badge nháy. Mở giỏ, sửa số lượng, quay lại: badge đã đúng.

### 2.5. Giải thích vòng đời cập nhật trong app

Khi người dùng bấm "Thêm vào giỏ" ở cách C:

1. `onPressed` gọi `CartScope.read(context).add(product)`.
2. `CartModel.add` sửa map `_qty` rồi gọi `notifyListeners()`.
3. `InheritedNotifier` nhận thông báo và đánh dấu các widget đã `watch` (badge) là dirty.
4. Frame kế tiếp, Flutter chỉ gọi `build()` của `CartBadgeButton`. Nó đọc `count` mới và trả về `Badge` với số mới.
5. Flutter so sánh cây cũ/mới và chỉ vẽ lại con số trên badge.

Ở cách B, bước 3 thay bằng `HomePage.setState(() {})`. Do đó bước 4 build lại toàn bộ cây con của `HomePage`.

### 2.6. Giới hạn của cách quản lý trạng thái cục bộ

1. **Không chia sẻ được.** State trong một widget thì widget anh em và màn hình khác không đọc được (cách A: badge không cập nhật).
2. **Build lại quá rộng.** Nâng state lên cha chung thì mỗi lần `setState` cả cây con build lại, kể cả widget không dùng dữ liệu đó (cách B).
3. **Prop drilling.** Dữ liệu và callback phải truyền qua nhiều tầng widget trung gian không cần chúng. App càng nhiều màn hình càng rối.
4. **Mất state khi widget bị hủy.** Bấm tim một sản phẩm, đổi sang danh mục khác rồi quay lại: tim đã mất, vì `ProductCard` bị dispose khi lọc. Tương tự, số lượng chọn ở trang chi tiết mất khi quay lại.
5. **Cùng dữ liệu, nhiều bản không đồng bộ.** Tim ở lưới và tim ở trang chi tiết của *cùng* sản phẩm là hai State khác nhau, nên không đồng bộ. Nếu "yêu thích" cần nhất quán, nó phải trở thành state chia sẻ.
6. **Logic trộn với giao diện.** Nghiệp vụ nằm trong State của widget nên khó tái sử dụng và khó viết unit test riêng.
7. **Bất đồng bộ phải tự xử lý.** Phải tự kiểm tra `mounted`, tự quản lý loading và lỗi ở từng widget.

**Hướng mở rộng:**

```
setState → Lifting state up → InheritedWidget / InheritedNotifier
        → ValueNotifier / ChangeNotifier → Provider · Riverpod · BLoC
```

---

## Phần 3. Các ứng dụng liên quan

### 3.1. Ứng dụng bài tập thường làm

| Ứng dụng | Khái niệm minh họa |
|---|---|
| Counter App (mẫu của `flutter create`) | StatefulWidget, setState |
| Todo List | setState với danh sách, `dispose` TextEditingController |
| Stopwatch / Đồng hồ đếm ngược | Tạo Timer trong `initState`, hủy trong `dispose` |
| Giỏ hàng (Mini Shop) | State chia sẻ, lifting state up, Provider |
| Đổi giao diện sáng/tối | State toàn cục, InheritedWidget (`Theme.of`) |
| Form đăng nhập | State cục bộ (ẩn/hiện mật khẩu, loading), kiểm tra `mounted` |
| Quiz trắc nghiệm | setState, truyền điểm sang màn kết quả |
| Ứng dụng thời tiết | Gọi API trong `initState`, FutureBuilder, trạng thái loading/lỗi |
| Bottom Navigation | `_selectedIndex` cục bộ; tab bị dispose mất state, giữ lại bằng `IndexedStack` |

### 3.2. Ứng dụng thực tế xây dựng bằng Flutter

Các ứng dụng sau đã phát hành và được viết bằng Flutter. Hai cột cuối là ví dụ thành phần giao diện thường gặp trong loại ứng dụng đó, để minh họa cách phân loại state. Đây không phải mã nguồn của các ứng dụng này.

| Ứng dụng | Lĩnh vực | State cục bộ (ví dụ) | State chia sẻ (ví dụ) |
|---|---|---|---|
| Google Pay | Thanh toán | Bàn phím nhập số tiền | Tài khoản, danh sách thẻ, lịch sử giao dịch |
| Google Ads | Quảng cáo | Bộ lọc khoảng thời gian | Chiến dịch đang chọn, số liệu |
| Nubank | Ngân hàng số | Ô nhập, thẻ mở rộng | Số dư, phiên đăng nhập |
| My BMW | Ô tô | Tab đang chọn | Trạng thái xe ở nhiều màn hình |
| Xianyu (Alibaba) | Mua bán đồ cũ | Nút thích, ảnh carousel | Giỏ hàng, tin nhắn chưa đọc |
| eBay Motors | Mua bán xe | Bộ lọc tìm kiếm đang mở | Danh sách theo dõi, người dùng |
| Reflectly | Nhật ký cảm xúc | Thanh chọn tâm trạng | Các bài nhật ký, chủ đề màu |

---

## Phụ lục: Chạy ứng dụng

```
cd C:\Users\HELLO\Documents\flutter_state_lab
flutter run -d chrome
```

Chạy kiểm thử: `flutter test`
