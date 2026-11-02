import 'package:flutter/material.dart';

import 'api.dart';
import 'models.dart';
import 'widgets.dart';
import 'pages/category_page.dart';
import 'pages/product_detail.dart';
import 'pages/profile_page.dart';
import 'pages/basket_page.dart';

/// Main app shell: keeps global state (products, cart, favorites, set, user)
/// and hosts the five bottom tabs (Home / Style Studio / Search / Saved /
/// Profile) plus header, banner, studio and search builders.
class ShopShell extends StatefulWidget {
  const ShopShell({super.key});
  @override
  State<ShopShell> createState() => _ShopShellState();
}

class _ShopShellState extends State<ShopShell> {
  int tab = 0;
  List<Product> products = [];
  bool loading = true;
  String? error;
  String searchTerm = '';
  final List<CartItem> cart = [];
  final Set<int> saved = {};
  List<Product> mySet = [];
  int? userId;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final p = await Api.products();
      if (mounted) {
        if (mySet.isEmpty) mySet = _defaultSet(p);
        setState(() {
          products = p;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
          error = e.toString();
        });
      }
    }
  }

  void message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void toggleSave(Product p) {
    final added = saved.add(p.id);
    setState(() {
      if (!added) saved.remove(p.id);
    });
    // Write-through to the favorites table when signed in.
    if (userId != null) {
      (added
              ? Api.addFavorite(userId!, p.id)
              : Api.removeFavorite(userId!, p.id))
          .catchError((_) => <String, dynamic>{});
    }
  }

  CartItem cartItemFromDb(Map<String, dynamic> row) => CartItem(
      Product.fromJson(Map<String, dynamic>.from(row['product'])),
      row['color'] ?? '',
      row['size'] ?? 'M',
      quantity: row['quantity'] ?? 1)
    ..dbId = row['id'];

  void add(Product p, String color, String size) {
    setState(() {
      final match = cart
          .where(
              (x) => x.product.id == p.id && x.color == color && x.size == size)
          .toList();
      if (match.isNotEmpty) {
        if (match.first.quantity < p.stock) {
          match.first.quantity++;
        } else {
          message('Only ${p.stock} left');
          return;
        }
      } else {
        cart.add(CartItem(p, color, size));
      }
    });
    // Mirror the local basket row into cart_items when signed in.
    if (userId != null) {
      final item = cart.firstWhere((x) =>
          x.product.id == p.id && x.color == color && x.size == size);
      Api.addToCart(userId!, p.id, item.quantity, size, color)
          .then((res) => item.dbId ??= res['id'])
          .catchError((_) => <String, dynamic>{});
    }
    message('Added to basket');
  }

  /// After login: push guest basket/favorites into the DB, then load the
  /// account's persisted basket and favorites back into the app state.
  Future<void> onLogin(int id) async {
    setState(() => userId = id);
    try {
      final dbRows = await Api.cart(id);
      for (final item in cart) {
        final exists = dbRows.any((r) =>
            r['product']['id'] == item.product.id &&
            r['size'] == item.size &&
            r['color'] == item.color);
        if (!exists) {
          final res = await Api.addToCart(
              id, item.product.id, item.quantity, item.size, item.color);
          item.dbId = res['id'];
        }
      }
      final dbFavs = (await Api.favorites(id)).map((r) => r['id'] as int);
      for (final fid in saved) {
        if (!dbFavs.contains(fid)) await Api.addFavorite(id, fid);
      }
      final fresh = await Api.cart(id);
      setState(() {
        cart
          ..clear()
          ..addAll(fresh.map(cartItemFromDb));
        saved.addAll(dbFavs);
      });
    } catch (e) {
      message('Account sync failed: $e');
    }
  }

  /// Back to guest state: rows backed by the DB stay in the DB (they reload
  /// on the next login), pure in-memory rows remain on screen.
  void logout() {
    setState(() {
      userId = null;
      cart.removeWhere((e) => e.dbId != null);
      saved.clear();
    });
  }

  void detail(Product p, {bool set = false}) => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => ProductDetail(
              product: p,
              isSet: set,
              savedIds: saved,
              onSave: (prod) => toggleSave(prod),
              onAdd: (prod, size) => add(prod, prod.vname, size),
              onBasket: openBasket,
              recommendations: products,
              onProduct: detail,
              fromTab: tab,
              onTab: switchTab)));

  // Switch tabs from any page: close pushed pages first, then show the tab.
  void switchTab(int i) {
    Navigator.of(context).popUntil((r) => r.isFirst);
    setState(() => tab = i);
  }

  void openBasket() => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => BasketPage(
              cart: cart,
              products: products,
              userId: userId,
              onChanged: () => setState(() {}),
              onProduct: detail,
              fromTab: tab,
              onTab: switchTab)));

  Widget header({bool back = false}) => Padding(
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 8),
      child: Row(children: [
        if (back)
          IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back)),
        Expanded(
            child: InkWell(
                onTap: () => setState(() => tab = 2),
                child: Container(
                    height: 30,
                    decoration: BoxDecoration(
                        color: gray, borderRadius: BorderRadius.circular(6)),
                    padding: const EdgeInsets.only(left: 8),
                    alignment: Alignment.centerLeft,
                    child: const Icon(Icons.search, size: 19)))),
        IconButton(
            onPressed: () => message('No new notifications'),
            icon: const Icon(Icons.notifications_none)),
        IconButton(
            onPressed: () => setState(() => tab = 4),
            icon: const Icon(Icons.account_circle_outlined)),
        IconButton(
            onPressed: openBasket,
            icon: Badge(
                label: Text('${cart.fold<int>(0, (a, b) => a + b.quantity)}'),
                isLabelVisible: cart.isNotEmpty,
                child: const Icon(Icons.shopping_bag_outlined)))
      ]));

  Widget _circle(double size, double opacity) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: opacity)));

  Widget homeBanner() => InkWell(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => CategoryPage(
                  category: 'New Arrival',
                  onProduct: detail,
                  fromTab: tab,
                  onTab: switchTab))),
      child: Container(
          height: 230,
          width: double.infinity,
          decoration: const BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                Color(0xFF6D28D9),
                Color(0xFF9D5CE8),
                Color(0xFFEC4899)
              ])),
          child: Stack(children: [
            Positioned(right: -40, top: -50, child: _circle(150, .14)),
            Positioned(right: 70, top: 32, child: _circle(90, .09)),
            Positioned(right: -10, bottom: -35, child: _circle(110, .12)),
            Positioned(right: 36, bottom: 40, child: _circle(54, .18)),
            Padding(
                padding: const EdgeInsets.fromLTRB(28, 34, 28, 22),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .18),
                              borderRadius: BorderRadius.circular(999)),
                          child: const Text('NEW SEASON',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2))),
                      const SizedBox(height: 12),
                      const Text('Dress the\nmood you feel',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 31,
                              fontWeight: FontWeight.bold,
                              height: 1.15)),
                      const SizedBox(height: 10),
                      const Text(
                          'Fresh drops from Nike, adidas, AMI and more',
                          style: TextStyle(
                              color: Color(0xFFF1E7FF), fontSize: 12)),
                      const SizedBox(height: 14),
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 9),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(999)),
                          child: const Text('Shop now →',
                              style: TextStyle(
                                  color: Color(0xFF6D28D9),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)))
                    ]))
          ])));

  Widget cards(List<Product> list, {bool horizontal = false}) {
    if (horizontal) {
      return SizedBox(
          height: 164,
          child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              scrollDirection: Axis.horizontal,
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => SizedBox(
                  width: 112, child: productCard(list[i], compact: true))));
    }
    return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        itemCount: list.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 18,
            childAspectRatio: .77),
        itemBuilder: (_, i) => productCard(list[i]));
  }

  Widget productCard(Product p, {bool compact = false}) => InkWell(
      onTap: () => detail(p, set: p.category == 'Set'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(child: AssetImg(p.img)),
        Container(
            color: gray,
            padding: EdgeInsets.all(compact ? 6 : 9),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: compact ? 12 : 19,
                      fontWeight:
                          compact ? FontWeight.bold : FontWeight.normal)),
              Text('THB: ${p.price}',
                  style: TextStyle(fontSize: compact ? 10 : 13))
            ]))
      ]));

  Widget section(String name, List<Product> list) => Column(children: [
        Padding(
            padding: const EdgeInsets.fromLTRB(29, 16, 22, 7),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(name, style: const TextStyle(fontSize: 20)),
                  TextButton(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => Scaffold(
                                  appBar: AppBar(title: Text(name)),
                                  bottomNavigationBar: BottomNavBar(
                                      onTab: switchTab, currentIndex: tab),
                                  body: cards(list)))),
                      child: const Text('View All',
                          style: TextStyle(color: Colors.black)))
                ])),
        cards(list, horizontal: true)
      ]);

  Widget home() {
    final visible =
        dedupeVariants(products.where((p) => p.category != 'Set').toList());
    return ListView(children: [
      header(),
      homeBanner(),
      SizedBox(
          height: 44,
          child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                'New Arrival',
                'Upper',
                'Bottom',
                'Hat',
                'Shoes',
                'Accessories'
              ]
                  .map((c) => TextButton(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => CategoryPage(
                                  category: c,
                                  onProduct: detail,
                                  fromTab: tab,
                                  onTab: switchTab))),
                      child: Text(c,
                          style:
                              const TextStyle(color: Colors.black, fontSize: 12))))
                  .toList())),
      section('Top-Pick', visible.take(6).toList()),
      section('Trending', visible.reversed.take(6).toList()),
      const SizedBox(height: 25),
      InkWell(
          onTap: () => setState(() => tab = 1),
          child: Container(
              decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Color(0xFF1E293B), Color(0xFF7C3AED)])),
              padding: const EdgeInsets.all(24),
              child: const Row(children: [
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('Style Studio',
                          style: TextStyle(fontSize: 29, color: Colors.white)),
                      Text('Mix and Match your style',
                          style: TextStyle(color: Color(0xFFDDD6FE))),
                      SizedBox(height: 12),
                      Chip(
                          backgroundColor: Colors.white,
                          label: Text('View More',
                              style: TextStyle(color: Color(0xFF6D28D9))))
                    ])),
                Icon(Icons.image_outlined, size: 70, color: Color(0xFFF1E7FF))
              ]))),
      cards(visible.take(6).toList())
    ]);
  }

  static const int setMax = 8;

  List<Product> _defaultSet(List<Product> all) {
    final pool =
        dedupeVariants(all.where((p) => p.category != 'Set').toList());
    final picks = <Product>[];
    for (final c in ['Upper', 'Bottom', 'Shoes', 'Accessories']) {
      final m = pool.where((p) => p.category == c).toList();
      if (m.isNotEmpty) picks.add(m.first);
    }
    return picks;
  }

  void addToSet(Product p) {
    if (mySet.any((x) => x.id == p.id)) {
      message('Already in the set');
      return;
    }
    if (mySet.length >= setMax) {
      message('Set is full (8 items max)');
      return;
    }
    setState(() => mySet.add(p));
    message('${p.name} added to set');
  }

  void removeFromSet(Product p) {
    setState(() => mySet.removeWhere((x) => x.id == p.id));
    message('${p.name} removed from set');
  }

  void setToCart() {
    if (mySet.isEmpty) {
      message('Add products to your set first');
      return;
    }
    for (final p in mySet) {
      add(p, p.vname.isEmpty ? 'Set' : p.vname, 'One Size');
    }
  }

  Future<void> _pickForSet() {
    final pool =
        dedupeVariants(products.where((p) => p.category != 'Set').toList());
    return showModalBottomSheet(
        context: context,
        builder: (sheet) => SizedBox(
            height: 430,
            child: Column(children: [
              Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text('Add product to set',
                      style: Theme.of(sheet).textTheme.titleMedium)),
              Expanded(
                  child: GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: .72),
                      itemCount: pool.length,
                      itemBuilder: (_, i) {
                        final p = pool[i];
                        return InkWell(
                            onTap: () {
                              Navigator.pop(sheet);
                              addToSet(p);
                            },
                            child: Column(children: [
                              Expanded(child: AssetImg(p.img)),
                              Container(
                                  color: gray,
                                  padding: const EdgeInsets.all(4),
                                  child: Text('${p.name}\nTHB ${p.price}',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 11)))
                            ]));
                      }))
            ])));
  }

  Widget _setTile(Product p) => Stack(clipBehavior: Clip.none, children: [
        InkWell(
            onTap: () => detail(p),
            child: SizedBox(
                width: 148,
                height: 148,
                child: AssetImg(p.img, fit: BoxFit.cover))),
        Positioned(
            top: 3,
            right: 3,
            child: InkWell(
                onTap: () => removeFromSet(p),
                child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .92),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: .25),
                              blurRadius: 4)
                        ]),
                    child: const Icon(Icons.close, size: 17))))
      ]);

  Widget _addTile() => InkWell(
      onTap: _pickForSet,
      child: Container(
          width: 148,
          height: 148,
          color: darkGray,
          alignment: Alignment.center,
          child: const Icon(Icons.add, size: 44, color: Colors.white)));

  Widget studio() {
    final recommend =
        dedupeVariants(products.where((p) => p.category != 'Set').toList());
    final total = mySet.fold<int>(0, (s, e) => s + e.price);
    return ListView(children: [
      header(),
      Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
              padding: const EdgeInsets.all(14),
              color: darkGray,
              child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final p in mySet) _setTile(p),
                    if (mySet.length < setMax) _addTile()
                  ]))),
      Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 12, 0),
          child: Row(children: [
            const Expanded(
                child: Text('My Set', style: TextStyle(fontSize: 30))),
            IconButton(
                onPressed: () => message('Set saved to favorites'),
                icon: const Icon(Icons.favorite_border))
          ])),
      Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Price'),
            Text('THB $total', style: const TextStyle(fontSize: 20))
          ])),
      Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
          child: Row(children: [
            Expanded(
                child: OutlinedButton(
                    onPressed: setToCart, child: const Text('PUT IN BASKET'))),
            const SizedBox(width: 24),
            Expanded(
                child: FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF444444)),
                    onPressed: () {
                      setToCart();
                      openBasket();
                    },
                    child: const Text('BUY NOW')))
          ])),
      const Divider(thickness: 10, color: gray),
      const Padding(
          padding: EdgeInsets.all(20),
          child: Text('Recommend', style: TextStyle(fontSize: 20))),
      cards(recommend.take(6).toList())
    ]);
  }

  Widget search() {
    return Column(children: [
      Padding(
          padding: const EdgeInsets.all(18),
          child: TextField(
              decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search fashion products',
                  border: OutlineInputBorder()),
              onChanged: (s) => setState(() => searchTerm = s))),
      Expanded(
          child: ListView(children: [
        cards(dedupeVariants(products)
            .where(
                (p) => p.name.toLowerCase().contains(searchTerm.toLowerCase()))
            .toList())
      ]))
    ]);
  }

  Widget profile() =>
      ProfilePage(onLoggedIn: onLogin, userId: userId, onLogout: logout);

  @override
  Widget build(BuildContext context) => Scaffold(
      body: SafeArea(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : error != null
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(error!, textAlign: TextAlign.center),
                      ElevatedButton(
                          onPressed: reload, child: const Text('Retry'))
                    ]))
                  : IndexedStack(index: tab, children: [
                      home(),
                      studio(),
                      search(),
                      ListView(children: [
                        const Padding(
                            padding: EdgeInsets.all(20),
                            child:
                                Text('Saved', style: TextStyle(fontSize: 26))),
                        cards(products
                            .where((p) => saved.contains(p.id))
                            .toList())
                      ]),
                      profile()
                    ])),
      bottomNavigationBar: BottomNavBar(onTab: switchTab, currentIndex: tab));
}
