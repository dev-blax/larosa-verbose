import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../Services/auth_service.dart';
import '../../Services/log_service.dart';
import '../../Utils/colors.dart';
import 'prepare_for_payment.dart';

// Function to list cart items
Future<List<Map<String, dynamic>>> listCartItems(int profileId) async {
  final Uri uri = Uri.https(
    'burnished-core-439210-f6.uc.r.appspot.com',
    '/cart/list',
  );

  try {
    String? token = AuthService.getToken();

    final Map<String, dynamic> requestBody = {
      "profileId": profileId,
    };

    final http.Response response = await http.post(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(requestBody),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(
          data.reversed.map((item) => item as Map<String, dynamic>));
    } else {
      LogService.logError(
          'Failed to list cart items. Status Code: ${response.statusCode}');
      return [];
    }
  } catch (error) {
    LogService.logError('Error in listCartItems: $error');
    return [];
  }
}

Future<void> removeItemFromCart(int profileId, int productId) async {
  final Uri uri = Uri.https(
    'burnished-core-439210-f6.uc.r.appspot.com',
    '/cart/remove-item',
  );

  try {
    String? token = AuthService.getToken();

    final Map<String, dynamic> requestBody = {
      "profileId": profileId,
      "items": [
        {"postId": productId, "quantity": 1}
      ]
    };

    final http.Response response = await http.post(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(requestBody),
    );
    if (response.statusCode == 200) {
      LogService.logInfo('Item removed from cart successfully.');
    } else {
      LogService.logError(
        'Failed to remove item from cart. Status Code: ${response.statusCode}',
      );
    }
  } catch (error) {
    LogService.logError('Error in removeItemFromCart: $error');
  }
}

// Widget to display cart items with delete and payment checkbox functionality
class MyCart extends StatefulWidget {
  @override
  _MyCartState createState() => _MyCartState();
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
    int profileId =
        AuthService.getProfileId() ?? 0; // Replace with actual profile ID logic
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
                itemCount: cartItems.length,
                itemBuilder: (context, index) {
                  final item = cartItems[index];
                  final productId = item['productId'];
                  final imageUrls =
                      (item['names'] ?? '').split(','); // Split names by commas

                  return Card(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.black
                        : Colors.white,
                    margin:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CheckboxListTile(
                            contentPadding: EdgeInsets
                                .zero, // No padding around CheckboxListTile
                            // checkColor: Colors.grey,
                            activeColor:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                            value: selectedItems.contains(productId),
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  selectedItems.add(productId);
                                } else {
                                  selectedItems.remove(productId);
                                }
                              });
                            },
                            title: Text(
                              item['caption'] ?? 'Unnamed Product',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                          const SizedBox(height: 1),
                          SizedBox(
                            height: 100, // Height for the image row
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: imageUrls.length,
                              itemBuilder: (context, imgIndex) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    imageUrls[imgIndex],
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(Icons.broken_image,
                                                size: 100),
                                  ),
                                );
                              },
                              separatorBuilder: (context, _) =>
                                  const SizedBox(width: 8),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Quantity: ${item['quantity']}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Price: Tsh ${NumberFormat('#,##0', 'en_US').format(item['price'])}',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
        bottomNavigationBar: Container(
          margin: const EdgeInsets.symmetric(
              vertical: 4, horizontal: 20), // Adjust horizontal padding
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [LarosaColors.secondary, LarosaColors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30), // Rounded corners
          ),
          child: FilledButton(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(Colors.transparent),
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              ),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    30, // Ensures button shape matches container
                  ),
                ),
              ),
            ),
            // onPressed: () {
            //   // Ensure at least one item is selected
            //   if (selectedItems.isEmpty) {
            //     ScaffoldMessenger.of(context).showSnackBar(
            //       const SnackBar(
            //         content: Text("No items selected for payment."),
            //       ),
            //     );
            //     return;
            //   }

            //   // Variables to hold data for PrepareForPayment
            //   List<int> productIds = [];
            //   double totalPrice = 0.0;
            //   int totalQuantity = 0; // Variable to track total quantity
            //   List<String> combinedNamesList = [];
            //   List<Map<String, dynamic>> items =
            //       []; // Array to hold detailed items
            //   List<Map<String, dynamic>> itemsToDisplay = [];

            //   // Collect details for each selected item
            //   for (var productId in selectedItems) {
            //     var item = cartItems
            //         .firstWhere((item) => item['productId'] == productId);

            //     productIds.add(item['productId']); // Add product ID to the list
            //     totalPrice += (item['price'] ?? 0.0) *
            //         (item['quantity'] ?? 1); // Sum up the total price
            //     totalQuantity += (item['quantity'] ?? 1)
            //         as int; // Cast to int to avoid type issues // Add to total quantity

            //     var names =
            //         (item['names'] ?? '').split(','); // Split names into a list
            //     combinedNamesList
            //         .addAll(names); // Add names to the combined list

            //     // Add detailed item to items array
            //     items.add({
            //       'productId': item['productId'],
            //       'quantity': item['quantity'] ?? 1
            //     });
            //   }

            //   // Combine all names into a single string
            //   String combinedNames = combinedNamesList.join(',');

            //   // Debugging prints
            //   // print('Product IDs: $productIds');
            //   // print('Total Price: \$${totalPrice.toStringAsFixed(2)}');
            //   // print('Total Quantity: $totalQuantity');
            //   // print('Combined Names: $combinedNames');
            //   // print('Items: $items');

            //   // Navigate to PrepareForPayment screen
            //   Navigator.push(
            //     context,
            //     MaterialPageRoute(
            //       builder: (context) => PrepareForPayment(
            //         productIds: productIds,
            //         totalPrice: totalPrice,
            //         totalQuantity: totalQuantity,
            //         combinedNames: combinedNames,
            //         items: items,
            //         reservationType: false,
            //       ),
            //     ),
            //   );
            // },

            onPressed: () {
              // Ensure at least one item is selected
              if (selectedItems.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("No items selected for payment."),
                  ),
                );
                return;
              }

              // Variables to hold data for PrepareForPayment
              List<int> productIds = [];
              double totalPrice = 0.0;
              int totalQuantity = 0; // Variable to track total quantity
              List<String> combinedNamesList = [];
              List<Map<String, dynamic>> items =
                  []; // Array to hold detailed items
              List<Map<String, dynamic>> itemsToDisplay =
                  []; // Array to display the items

              // Collect details for each selected item
              for (var productId in selectedItems) {
                var item = cartItems
                    .firstWhere((item) => item['productId'] == productId);

                productIds.add(item['productId']); // Add product ID to the list
                totalPrice += (item['price'] ?? 0.0) *
                    (item['quantity'] ?? 1); // Sum up the total price
                totalQuantity +=
                    (item['quantity'] ?? 1) as int; // Add to total quantity

                var names =
                    (item['names'] ?? '').split(','); // Split names into a list
                combinedNamesList
                    .addAll(names); // Add names to the combined list

                // Add detailed item to items array
                items.add({
                  'productId': item['productId'],
                  'quantity': item['quantity'] ?? 1
                });

                // Add item details for display
                itemsToDisplay.add({
                  'names': item['names'] ?? 'Unnamed Item', // Add the name
                  'price': item['price'] ?? 0.0, // Add the price
                  'quantity': item['quantity'] ?? 1, // Add the quantity
                });
              }

              // Combine all names into a single string
              String combinedNames = combinedNamesList.join(',');

              // Debugging prints
              // print('Product IDs: $productIds');
              // print('Total Price: \$${totalPrice.toStringAsFixed(2)}');
              // print('Total Quantity: $totalQuantity');
              // print('Combined Names: $combinedNames');
              // print('Items: $items');
              // print('Items to Display: $itemsToDisplay');

              // Navigate to PrepareForPayment screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PrepareForPayment(
                    productIds: productIds,
                    totalPrice: totalPrice,
                    totalQuantity: totalQuantity,
                    combinedNames: combinedNames,
                    items: items,
                    itemsToDisplay:
                        itemsToDisplay, // Pass itemsToDisplay to the screen
                    reservationType: false,
                  ),
                ),
              );
            },
            child: const Text(
              'Proceed to Payment',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w600, // Semi-bold for emphasis
                letterSpacing: 1.0, // Add slight spacing for a clean look
              ),
            ),
          ),
        ));
  }
}
