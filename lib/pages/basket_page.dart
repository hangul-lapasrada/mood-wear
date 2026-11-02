import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../widgets.dart';

/// Basket page: quantity/checkbox/delete with write-back to cart_items,
/// address checkout posting to /orders and similar-product suggestions.
class BasketPage extends StatefulWidget {
  final List<CartItem> cart;
  final List<Product> products;
  final int? userId;
  final VoidCallback onChanged;
  final void Function(Product, {bool set}) onProduct;
  final int fromTab;
  final void Function(int) onTab;
  const BasketPage(
      {super.key,
      required this.cart,
      required this.products,
      required this.userId,
      required this.onChanged,
      required this.onProduct,
      required this.fromTab,
      required this.onTab});
  @override
  State<BasketPage> createState() => _BasketPageState();
}

class _BasketPageState extends State<BasketPage> {
  final address = TextEditingController();
  bool busy = false;
  @override
  void dispose() {
    address.dispose();
    super.dispose();
  }

  int get subtotal => widget.cart
      .where((e) => e.selected)
      .fold(0, (s, e) => s + e.product.price * e.quantity);
  void update() {
    setState(() {});
    widget.onChanged();
  }

  // Quantity changes and removals are written back to cart_items.
  void changeQty(CartItem e, int delta) {
    final q = e.quantity + delta;
    if (q < 1 || q > e.product.stock) return;
    e.quantity = q;
    update();
    if (widget.userId != null && e.dbId != null) {
      Api.updateCart(e.dbId!, q).catchError((_) => <String, dynamic>{});
    }
  }

  Future<void> checkout() async {
    final selected = widget.cart.where((e) => e.selected).toList();
    if (selected.isEmpty || address.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select items and enter an address')));
      return;
    }
    setState(() => busy = true);
    try {
      final result = await Api.post('/orders', {
        'user_id': widget.userId,
        'address': address.text,
        'items': selected
            .map((e) => {
                  'product_id': e.product.id,
                  'quantity': e.quantity,
                  'size': e.size,
                  'color': e.color
                })
            .toList()
      });
      final dbIds = [for (final e in selected) if (e.dbId != null) e.dbId!];
      widget.cart.removeWhere((e) => e.selected);
      update();
      // Checked-out rows are removed from cart_items too.
      if (widget.userId != null) {
        for (final id in dbIds) {
          Api.removeCart(id).catchError((_) => <String, dynamic>{});
        }
      }
      if (mounted) {
        showDialog(
            context: context,
            builder: (_) => AlertDialog(
                    title: const Text('Order placed'),
                    content: Text(
                        'Order #${result['order_id']}\nTotal THB ${result['total']}'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'))
                    ]));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final similar =
        dedupeVariants(widget.products.where((p) => p.category != 'Set').toList())
            .take(6)
            .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Basket'), centerTitle: true),
      bottomNavigationBar:
          BottomNavBar(onTab: widget.onTab, currentIndex: widget.fromTab),
      body: ListView(children: [
        Container(
            color: gray,
            padding: const EdgeInsets.all(6),
            child: Column(
                children: widget.cart
                    .map((e) => Container(
                        color: Colors.white,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(8),
                        child: Row(children: [
                          ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: SizedBox(
                                  width: 90,
                                  height: 85,
                                  child:
                                      AssetImg(e.product.img, fit: BoxFit.cover))),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(e.product.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 20)),
                                Text(e.color),
                                Text('${e.product.price} THB   ${e.size}'),
                                Row(children: [
                                  IconButton(
                                      onPressed: () => changeQty(e, -1),
                                      icon: const Icon(
                                          Icons.remove_circle_outline)),
                                  Text('${e.quantity}'),
                                  IconButton(
                                      onPressed: () => changeQty(e, 1),
                                      icon:
                                          const Icon(Icons.add_circle_outline))
                                ])
                              ])),
                          Column(children: [
                            Checkbox(
                                value: e.selected,
                                onChanged: (v) {
                                  e.selected = v ?? false;
                                  update();
                                }),
                            IconButton(
                                onPressed: () {
                                  widget.cart.remove(e);
                                  update();
                                  if (widget.userId != null &&
                                      e.dbId != null) {
                                    Api.removeCart(e.dbId!)
                                        .catchError((_) => <String, dynamic>{});
                                  }
                                },
                                icon: const Icon(Icons.delete_outline))
                          ])
                        ])))
                    .toList())),
        Padding(
            padding: const EdgeInsets.all(18),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Basket', style: TextStyle(fontSize: 24)),
              const SizedBox(height: 20),
              Text(
                  'Subtotal                                       $subtotal THB'),
              const Text(
                  'Delivery fee                                      0 THB'),
              Text(
                  'Total price                                      $subtotal THB'),
              const SizedBox(height: 20),
              TextField(
                  controller: address,
                  decoration: const InputDecoration(
                      labelText: 'Location / Address',
                      hintText: 'Enter delivery address',
                      border: OutlineInputBorder())),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                    child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Continue Shopping'))),
                const SizedBox(width: 15),
                Expanded(
                    child: FilledButton(
                        style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF444444)),
                        onPressed: busy ? null : checkout,
                        child: const Text('Checkout')))
              ])
            ])),
        const Divider(thickness: 12, color: gray),
        const Padding(
            padding: EdgeInsets.all(20),
            child: Text('Similar product', style: TextStyle(fontSize: 19))),
        GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            itemCount: similar.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 18,
                childAspectRatio: .8),
            itemBuilder: (_, i) {
              final p = similar[i];
              return InkWell(
                  onTap: () => widget.onProduct(p),
                  child: Column(children: [
                    Expanded(child: AssetImg(p.img)),
                    Container(
                        width: double.infinity,
                        color: gray,
                        padding: const EdgeInsets.all(8),
                        child: Text('${p.name}\nTHB ${p.price}'))
                  ]));
            })
      ]));
  }
}
