import 'dart:ui';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:larosa_block/Utils/links.dart';

import '../../Services/auth_service.dart';
import '../../Services/log_service.dart';
import '../../Services/dio_service.dart';
import '../../Services/reservation_service.dart';
import '../../Utils/colors.dart';
import '../../Utils/helpers.dart';
import 'proceed_to_payment.dart';
import 'widgets/brand_button.dart';
import 'widgets/cart_shimmer.dart';
import 'widgets/media_gallery_view.dart';

enum UpdateType { increase, decrease }

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
    LogService.logInfo('Cart items: ${data[0]}');
    return List<Map<String, dynamic>>.from(
        data.reversed.map((item) => item as Map<String, dynamic>));
  } catch (error) {
    LogService.logError('Error in listCartItems: $error');
    return [];
  }
}

Future<void> _removeItemFromCart(int profileId, int productId) async {
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
  List<Map<String, dynamic>> reservationItems = [];
  bool isLoading = true;
  List<int> selectedItems = [];
  int _selectedTabIndex = 0;
  Map<int, bool> _isUpdatingQuantity = {};
  Map<int, Timer?> _debounceTimers = {};
  Map<int, int> _pendingQuantities = {};

  @override
  void dispose() {
    for (var timer in _debounceTimers.values) {
      timer?.cancel();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadCartItems();
    _loadReservationItems();
  }

  Future<void> _loadCartItems() async {
    int profileId = AuthService.getProfileId() ?? 0;
    if (profileId == 0) {
      LogService.logError('Profile ID is missing.');
      return;
    }
    List<Map<String, dynamic>> items = await listCartItems(profileId);
    setState(() {
      cartItems = items;
      isLoading = false;
    });

    LogService.logTrace('Cart items: ${cartItems[0]}');
  }

  Future<void> _loadReservationItems() async {
    List<dynamic> items = await ReservationService.getReservationsInCart();
    setState(() {
      reservationItems =
          items.map((item) => Map<String, dynamic>.from(item)).toList();
      isLoading = false;
    });

    LogService.logTrace('Reservation items: ${reservationItems[0]}');
  }

  Future<void> _increaseCartItemQuantity(int productId, int quantity) async {
    final dio = DioService().dio;
    try {
      await dio.post(
        LarosaLinks.addCartItemQuantity,
        data: {
          "items": [
            {
              "postId": productId,
              "quantity": 1,
            },
          ],
        },
      );
      LogService.logTrace('Cart item quantity updated successfully.');
      await _loadCartItems();
    } catch (error) {
      LogService.logError('Error in updateCartItemQuantity: $error');
    }
  }

  Future<void> _decreaseCartItemQuantity(int productId, int quantity) async {
    final dio = DioService().dio;
    try {
      if (quantity <= 1) return;
      await dio.post(
        LarosaLinks.decreaseCartItemQuantity,
        data: {
          "items": [
            {
              "postId": productId,
              "quantity": 1,
            }
          ],
        },
      );
      LogService.logTrace('Cart item quantity updated successfully.');
      await _loadCartItems();
    } catch (error) {
      LogService.logError('Error in updateCartItemQuantity: $error');
    }
  }

  Future<void> _handleQuantityUpdate(
      Map<String, dynamic> item, int newQuantity, UpdateType type) async {
    if (newQuantity < 1) return;

    final productId = item['productId'] ?? item['reservationId'];
    final currentQuantity = _pendingQuantities[productId] ?? item['quantity'];

    if (newQuantity == currentQuantity) return;

    _debounceTimers[productId]?.cancel();

    setState(() {
      _pendingQuantities[productId] = newQuantity;
      _isUpdatingQuantity[productId] = true;
    });

    _debounceTimers[productId] =
        Timer(const Duration(milliseconds: 500), () async {
      try {
        if (type == UpdateType.increase) {
          await _increaseCartItemQuantity(productId, newQuantity);
        } else {
          await _decreaseCartItemQuantity(productId, newQuantity);
        }
      } finally {
        if (mounted) {
          setState(() {
            _isUpdatingQuantity[productId] = false;
            _pendingQuantities.remove(productId);
          });
        }
      }
    });
  }

  void _deleteSelectedItems() async {
    int profileId = AuthService.getProfileId() ?? 0;
    for (int productId in selectedItems) {
      await _removeItemFromCart(profileId, productId);
    }
    _loadCartItems();
    setState(() {
      selectedItems.clear();
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.cart,
            size: 64,
            color: CupertinoColors.systemGrey.withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          Text(
            "Your Cart is Empty",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Add items to start shopping",
            style: TextStyle(
              fontSize: 15,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 24),
          CupertinoButton(
            onPressed: () => context.pop(),
            child: const Text("Browse Items"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // List<Map<String, dynamic>> reservationItems =
    //     cartItems.where((item) => item['type'] == 'RESERVATION').toList();
    List<Map<String, dynamic>> businessPostItems =
        cartItems.where((item) => item['type'] == 'BUSINESS_POST').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.1),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_selectedTabIndex != 0) {
                            selectedItems.clear();
                          }
                          _selectedTabIndex = 0;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: _selectedTabIndex == 0
                                  ? Theme.of(context).primaryColor
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Text(
                          'Reservations (${reservationItems.length})',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _selectedTabIndex == 0
                                ? Theme.of(context).primaryColor
                                : Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white.withOpacity(0.6)
                                    : Colors.black.withOpacity(0.6),
                            fontWeight: _selectedTabIndex == 0
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_selectedTabIndex != 1) {
                            selectedItems.clear();
                          }
                          _selectedTabIndex = 1;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: _selectedTabIndex == 1
                                  ? Theme.of(context).primaryColor
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Text(
                          'Products (${businessPostItems.length})',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _selectedTabIndex == 1
                                ? Theme.of(context).primaryColor
                                : Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white.withOpacity(0.6)
                                    : Colors.black.withOpacity(0.6),
                            fontWeight: _selectedTabIndex == 1
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: isLoading
                  ? const CartShimmer()
                  : (_selectedTabIndex == 0
                              ? reservationItems
                              : businessPostItems)
                          .isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          itemCount: _selectedTabIndex == 0
                              ? reservationItems.length
                              : businessPostItems.length,
                          itemBuilder: (context, index) {
                            final item = _selectedTabIndex == 0
                                ? reservationItems[index]
                                : businessPostItems[index];
                            final productId =
                                item['productId'] ?? item['reservationId'];
                            final imageUrls = (item['names'] ?? '').split(',');
                            final double price =
                                item['price'] ?? item['pricePerNight'];

                            final caption = item['caption'] ?? item['description'];
                            LogService.logInfo('Caption: $caption');

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: BackdropFilter(
                                  filter:
                                      ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.black.withOpacity(0.7)
                                          : Colors.white.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white.withOpacity(0.1)
                                            : Colors.black.withOpacity(0.1),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                                      barrierColor:
                                                          Colors.black87,
                                                      pageBuilder: (context,
                                                          animation,
                                                          secondaryAnimation) {
                                                        return MediaGalleryView(
                                                          urls: imageUrls,
                                                          initialIndex: 0,
                                                        );
                                                      },
                                                      transitionsBuilder:
                                                          (context,
                                                              animation,
                                                              secondaryAnimation,
                                                              child) {
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
                                                  itemBuilder:
                                                      (context, imgIndex) {
                                                    return Stack(
                                                      children: [
                                                        CachedNetworkImage(
                                                          imageUrl: imageUrls[
                                                              imgIndex],
                                                          fit: BoxFit.cover,
                                                          width:
                                                              double.infinity,
                                                          errorWidget: (context,
                                                                  error,
                                                                  stackTrace) =>
                                                              const Icon(
                                                                  CupertinoIcons
                                                                      .photo,
                                                                  size: 60),
                                                        ),
                                                        if (imageUrls.length >
                                                            1)
                                                          Positioned(
                                                            right: 8,
                                                            bottom: 8,
                                                            child: Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                horizontal: 8,
                                                                vertical: 4,
                                                              ),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: Colors
                                                                    .black54,
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            12),
                                                              ),
                                                              child: Text(
                                                                '${imgIndex + 1}/${imageUrls.length}',
                                                                style:
                                                                    const TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
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
                                                      if (selectedItems
                                                          .contains(
                                                              productId)) {
                                                        selectedItems
                                                            .remove(productId);
                                                      } else {
                                                        selectedItems
                                                            .add(productId);
                                                      }
                                                    });
                                                  },
                                                  child: AnimatedContainer(
                                                    duration: const Duration(
                                                        milliseconds: 200),
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: selectedItems
                                                              .contains(
                                                                  productId)
                                                          ? LarosaColors
                                                              .secondary
                                                              .withOpacity(0.9)
                                                          : Colors.black
                                                              .withOpacity(0.5),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    child: Icon(
                                                      selectedItems.contains(
                                                              productId)
                                                          ? CupertinoIcons
                                                              .checkmark_circle_fill
                                                          : CupertinoIcons
                                                              .circle,
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
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                HelperFunctions.decodeEmoji(
                                                    caption ?? ''),
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w400,
                                                  letterSpacing: -0.5,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 12,
                                                          vertical: 6,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Theme.of(context)
                                                                      .brightness ==
                                                                  Brightness
                                                                      .dark
                                                              ? Colors.white
                                                                  .withOpacity(
                                                                      0.1)
                                                              : Colors.black
                                                                  .withOpacity(
                                                                      0.05),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                        ),
                                                        child: Row(
                                                          children: [
                                                            Text(
                                                              '@${NumberFormat('#,##0', 'en_US').format(price)}',
                                                              style: TextStyle(
                                                                color: Theme.of(context)
                                                                            .brightness ==
                                                                        Brightness
                                                                            .dark
                                                                    ? Colors
                                                                        .white
                                                                        .withOpacity(
                                                                            0.8)
                                                                    : Colors
                                                                        .black
                                                                        .withOpacity(
                                                                            0.8),
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Theme.of(context)
                                                                      .brightness ==
                                                                  Brightness
                                                                      .dark
                                                              ? Colors.white
                                                                  .withOpacity(
                                                                      0.1)
                                                              : Colors.black
                                                                  .withOpacity(
                                                                      0.05),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                        ),
                                                        child: Row(
                                                          children: [
                                                            CupertinoButton(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                horizontal: 8,
                                                                vertical: 0,
                                                              ),
                                                              onPressed: _isUpdatingQuantity[
                                                                          productId] ==
                                                                      true
                                                                  ? null
                                                                  : () => _handleQuantityUpdate(
                                                                      item,
                                                                      item['quantity'] -
                                                                          1,
                                                                      UpdateType
                                                                          .decrease),
                                                              child: Icon(
                                                                CupertinoIcons
                                                                    .minus,
                                                                size: 18,
                                                                color: Theme.of(context)
                                                                            .brightness ==
                                                                        Brightness
                                                                            .dark
                                                                    ? Colors
                                                                        .white
                                                                        .withOpacity(
                                                                            0.8)
                                                                    : Colors
                                                                        .black
                                                                        .withOpacity(
                                                                            0.8),
                                                              ),
                                                            ),
                                                            if (_isUpdatingQuantity[
                                                                    productId] ==
                                                                true)
                                                              const SizedBox(
                                                                width: 20,
                                                                height: 20,
                                                                child:
                                                                    CupertinoActivityIndicator(),
                                                              )
                                                            else
                                                              Text(
                                                                '${_pendingQuantities[productId] ?? item['quantity']}',
                                                                style:
                                                                    TextStyle(
                                                                  color: Theme.of(context)
                                                                              .brightness ==
                                                                          Brightness
                                                                              .dark
                                                                      ? Colors
                                                                          .white
                                                                          .withOpacity(
                                                                              0.8)
                                                                      : Colors
                                                                          .black
                                                                          .withOpacity(
                                                                              0.8),
                                                                  fontSize: 14,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                ),
                                                              ),
                                                            CupertinoButton(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          8,
                                                                      vertical:
                                                                          0),
                                                              onPressed: _isUpdatingQuantity[
                                                                          productId] ==
                                                                      true
                                                                  ? null
                                                                  : () =>
                                                                      _handleQuantityUpdate(
                                                                        item,
                                                                        item['quantity'] +
                                                                            1,
                                                                        UpdateType
                                                                            .increase,
                                                                      ),
                                                              child: Icon(
                                                                CupertinoIcons
                                                                    .plus,
                                                                size: 18,
                                                                color: Theme.of(context)
                                                                            .brightness ==
                                                                        Brightness
                                                                            .dark
                                                                    ? Colors
                                                                        .white
                                                                        .withOpacity(
                                                                            0.8)
                                                                    : Colors
                                                                        .black
                                                                        .withOpacity(
                                                                            0.8),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Text(
                                                    'Tsh ${NumberFormat('#,##0', 'en_US').format(price * item['quantity'])}',
                                                    style: TextStyle(
                                                      color: Theme.of(context)
                                                                  .brightness ==
                                                              Brightness.dark
                                                          ? LarosaColors.primary
                                                          : LarosaColors.purple,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
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
            ),
            Container(
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

                  LogService.logInfo('Selected items: $selectedItems');

                  List<int> productIds = [];
                  double totalPrice = 0.0;
                  int totalQuantity = 0;
                  List<String> combinedNamesList = [];
                  List<Map<String, dynamic>> items = [];
                  List<Map<String, dynamic>> itemsToDisplay = [];

                  LogService.logInfo('Cart items: $cartItems');

                  for (var productId in selectedItems) {
                    // for reservations (selected tab index == 0)
                    LogService.logInfo('selected tab index: $_selectedTabIndex');
                    if (_selectedTabIndex == 0) {
                      var item = reservationItems
                          .firstWhere((item) => item['reservationId'] == productId);

                      LogService.logTrace('reservations: $item');
                      double supplierLongitude =
                          item['supplierLongitude'] ?? 0.0;
                      double supplierLatitude = item['supplierLatitude'] ?? 0.0;

                      productIds.add(item['reservationId']);
                      totalPrice +=
                          (item['pricePerNight'] ?? 0.0) * (item['quantity'] ?? 1);
                      totalQuantity += (item['quantity'] ?? 1) as int;

                      var names = (item['names'] ?? '').split(',');
                      combinedNamesList.addAll(names);

                      items.add({
                        'productId': item['reservationId'],
                        'quantity': item['quantity'] ?? 1
                      });

                      itemsToDisplay.add({
                        'names': item['names'] ?? 'Unnamed Item',
                        'price': item['pricePerNight'],
                        'quantity': item['quantity'] ?? 1,
                        'supplierLongitude': supplierLongitude,
                        'supplierLatitude': supplierLatitude,
                      });
                    } else {
                      var item = cartItems
                          .firstWhere((item) => item['productId'] == productId);

                      LogService.logInfo('item: $item');
                      double supplierLongitude =
                          item['supplierLongitude'] ?? 0.0;
                      double supplierLatitude = item['supplierLatitude'] ?? 0.0;

                      productIds.add(item['productId']);
                      totalPrice +=
                          (item['price'] ?? 0.0) * (item['quantity'] ?? 1);
                      totalQuantity += (item['quantity'] ?? 1) as int;

                      var names = (item['names'] ?? '').split(',');
                      combinedNamesList.addAll(names);

                      items.add({
                        'productId': item['productId'] ?? item['reservationId'],
                        'quantity': item['quantity'] ?? 1
                      });

                      itemsToDisplay.add({
                        'names': item['names'] ?? 'Unnamed Item',
                        'price':
                            item['price'] ?? item['reservationPrice'] ?? 0.0,
                        'quantity': item['quantity'] ?? 1,
                        'supplierLongitude': supplierLongitude,
                        'supplierLatitude': supplierLatitude,
                      });
                    }
                  }

                  String combinedNames = combinedNamesList.join(',');

                  LogService.logInfo('Items to display: $itemsToDisplay');

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
                        reservationType: _selectedTabIndex == 0,
                      ),
                    ),
                  );
                },
                isEnabled: cartItems.isNotEmpty,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
