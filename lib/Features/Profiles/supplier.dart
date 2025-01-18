import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:larosa_block/Utils/helpers.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../../Services/auth_service.dart';
import '../../Services/log_service.dart';
import '../../Utils/links.dart';
import '../../Utils/colors.dart';

class SupplierDashboard extends StatefulWidget {
  final String supplierId;

  const SupplierDashboard({Key? key, required this.supplierId})
      : super(key: key);

  @override
  State<SupplierDashboard> createState() => _SupplierDashboardState();
}

class _SupplierDashboardState extends State<SupplierDashboard> {
  late StompClient stompClient;
  final ValueNotifier<List<Map<String, dynamic>>> supplierNotifications =
      ValueNotifier<List<Map<String, dynamic>>>([]); // Use ValueNotifier
  int pageNumber = 0;
  bool isLoading = false;

  final String token = AuthService.getToken();

 Future<void> _loadNotifications() async {
  if (isLoading) return;

  setState(() {
    isLoading = true;
  });

  final String url =
      '${LarosaLinks.baseurl}/api/v1/notifications/supplier/$pageNumber';

  try {
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    HelperFunctions.larosaLogger(response.body);

    if (response.statusCode == 200) {
      final List<dynamic> notifications = jsonDecode(response.body);

        // Update the ValueNotifier with fresh data
        supplierNotifications.value = notifications.map((dynamic notification) {
          return {
            ...(notification as Map<String, dynamic>),
            'isAcknowledgeLoading': false,
            'isReadyLoading': false,
          };
        }).toList();

      pageNumber++;
    } else {
      LogService.logError(
          'Failed to fetch notifications: ${response.statusCode}');
    }
  } catch (e) {
    LogService.logError('Error fetching notifications: $e');
  } finally {
    setState(() {
      isLoading = false;
    });
  }
}


  Future<void> initializeWebSocket(String supplierId) async {
    stompClient = StompClient(
      config: StompConfig.sockJS(
        url: LarosaLinks.socketUrl,
        onConnect: (StompFrame frame) {
          LogService.logInfo('Connected to WebSocket');
          subscribeToChannel(supplierId);
        },
        onWebSocketError: (dynamic error) {
          LogService.logError('WebSocket error: $error');
        },
        onDisconnect: (StompFrame frame) =>
            LogService.logFatal('Disconnected from WebSocket'),
      ),
    );
    stompClient.activate();
  }

  void subscribeToChannel(String supplierId) {
    final String supplierChannel = '/topic/supplier/$supplierId';

    stompClient.subscribe(
      destination: supplierChannel,
      callback: (StompFrame frame) {
        if (frame.body != null) {
          // Reload notifications after successful acknowledgment
          _loadNotifications();
        }
      },
    );
  }

  void closeWebSocketConnection() {
    if (stompClient.isActive) {
      stompClient.deactivate();
      LogService.logInfo('WebSocket connection closed');
    }
  }

  Future<void> acknowledgeNotification(int? notificationId, int? productId, int index) async {
  if (notificationId == null || productId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invalid data. Cannot acknowledge.')),
    );
    return;
  }

  final String endpoint =
      '${LarosaLinks.baseurl}/api/v1/notifications/acknowledge/$notificationId';
  final Map<String, dynamic> requestBody = {productId.toString(): true};

  await handleNotificationAction(
    endpoint: endpoint,
    index: index,
    loadingKey: 'isAcknowledgeLoading',
    requestBody: requestBody,
  );
}


Future<void> markAsReadyForPickup(int? notificationId, int? productId, int index) async {
  if (notificationId == null || productId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invalid data. Cannot mark as ready.')),
    );
    return;
  }

  final String endpoint =
      '${LarosaLinks.baseurl}/api/v1/notifications/ready-for-pickup/$notificationId';

  await handleNotificationAction(
    endpoint: endpoint,
    index: index,
    loadingKey: 'isReadyLoading',
  );
}

  Future<void> handleNotificationAction({
    required String endpoint,
    required int index,
    required String loadingKey,
    Map<String, dynamic>? requestBody,
  }) async {
    // Set loading state
    supplierNotifications.value[index][loadingKey] = true;
    supplierNotifications.notifyListeners();

  try {
    final response = await http.post(
      Uri.parse(endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: requestBody != null ? jsonEncode(requestBody) : null,
    );


      if (response.statusCode == 200) {
        // Update local state immediately
        if (loadingKey == 'isAcknowledgeLoading') {
          supplierNotifications.value[index]['confirmed'] = true;
        } else if (loadingKey == 'isReadyLoading') {
          supplierNotifications.value[index]['readyForPickup'] = true;
        }
        supplierNotifications.notifyListeners();

      } else {
        LogService.logError('Failed to complete action: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${response.body}')),
        );
      }
    } catch (e) {
      LogService.logError('Error completing action: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      // Reset loading state
      supplierNotifications.value[index][loadingKey] = false;
      supplierNotifications.notifyListeners();
    }
  }

  @override
  void initState() {
    super.initState();
    print(AuthService.isReservation());
    initializeWebSocket(widget.supplierId);
    _loadNotifications();
  }

  @override
  void dispose() {
    // closeWebSocketConnection();
    super.dispose();
  }

  Widget buildNotificationCard(Map<String, dynamic> notification, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(1.0),
              child: Row(
                children: [
                  const Icon(Icons.notifications, size: 24.0),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order ID: ${notification['orderId']}',
                          style: const TextStyle(
                            fontSize: 15.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          'Sent At: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(notification['sentAt']))}',
                          style: TextStyle(
                            fontSize: 14.0,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),

            // Product Details
            const Text(
              'Product Details:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Product Details List
            ...notification['productDetails'].map<Widget>((product) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Card(
                  elevation: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 2.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(3.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Product ID: ${product['id']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Tsh ${NumberFormat('#,##0', 'en_US').format(product['price'])}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Caption and Unit Name
                        Text(
                          '${product['caption']}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
//                       RichText(
//   text: TextSpan(
//     children: [
//       const TextSpan(
//         text: 'Karibu kwa ', // Static part
//         style: TextStyle(
//           fontSize: 14,
//           fontWeight: FontWeight.w500,
//           color: Colors.grey,
//           // color: Theme.of(context).colorScheme.onSecondaryContainer,
//         ),
//       ),
//       TextSpan(
//         text: 'Aslay Mihogo', // Stylized dynamic part
//         style: TextStyle(
//           fontSize: 14, // Slightly larger for emphasis
//           fontWeight: FontWeight.bold,
//           fontStyle: FontStyle.italic, // Adds creative flair
//           color: Theme.of(context).colorScheme.primary, // Highlight color
//         ),
//       ),
//       TextSpan(
//         text: '!', // Closing punctuation
//         style: TextStyle(
//           fontSize: 14,
//           fontWeight: FontWeight.w500,
//           color: Theme.of(context).colorScheme.onSecondaryContainer,
//         ),
//       ),
//     ],
//   ),
// ),

                        const SizedBox(height: 8),
                        Text(
                          'Unit: ${product['unitName']}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const Divider(height: 20, thickness: 1),

                        // Additional Product Details
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Availability',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                Text('${product['availabilityStatus']}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                    )),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Weight',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                Text(
                                    '${product['weightCategoryName']?.toUpperCase()}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                    )),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Size',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                                Text(
                                  '${product['sizeCategoryName']?.toUpperCase()}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Quantity
                        Text(
                          'Quantity: ${product['quantity']}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(height: 20, thickness: 1),

                        // Product Images
                        if (product['names'] != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Product Images:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children:
                                      product['names'].map<Widget>((imageUrl) {
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(right: 8.0),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          imageUrl,
                                          height: 100,
                                          width: 100,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),

                        const SizedBox(
                          height: 5,
                        ),
                        const Divider(),

                        // Confirm Button (Inside Product Details)
                        if (!notification['confirmed'])
                          buildCustomButton(
                            label: 'Confirm',
                            onTap: () => acknowledgeNotification(
                                notification['notificationId'],
                                product['id'],
                                index),
                            isLoading: notification['isAcknowledgeLoading'],
                          ),

                        // Mark Ready for Pickup Button
                        if (notification['confirmed'] &&
                            !notification['readyForPickup'])
                          buildCustomButton(
                            label: 'Mark Ready for Pickup',
                            onTap: () => markAsReadyForPickup(
                                notification['notificationId'],
                                product['id'],
                                index),
                            isLoading: notification['isReadyLoading'],
                          ),

                        // Success Message
                        if (notification['confirmed'] &&
                            notification['readyForPickup'])
                          Container(
                            padding: const EdgeInsets.all(10),
                            margin: const EdgeInsets.only(top: 10),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle,
                                    color: Colors.green),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Order ${notification['orderId']} is ready for pickup! 🎉',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget buildCustomButton({
    required String label,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: double.infinity,
          minHeight: 50, 
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: const LinearGradient(
              colors: [LarosaColors.primary, LarosaColors.secondary],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: isLoading
              ? const Center(
                  child: CupertinoActivityIndicator(),
                )
              : Center(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // print(supplierNotifications);
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(
              CupertinoIcons.back,
            ),
            onPressed: () => context.pop(),
          ),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          elevation: 1,
          centerTitle: false,
          title: Row(
            children: [
              // CircleAvatar(
              //   radius: 16,
              //   backgroundColor:
              //       Theme.of(context).colorScheme.secondaryContainer,
              //   child: Icon(
              //     Icons.business_center,
              //     color: Theme.of(context).colorScheme.onSecondaryContainer,
              //     size: 20,
              //   ),
              // ),
              // const SizedBox(width: 12),
              Text(
                'Supplier Dashboard',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: Theme.of(context).appBarTheme.foregroundColor,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                softWrap: false,
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.notifications_outlined,
                color: Theme.of(context).appBarTheme.foregroundColor,
              ),
              onPressed: () {
                // Notification action
              },
            ),
            IconButton(
              icon: Icon(
                Icons.settings_outlined,
                color: Theme.of(context).appBarTheme.foregroundColor,
              ),
              onPressed: () {
                // Settings action
              },
            ),
          ],
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(
                  16), // Smooth rounded bottom for a premium feel
            ),
          ),
        ),
        body: ValueListenableBuilder<List<Map<String, dynamic>>>(
          valueListenable: supplierNotifications,
          builder: (context, notifications, child) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  ...notifications.map((notification) {
                    final int index = notifications.indexOf(notification);
                    return buildNotificationCard(notification, index);
                  }),
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CupertinoActivityIndicator(),
                    )
                  else
                    ElevatedButton(
                      onPressed: _loadNotifications,
                      child: const Text('Load More Notifications'),
                    ),
                ],
              ),
            );
          },
        ));
  }
}
