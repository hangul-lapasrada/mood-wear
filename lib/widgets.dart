import 'package:flutter/material.dart';

import 'models.dart';

/// Shared widgets: pinned bottom navigation bar and product image helpers.
class BottomNavBar extends StatelessWidget {
  final void Function(int) onTab;
  final int currentIndex;
  const BottomNavBar({super.key, required this.onTab, this.currentIndex = 0});
  @override
  Widget build(BuildContext context) => BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: onTab,
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.black,
      items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined), label: 'Home'),
        BottomNavigationBarItem(
            icon: Icon(Icons.checkroom_outlined), label: 'Style Studio'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border), label: 'Saved'),
        BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_outlined), label: 'Profile')
      ]);
}

class Picture extends StatelessWidget {
  final double? height;
  final IconData icon;
  const Picture({super.key, this.height, this.icon = Icons.image_outlined});
  @override
  Widget build(BuildContext context) => Container(
      height: height,
      color: darkGray,
      alignment: Alignment.center,
      child: Icon(icon, size: height != null ? 60 : 45, color: Colors.black));
}

class AssetImg extends StatelessWidget {
  final String asset;
  final BoxFit fit;
  const AssetImg(this.asset, {super.key, this.fit = BoxFit.cover});

  // The API stores 'products/xxx.webp'; Flutter assets live under assets/.
  static String path(String a) =>
      a.startsWith('assets/') || a.isEmpty ? a : 'assets/$a';

  @override
  Widget build(BuildContext context) => asset.isEmpty
      ? const Picture()
      : Image.asset(path(asset),
          fit: fit, errorBuilder: (_, __, ___) => const Picture());
}
