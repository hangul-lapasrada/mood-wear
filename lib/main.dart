import 'package:flutter/material.dart';

import 'shop_shell.dart';

void main() => runApp(const MoodWearApp());

/// Entry point of Mood Wear. All pages now live in their own files:
/// - lib/shop_shell.dart      Home / Style Studio / Search / Saved shell
/// - lib/pages/category_page.dart
/// - lib/pages/product_detail.dart
/// - lib/pages/profile_page.dart
/// - lib/pages/basket_page.dart
/// - lib/api.dart             HTTP client for the FastAPI backend
/// - lib/models.dart          Product / CartItem models
/// - lib/widgets.dart         BottomNavBar / AssetImg shared widgets
class MoodWearApp extends StatelessWidget {
  const MoodWearApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mood Wear',
      theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.white,
          colorSchemeSeed: Colors.grey,
          appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white, foregroundColor: Colors.black)),
      home: const ShopShell());
}
