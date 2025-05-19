import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../components/product_card.dart';
import '../components/shopping_cart_sheet.dart';
import '../components/checkout_sheet.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final List<Map<String, dynamic>> products = [
    {
      'id': '1',
      'name': 'Tanzanite Jewelry Set',
      'vendor': 'Tanzanite Experience',
      'price': 240000,
      'originalPrice': 300000,
      'discount': 25,
      'rating': 4.8,
      'image': 'https://images.pexels.com/photos/2735970/pexels-photo-2735970.jpeg',
      'description': 'Authentic Tanzanite jewelry set featuring earrings and necklace.',
    },
    {
      'id': '2',
      'name': 'Maasai Beaded Bracelet',
      'vendor': 'Maasai Crafts',
      'price': 50000,
      'rating': 4.9,
      'image': 'https://images.pexels.com/photos/1191531/pexels-photo-1191531.jpeg',
      'description': 'Handcrafted Maasai beaded bracelet with traditional patterns.',
    },
    {
      'id': '3',
      'name': 'Organic Tanzanian Coffee',
      'vendor': 'Kilimanjaro Coffee Co.',
      'price': 15000,
      'rating': 4.7,
      'image': 'https://images.pexels.com/photos/1695052/pexels-photo-1695052.jpeg',
      'description': 'Premium organic coffee beans from the slopes of Kilimanjaro.',
    },
  ];

  final List<Map<String, dynamic>> cartItems = [];

  void _addToCart(Map<String, dynamic> product) {
    setState(() {
      final existingItem = cartItems.firstWhere(
        (item) => item['id'] == product['id'],
        orElse: () => {'id': null},
      );

      if (existingItem['id'] != null) {
        existingItem['quantity'] = (existingItem['quantity'] ?? 1) + 1;
      } else {
        cartItems.add({...product, 'quantity': 1});
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product['name']} added to cart'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'View Cart',
          onPressed: _showCart,
        ),
      ),
    );
  }

  void _removeFromCart(String productId) {
    setState(() {
      cartItems.removeWhere((item) => item['id'] == productId);
    });
  }

  void _showCart() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ShoppingCartSheet(
        cartItems: cartItems,
        onRemoveItem: _removeFromCart,
        onCheckout: () {
          Navigator.pop(context);
          _showCheckout();
        },
      ),
    );
  }

  void _showCheckout() {
    final total = cartItems.fold(
        0.0, (sum, item) => sum + (item['price'] * (item['quantity'] ?? 1)));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CheckoutSheet(
        totalAmount: total,
        onConfirmPayment: () {
          Navigator.pop(context);
          setState(() => cartItems.clear());
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment successful! Your order is confirmed.'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  void _buyNow(Map<String, dynamic> product) {
    setState(() {
      cartItems.clear();
      cartItems.add({...product, 'quantity': 1});
    });
    _showCheckout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            // actions: [
            //   Stack(
            //     children: [
            //       IconButton(
            //         icon: const Icon(Icons.shopping_cart),
            //         onPressed: _showCart,
            //       ),
            //       if (cartItems.isNotEmpty)
            //         Positioned(
            //           right: 8,
            //           top: 8,
            //           child: Container(
            //             padding: const EdgeInsets.all(4),
            //             decoration: const BoxDecoration(
            //               color: Colors.red,
            //               shape: BoxShape.circle,
            //             ),
            //             child: Text(
            //               cartItems.length.toString(),
            //               style: const TextStyle(
            //                 color: Colors.white,
            //                 fontSize: 12,
            //               ),
            //             ),
            //           ),
            //         ),
            //     ],
            //   ),
            // ],
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Tanzania Marketplace',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl:
                        'https://images.pexels.com/photos/135620/pexels-photo-135620.jpeg',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final product = products[index];
                  return Animate(
                    effects: [
                      SlideEffect(
                        begin: const Offset(0.2, 0),
                        end: const Offset(0, 0),
                        delay: Duration(milliseconds: index * 100),
                        duration: const Duration(seconds: 1),
                        curve: Curves.easeOutQuart,
                      ),
                      FadeEffect(
                        delay: Duration(milliseconds: index * 100),
                        duration: const Duration(milliseconds: 500),
                      ),
                    ],
                    child: ProductCard(
                      product: product,
                      onAddToCart: () => _addToCart(product),
                      onBuyNow: () => _buyNow(product),
                    ),
                  );
                },
                childCount: products.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
