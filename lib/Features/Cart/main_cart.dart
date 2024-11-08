import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:larosa_block/Features/Cart/Models/product_model.dart';
import 'package:larosa_block/Features/Cart/controllers/cart_controller.dart';
import 'package:provider/provider.dart';

class MyCart extends StatelessWidget {
  const MyCart({super.key});

  @override
  Widget build(BuildContext context) {
    final cartNotifier = Provider.of<CartController>(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            CupertinoIcons.back,
          ),
        ),
        title: const Text("Your Cart"),
        centerTitle: true,
      ),
      body: cartNotifier.cartItems.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(CupertinoIcons.zzz),
                  const Gap(10),
                  const Text(
                    'You have no Products in your Cart',
                  ),
                  const Gap(10),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        side: BorderSide(color: Colors.blue),
                      ),
                    ),
                    onPressed: () => context.push('/maindelivery'),
                    child: const Text(
                      'Look for Nearby Services and Products',
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cartNotifier.cartItems.length,
                    itemBuilder: (context, index) {
                      var product = cartNotifier.cartItems[index];
                      return CartItemWidget(
                        product: product,
                        onAdd: (product) => cartNotifier.addProduct(product),
                        onRemove: (product) =>
                            cartNotifier.removeProduct(product),
                        onDelete: (product) =>
                            cartNotifier.deleteProduct(product),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Total: \$${cartNotifier.totalPrice.toStringAsFixed(2)}',
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
    super.key,
    required this.product,
    required this.onAdd,
    required this.onRemove,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
