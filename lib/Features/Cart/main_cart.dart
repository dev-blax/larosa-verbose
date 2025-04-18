import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:larosa_block/Utils/links.dart';

import '../../Services/auth_service.dart';
import '../../Services/log_service.dart';
import '../../Services/dio_service.dart';
import '../../Utils/colors.dart';
import 'prepare_for_payment.dart';
import 'widgets/brand_button.dart';
import 'widgets/media_gallery_view.dart';

// Function to list cart items
Future<List<Map<String, dynamic>>> listCartItems(int profileId) async {
  final dio = DioService().dio;

  try {
    final response = await dio.post(
      LarosaLinks.cartList,
      data: {
        "profileId": profileId,
      },
    );

    final List<dynamic> data = response.data;
    return List<Map<String, dynamic>>.from(
        data.reversed.map((item) => item as Map<String, dynamic>));
  } catch (error) {
    LogService.logError('Error in listCartItems: $error');
    return [];
  }
}

Future<void> removeItemFromCart(int profileId, int productId) async {
  final dio = DioService().dio;

  try {
    await dio.post(
      LarosaLinks.cartRemoveItem,
      data: {
        "profileId": profileId,
        "items": [
          {"postId": productId, "quantity": 1}
        ]
      },
    );

    LogService.logInfo('Item removed from cart successfully.');
  } catch (error) {
    LogService.logError('Error in removeItemFromCart: $error');
  }
}


class MyCart extends StatefulWidget {
  const MyCart({super.key});

  @override
  State<MyCart> createState() => _MyCartState();
}


class _MyCartState extends State<MyCart> {
  List<Map<String, dynamic>> cartItems = [];
  List<int> selectedItems = [];

  @override
  void initState() {
    super.initState();
    fetchCartItems();
  }

  void fetchCartItems() async {
    int profileId = AuthService.getProfileId() ?? 0;
    if (profileId == 0) {
      LogService.logError('Profile ID is missing.');
      return;
    }
    List<Map<String, dynamic>> items = await listCartItems(profileId);
    setState(() {
      cartItems = items;
    });
  }

  void deleteSelectedItems() async {
    int profileId = AuthService.getProfileId() ?? 0;
    for (int productId in selectedItems) {
      await removeItemFromCart(profileId, productId);
    }
    fetchCartItems();
    setState(() {
      selectedItems.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cart"),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: deleteSelectedItems,
          ),
        ],
      ),
      body: cartItems.isEmpty
          ? const Center(child: Text("No items in the cart"))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final item = cartItems[index];
                final productId = item['productId'];
                final imageUrls = (item['names'] ?? '').split(',');

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.black.withOpacity(0.7)
                              : Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.black.withOpacity(0.1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                SizedBox(
                                  height: 180,
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        PageRouteBuilder(
                                          opaque: false,
                                          barrierColor: Colors.black87,
                                          pageBuilder: (context, animation, secondaryAnimation) {
                                            return MediaGalleryView(
                                              urls: imageUrls,
                                              initialIndex: 0,
                                            );
                                          },
                                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                            return FadeTransition(
                                              opacity: animation,
                                              child: child,
                                            );
                                          },
                                        ),
                                      );
                                    },
                                    child: PageView.builder(
                                      itemCount: imageUrls.length,
                                      itemBuilder: (context, imgIndex) {
                                        return Stack(
                                          children: [
                                            CachedNetworkImage(
                                              imageUrl: imageUrls[imgIndex],
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              errorWidget: (context, error, stackTrace) =>
                                                  const Icon(CupertinoIcons.photo, size: 60),
                                            ),
                                            if (imageUrls.length > 1)
                                              Positioned(
                                                right: 8,
                                                bottom: 8,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black54,
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                    '${imgIndex + 1}/${imageUrls.length}',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          if (selectedItems.contains(productId)) {
                                            selectedItems.remove(productId);
                                          } else {
                                            selectedItems.add(productId);
                                          }
                                        });
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: selectedItems.contains(productId)
                                              ? LarosaColors.secondary.withOpacity(0.9)
                                              : Colors.black.withOpacity(0.5),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          selectedItems.contains(productId)
                                              ? CupertinoIcons.checkmark_circle_fill
                                              : CupertinoIcons.circle,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['caption'] ?? 'Unnamed Product',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).brightness == Brightness.dark
                                              ? Colors.white.withOpacity(0.1)
                                              : Colors.black.withOpacity(0.05),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Qty: ${item['quantity']} @${NumberFormat('#,##0', 'en_US').format(item['price'])}',
                                          style: TextStyle(
                                            color: Theme.of(context).brightness == Brightness.dark
                                                ? Colors.white.withOpacity(0.8)
                                                : Colors.black.withOpacity(0.8),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        'Tsh ${NumberFormat('#,##0', 'en_US').format(item['price'] * item['quantity'])}',
                                        style: TextStyle(
                                          color: Theme.of(context).brightness == Brightness.dark
                                              ? LarosaColors.secondary
                                              : LarosaColors.purple,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 20),
        child: BrandButton(
          text: 'Proceed to Payment',
          onPressed: () {
            if (selectedItems.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("No items selected for payment."),
                ),
              );
              return;
            }

            List<int> productIds = [];
            double totalPrice = 0.0;
            int totalQuantity = 0;
            List<String> combinedNamesList = [];
            List<Map<String, dynamic>> items = [];
            List<Map<String, dynamic>> itemsToDisplay = [];

            for (var productId in selectedItems) {
              var item = cartItems.firstWhere((item) => item['productId'] == productId);

              productIds.add(item['productId']);
              totalPrice += (item['price'] ?? 0.0) * (item['quantity'] ?? 1);
              totalQuantity += (item['quantity'] ?? 1) as int;

              var names = (item['names'] ?? '').split(',');
              combinedNamesList.addAll(names);

              items.add({
                'productId': item['productId'],
                'quantity': item['quantity'] ?? 1
              });

              itemsToDisplay.add({
                'names': item['names'] ?? 'Unnamed Item',
                'price': item['price'] ?? 0.0,
                'quantity': item['quantity'] ?? 1,
              });
            }

            String combinedNames = combinedNamesList.join(',');

            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => PrepareForPayment(
                  productIds: productIds,
                  totalPrice: totalPrice,
                  totalQuantity: totalQuantity,
                  combinedNames: combinedNames,
                  items: items,
                  itemsToDisplay: itemsToDisplay,
                  reservationType: false,
                ),
              ),
            );
          },
          isEnabled: cartItems.isNotEmpty,
        ),
      ),
    );
  }
}