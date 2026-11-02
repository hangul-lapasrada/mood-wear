import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../widgets.dart';

/// Category listing page (New Arrival / Upper / Bottom / Hat / Shoes /
/// Accessories / View All) — loads products straight from the FastAPI
/// backend with a loading/error state.
class CategoryPage extends StatefulWidget {
  final String category;
  final void Function(Product, {bool set}) onProduct;
  final int fromTab;
  final void Function(int) onTab;
  const CategoryPage(
      {super.key,
      required this.category,
      required this.onProduct,
      required this.fromTab,
      required this.onTab});
  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  late Future<List<Product>> future;
  @override
  void initState() {
    super.initState();
    future = Api.products(category: widget.category);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text(widget.category)),
      bottomNavigationBar:
          BottomNavBar(onTab: widget.onTab, currentIndex: widget.fromTab),
      body: FutureBuilder<List<Product>>(
          future: future,
          builder: (context, s) {
            if (!s.hasData) {
              return Center(
                  child: Text(s.hasError ? '${s.error}' : 'Loading...'));
            }
            final items = dedupeVariants(s.data!);
            return GridView.builder(
                padding: const EdgeInsets.all(18),
                itemCount: items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 15,
                    crossAxisSpacing: 15,
                    childAspectRatio: .78),
                itemBuilder: (_, i) {
                  final p = items[i];
                  return InkWell(
                      onTap: () =>
                          widget.onProduct(p, set: p.category == 'Set'),
                      child: Column(children: [
                        Expanded(child: AssetImg(p.img)),
                        Container(
                            color: gray,
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            child: Text('${p.name}\nTHB ${p.price}'))
                      ]));
                });
          }));
}
