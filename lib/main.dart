import 'package:flutter/material.dart';

import 'screens/home_page.dart';
import 'state/app_settings.dart';
import 'state/cart_model.dart';

void main() => runApp(const ShopApp());

/// Widget gốc: tạo và giữ state CHIA SẺ của toàn app (giỏ hàng, cài đặt),
/// rồi đưa xuống cây widget qua CartScope và SettingsScope.
class ShopApp extends StatefulWidget {
  const ShopApp({super.key});

  @override
  State<ShopApp> createState() => _ShopAppState();
}

class _ShopAppState extends State<ShopApp> {
  late final AppSettings _settings;
  late final CartModel _cart;

  @override
  void initState() {
    super.initState();
    _settings = AppSettings();
    _cart = CartModel();
    appLog.add('ShopApp', 'initState() → tạo CartModel và AppSettings (state chia sẻ)');
  }

  @override
  void dispose() {
    _cart.dispose();
    _settings.dispose();
    super.dispose();
  }

  ThemeData _theme(Brightness b) => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00897B),
          brightness: b,
        ),
        useMaterial3: true,
      );

  @override
  Widget build(BuildContext context) {
    return SettingsScope(
      notifier: _settings,
      child: CartScope(
        notifier: _cart,
        child: ListenableBuilder(
          listenable: _settings,
          builder: (context, _) => MaterialApp(
            title: 'Mini Shop',
            debugShowCheckedModeBanner: false,
            theme: _theme(Brightness.light),
            darkTheme: _theme(Brightness.dark),
            themeMode: _settings.dark ? ThemeMode.dark : ThemeMode.light,
            home: const HomeShell(),
          ),
        ),
      ),
    );
  }
}
