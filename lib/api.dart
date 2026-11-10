import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import 'models.dart';

// Web (Chrome): localhost. Android emulator: 10.0.2.2. iOS simulator: localhost.
// Override with: --dart-define=API_URL=http://<host>:8000
const apiBase = String.fromEnvironment('API_URL',
    defaultValue:
        kIsWeb ? 'http://127.0.0.1:8000' : 'http://10.0.2.2:8000');

/// All HTTP calls to the FastAPI backend (products, cart, favorites, orders).
class Api {
  static Future<List<Product>> products(
      {String? category, String? search}) async {
    final q = <String, String>{};
    if (category != null && category != 'New Arrival') q['category'] = category;
    if (search != null && search.isNotEmpty) q['search'] = search;
    final uri = Uri.parse('$apiBase/products')
        .replace(queryParameters: q.isEmpty ? null : q);
    final r = await http.get(uri).timeout(const Duration(seconds: 8));
    if (r.statusCode != 200) {
      throw Exception('Cannot load products: ${r.statusCode}');
    }
    return (jsonDecode(r.body) as List)
        .map((e) => Product.fromJson(e))
        .toList();
  }

  static Future<Map<String, dynamic>> post(
      String path, Map<String, dynamic> body) async {
    final r = await http
        .post(Uri.parse('$apiBase$path'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body))
        .timeout(const Duration(seconds: 8));
    if (r.statusCode >= 400) {
      final j = jsonDecode(r.body);
      throw Exception(j['detail'] ?? 'Request failed');
    }
    return Map<String, dynamic>.from(jsonDecode(r.body));
  }

  /// Generic JSON call for PUT/DELETE endpoints.
  static Future<Map<String, dynamic>> send(String method, String path,
      {Map<String, dynamic>? body}) async {
    final req = http.Request(method, Uri.parse('$apiBase$path'));
    if (body != null) {
      req.headers['Content-Type'] = 'application/json';
      req.body = jsonEncode(body);
    }
    final streamed =
        await req.send().timeout(const Duration(seconds: 8));
    final r = await http.Response.fromStream(streamed);
    if (r.statusCode >= 400) {
      String detail = 'Request failed (${r.statusCode})';
      try {
        detail = jsonDecode(r.body)['detail'] ?? detail;
      } catch (_) {}
      throw Exception(detail);
    }
    return r.body.isEmpty
        ? {}
        : Map<String, dynamic>.from(jsonDecode(r.body));
  }

  static List<Map<String, dynamic>> _list(String body) =>
      (jsonDecode(body) as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

  // ---- Backend-backed basket (cart_items table) ----
  static Future<List<Map<String, dynamic>>> cart(int userId) async {
    final r = await http.get(Uri.parse('$apiBase/cart').replace(
            queryParameters: {'user_id': '$userId'}))
        .timeout(const Duration(seconds: 8));
    if (r.statusCode != 200) throw Exception('Cannot load basket');
    return _list(r.body);
  }

  static Future<Map<String, dynamic>> addToCart(int userId, int productId,
          int quantity, String size, String color) async =>
      send('POST', '/cart', body: {
        'user_id': userId,
        'product_id': productId,
        'quantity': quantity,
        'size': size,
        'color': color
      });

  static Future<Map<String, dynamic>> updateCart(int itemId, int quantity) =>
      send('PUT', '/cart/$itemId', body: {'quantity': quantity});

  static Future<Map<String, dynamic>> removeCart(int itemId) =>
      send('DELETE', '/cart/$itemId');

  // ---- Backend-backed favorites (favorites table) ----
  static Future<List<Map<String, dynamic>>> favorites(int userId) async {
    final r = await http
        .get(Uri.parse('$apiBase/favorites')
            .replace(queryParameters: {'user_id': '$userId'}))
        .timeout(const Duration(seconds: 8));
    if (r.statusCode != 200) throw Exception('Cannot load favorites');
    return _list(r.body);
  }

  static Future<Map<String, dynamic>> addFavorite(int userId, int productId) =>
      send('POST', '/favorites',
          body: {'user_id': userId, 'product_id': productId});

  static Future<Map<String, dynamic>> removeFavorite(
          int userId, int productId) =>
      send('DELETE', '/favorites/$userId/$productId');

  // ---- Purchase history (orders + order_items tables) ----
  static Future<List<Map<String, dynamic>>> orders(int userId) async {
    final r = await http.get(Uri.parse('$apiBase/orders').replace(
            queryParameters: {'user_id': '$userId'}))
        .timeout(const Duration(seconds: 8));
    if (r.statusCode != 200) throw Exception('Cannot load orders');
    return _list(r.body);
  }
}
