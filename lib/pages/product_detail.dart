import 'package:flutter/material.dart';

import '../models.dart';
import '../widgets.dart';

/// Product detail page: variant (colorway) picker + size picker + add to
/// basket. For sets it shows the big Studio Fit frame with recommended
/// products instead of variant/size controls.
class ProductDetail extends StatefulWidget {
  final Product product;
  final bool isSet;
  final Set<int> savedIds;
  final void Function(Product) onSave;
  final VoidCallback onBasket;
  final void Function(Product, String) onAdd;
  final List<Product> recommendations;
  final void Function(Product, {bool set}) onProduct;
  final int fromTab;
  final void Function(int) onTab;
  const ProductDetail(
      {super.key,
      required this.product,
      required this.isSet,
      required this.savedIds,
      required this.onSave,
      required this.onAdd,
      required this.onBasket,
      required this.recommendations,
      required this.onProduct,
      required this.fromTab,
      required this.onTab});
  @override
  State<ProductDetail> createState() => _ProductDetailState();
}

class _ProductDetailState extends State<ProductDetail> {
  static const apparelSizes = ['XXS', 'XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL'];
  static const shoeSizes = [
    'US 5', 'US 6', 'US 7', 'US 8', 'US 9', 'US 10', 'US 11', 'US 12'
  ];
  late List<String> sizeOptions;
  late String size;
  late List<Product> variants;
  int vi = 0;
  Product get cur => variants[vi];
  @override
  void initState() {
    super.initState();
    variants = variantsOf(widget.product, widget.recommendations);
    vi = variants.indexWhere((x) => x.id == widget.product.id);
    if (vi < 0) vi = 0;
    final c = widget.product.category.toLowerCase();
    if (widget.isSet || c == 'accessories' || c == 'hat') {
      // Hats and accessories (and sets) come in one size.
      sizeOptions = const [];
      size = 'One Size';
    } else if (c == 'shoes') {
      sizeOptions = shoeSizes;
      size = 'US 9';
    } else {
      sizeOptions = apparelSizes;
      size = 'M';
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = cur;
    return Scaffold(
        appBar: AppBar(title: const Text(''), actions: [
          IconButton(
              onPressed: widget.onBasket,
              icon: const Icon(Icons.shopping_bag_outlined)),
          IconButton(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => Scaffold(
                          appBar: AppBar(title: const Text('Profile')),
                          body: const Center(
                              child: Text(
                                  'Open Profile from the bottom navigation'))))),
              icon: const Icon(Icons.account_circle_outlined))
        ]),
        body: ListView(
          children: [
            Padding(
                padding: EdgeInsets.fromLTRB(0, 0, 0, widget.isSet ? 0 : 19),
                child: SizedBox(
                    height: widget.isSet ? 430 : 260,
                    width: double.infinity,
                    child: AssetImg(p.img, fit: BoxFit.cover))),
            if (!widget.isSet && variants.length > 1)
              SizedBox(
                  height: 78,
                  child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: variants.length,
                      itemBuilder: (_, i) => InkWell(
                          onTap: () => setState(() => vi = i),
                          child: Opacity(
                              opacity: vi == i ? 1 : .55,
                              child: Container(
                                  width: 66,
                                  margin: const EdgeInsets.only(right: 10),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: vi == i
                                              ? Colors.black
                                              : Colors.transparent,
                                          width: 2)),
                                  child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: AssetImg(variants[i].img))))))),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  Expanded(
                      child: Text(p.name, style: const TextStyle(fontSize: 24))),
                  IconButton(
                      icon: Icon(widget.savedIds.contains(p.id)
                          ? Icons.favorite
                          : Icons.favorite_border),
                      onPressed: () => setState(() => widget.onSave(p)))
                ])),
            if (!widget.isSet && variants.length > 1)
              const Padding(
                  padding: EdgeInsets.fromLTRB(20, 22, 20, 0),
                  child: Text('Color')),
            if (!widget.isSet && variants.length > 1)
              Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final v in variants)
                          ChoiceChip(
                              selected: v.id == p.id,
                              onSelected: (_) =>
                                  setState(() => vi = variants.indexOf(v)),
                              label: Text(v.vname.isEmpty ? 'Variant' : v.vname,
                                  style: const TextStyle(fontSize: 12)))
                      ])),
            if (!widget.isSet && sizeOptions.isNotEmpty) ...[
              const Padding(
                  padding: EdgeInsets.fromLTRB(20, 22, 20, 0),
                  child: Text('Size')),
              Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final s in sizeOptions)
                          InkWell(
                              onTap: () => setState(() => size = s),
                              child: Container(
                                  width: 70,
                                  height: 50,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                      color: gray,
                                      border: Border.all(
                                          color: size == s
                                              ? Colors.black
                                              : Colors.transparent,
                                          width: 2)),
                                  child: Text(s,
                                      style: const TextStyle(fontSize: 14))))
                      ]))
            ],
            if (!widget.isSet)
              const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text('★★★★★   5.0 (230 Review)')),
            Padding(
                padding: const EdgeInsets.all(22),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Price'),
                            Text('THB ${p.price}',
                                style: const TextStyle(fontSize: 20))
                          ]),
                      Text('${p.stock} Left',
                          style: const TextStyle(fontSize: 19))
                    ])),
            const Divider(thickness: 10, color: gray),
            if (!widget.isSet) ...[
              const Padding(
                  padding: EdgeInsets.all(22),
                  child: Text(
                      'Product Description\n\nA versatile fashion piece for everyday styling. Pick a variant above to switch colorway — the name, price and photos update instantly.\n\nMix and match this item with other pieces from our collection.',
                      style: TextStyle(fontSize: 15, height: 1.6)))
            ],
            if (widget.isSet) ...[
              const Divider(thickness: 10, color: gray),
              const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Recommend', style: TextStyle(fontSize: 19))),
              Padding(
                  padding: const EdgeInsets.all(18),
                  child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.recommendations
                          .where((x) => x.category != 'Set')
                          .take(6)
                          .length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: .8),
                      itemBuilder: (_, i) {
                        final r = widget.recommendations
                            .where((x) => x.category != 'Set')
                            .elementAt(i);
                        return InkWell(
                            onTap: () => widget.onProduct(r),
                            child: Column(children: [
                              const Expanded(child: Picture()),
                              Container(
                                  width: double.infinity,
                                  color: gray,
                                  padding: const EdgeInsets.all(8),
                                  child: Text('${r.name}\nTHB ${r.price}'))
                            ]));
                      }))
            ]
          ],
        ),
        bottomNavigationBar:
            Column(mainAxisSize: MainAxisSize.min, children: [
          SafeArea(
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    Expanded(
                        child: OutlinedButton(
                            onPressed: () => widget.onAdd(
                                p, widget.isSet ? 'One Size' : size),
                            child: const Text('PUT IN BASKET'))),
                    const SizedBox(width: 24),
                    Expanded(
                        child: FilledButton(
                            style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF444444)),
                            onPressed: () {
                              widget.onAdd(p, widget.isSet ? 'One Size' : size);
                              widget.onBasket();
                            },
                            child: const Text('BUY NOW')))
                  ]))),
          BottomNavBar(onTab: widget.onTab, currentIndex: widget.fromTab)
        ]));
  }
}
