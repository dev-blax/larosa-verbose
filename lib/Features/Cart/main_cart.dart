import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

class Product {
  final String id;
  final String imageUrl;
  final String name;
  final String shortDescription;
  final double price;
  int quantity;

  Product({
    required this.id,
    required this.imageUrl,
    required this.name,
    required this.shortDescription,
    required this.price,
    this.quantity = 1,
  });
}

class MyCart extends StatefulWidget {
  MyCart({Key? key}) : super(key: key);

  @override
  _MyCartState createState() => _MyCartState();
}

class _MyCartState extends State<MyCart> {
  List<Product> cartItems = [];

  @override
  void initState() {
    super.initState();
    _initializeCart();
  }

  void _initializeCart() {
    setState(() {
      cartItems = [
        Product(
          id: '1',
          imageUrl:
              'https://images.pexels.com/photos/291528/pexels-photo-291528.jpeg?auto=compress&cs=tinysrgb&w=600',
          name: 'Black Choco',
          shortDescription: 'Description for product 1',
          price: 10.0,
        ),
        Product(
          id: '2',
          imageUrl:
              'https://images.pexels.com/photos/808941/pexels-photo-808941.jpeg?auto=compress&cs=tinysrgb&w=600',
          name: 'Pinky Cakes',
          shortDescription: 'Description for product 2',
          price: 20.0,
        ),
        Product(
          id: '3',
          imageUrl:
              'https://images.pexels.com/photos/121191/pexels-photo-121191.jpeg?auto=compress&cs=tinysrgb&w=600',
          name: 'Dodoma Wine',
          shortDescription: 'Description for product 3',
          price: 30.0,
        ),
      ];
    });
  }

  void addProduct(Product product) {
    setState(() {
      var existingProduct = cartItems.firstWhere(
        (item) => item.id == product.id,
        orElse: () => Product(id: '', imageUrl: '', name: '', shortDescription: '', price: 0),
      );
      if (existingProduct.id.isNotEmpty) {
        existingProduct.quantity++;
      } else {
        cartItems.add(product);
      }
    });
  }

  void removeProduct(Product product) {
    setState(() {
      if (product.quantity > 1) {
        product.quantity--;
      } else {
        cartItems.remove(product);
      }
    });
  }

  void deleteProduct(Product product) {
    setState(() {
      cartItems.remove(product);
    });
  }

  double get totalPrice {
    return cartItems.fold(
      0,
      (sum, item) => sum + (item.price * item.quantity),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_left,
          ),
        ),
        title: const Text("Your Cart"),
      ),
      body: cartItems.isEmpty
          ? const Center(
              child: Text(
                'No products in Cart',
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      var product = cartItems[index];
                      return Animate(
                        effects: [
                          SlideEffect(
                            curve: Curves.elasticOut,
                            begin: index % 2 == 0
                                ? const Offset(-0.5, 0)
                                : const Offset(0.5, 0),
                            end: Offset.zero,
                            duration: const Duration(seconds: 3),
                          ),
                        ],
                        child: CartItemWidget(
                          product: product,
                          onAdd: addProduct,
                          onRemove: removeProduct,
                          onDelete: deleteProduct,
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Total: \$${totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    // Handle checkout functionality
                  },
                  child: const Text('Checkout'),
                ),
              ],
            ),
    );
  }
}

class CartItemWidget extends StatelessWidget {
  final Product product;
  final Function(Product) onAdd;
  final Function(Product) onRemove;
  final Function(Product) onDelete;

  const CartItemWidget({
    Key? key,
    required this.product,
    required this.onAdd,
    required this.onRemove,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: ContinuousRectangleBorder(borderRadius: BorderRadius.circular(40)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: product.imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(
                    product.shortDescription,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          fontSize: 12,
                        ),
                  ),
                  const Gap(8),
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color: Colors.orange,
                        ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => onAdd(product),
                ),
                Text(product.quantity.toString()),
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () => onRemove(product),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => onDelete(product),
            ),
          ],
        ),
      ),
    );
  }
}
