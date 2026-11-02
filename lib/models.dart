import 'package:flutter/material.dart';

/// Domain models shared by every page (Product / CartItem) and the small
/// list helpers for variant groups.
class Product {
  final int id, price, stock;
  final String name, category, img, vgroup, vname;
  Product.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        price = j['price'],
        stock = j['stock'] ?? 0,
        name = j['name'] ?? '',
        category = j['category'] ?? '',
        img = j['img'] ?? '',
        vgroup = j['vgroup'] ?? '',
        vname = j['vname'] ?? '';
}

// Rows of the same variant group share one product card in listings.
List<Product> dedupeVariants(List<Product> list) {
  final seen = <String>{};
  return [
    for (final p in list)
      if (seen.add(p.vgroup.isEmpty ? 'id-${p.id}' : p.vgroup)) p
  ];
}

List<Product> variantsOf(Product p, List<Product> all) {
  if (p.vgroup.isEmpty) return [p];
  final v = all.where((x) => x.vgroup == p.vgroup).toList();
  return v.length <= 1 ? [p] : v;
}

class CartItem {
  final Product product;
  String color, size;
  int quantity;
  bool selected = true;
  // Non-null when this row exists in the backend cart_items table.
  int? dbId;
  CartItem(this.product, this.color, this.size, {this.quantity = 1});
}

// Shared greys used across pages.
const gray = Color(0xFFD9D9D9);
const darkGray = Color(0xFF999999);
