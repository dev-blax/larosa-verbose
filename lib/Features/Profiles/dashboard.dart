// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:stomp_dart_client/stomp_dart_client.dart';
// import '../../Services/auth_service.dart';
// import '../../Services/log_service.dart';
// import '../../Utils/links.dart';
// import '../../Utils/colors.dart';

// class SupplierDashboard extends StatefulWidget {
//   final String supplierId;

//   const SupplierDashboard({Key? key, required this.supplierId})
//       : super(key: key);

//   @override
//   _SupplierDashboardState createState() => _SupplierDashboardState();
// }

// class _SupplierDashboardState extends State<SupplierDashboard> {
//   late StompClient stompClient;
//   final List<Map<String, dynamic>> supplierNotifications = [];

//   Future<void> initializeWebSocket(String supplierId) async {
//     stompClient = StompClient(
//       config: StompConfig.sockJS(
//         url: LarosaLinks.socketUrl,
//         onConnect: (StompFrame frame) {
//           LogService.logInfo('Connected to WebSocket');
//           subscribeToChannel(supplierId);
//         },
//         onWebSocketError: (dynamic error) {
//           LogService.logError('WebSocket error: $error');
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('WebSocket error: $error')),
//           );
//         },
//         onStompError: (StompFrame frame) =>
//             LogService.logWarning('Stomp error: ${frame.body}'),
//         onDisconnect: (StompFrame frame) =>
//             LogService.logFatal('Disconnected from WebSocket'),
//       ),
//     );
//     stompClient.activate();
//   }

//   void subscribeToChannel(String supplierId) {
//     final String supplierChannel = '/topic/supplier/$supplierId';

//     stompClient.subscribe(
//       destination: supplierChannel,
//       callback: (StompFrame frame) {
//         LogService.logInfo('Raw notification received: ${frame.body}');

//         if (frame.body != null) {
//           final Map<String, dynamic> notification = jsonDecode(frame.body!);
//           setState(() {
//             supplierNotifications.add({
//               'id': notification['id'],
//               'message': notification['message'],
//               'isAcknowledgeLoading': false,
//               'isReadyLoading': false,
//             });
//           });
//           LogService.logInfo('Notification received: ${frame.body}');
//         }
//       },
//     );
//   }

//   void closeWebSocketConnection() {
//     if (stompClient.isActive) {
//       stompClient.deactivate();
//       LogService.logInfo('WebSocket connection closed');
//     }
//   }

//   Future<void> acknowledgeNotification(int notificationId, int index) async {
//     final String endpoint =
//         '${LarosaLinks.baseurl}/notifications/acknowledge/$notificationId';
//     setState(() {
//       supplierNotifications[index]['isAcknowledgeLoading'] = true;
//     });

//     try {
//       final response = await http.post(
//         Uri.parse(endpoint),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({'notificationId': notificationId}),
//       );
//       if (response.statusCode == 200) {
//         LogService.logInfo('Acknowledged: ${response.body}');
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Notification acknowledged')),
//         );
//       } else {
//         LogService.logError('Failed to acknowledge: ${response.body}');
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to acknowledge: ${response.body}')),
//         );
//       }
//     } catch (e) {
//       LogService.logError('Error acknowledging notification: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     } finally {
//       setState(() {
//         supplierNotifications[index]['isAcknowledgeLoading'] = false;
//       });
//     }
//   }

//   Future<void> markAsReadyForPickup(int notificationId, int index) async {
//     final String endpoint =
//         '${LarosaLinks.baseurl}/notifications/ready-for-pickup/$notificationId';
//     setState(() {
//       supplierNotifications[index]['isReadyLoading'] = true;
//     });

//     try {
//       final response = await http.post(Uri.parse(endpoint));
//       if (response.statusCode == 200) {
//         LogService.logInfo('Marked as ready: ${response.body}');
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Marked as ready for pickup')),
//         );
//       } else {
//         LogService.logError('Failed to mark as ready: ${response.body}');
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to mark as ready: ${response.body}')),
//         );
//       }
//     } catch (e) {
//       LogService.logError('Error marking as ready: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     } finally {
//       setState(() {
//         supplierNotifications[index]['isReadyLoading'] = false;
//       });
//     }
//   }

//   @override
//   void initState() {
//     super.initState();
//     initializeWebSocket(widget.supplierId);

//     print(AuthService.getToken());
//   }

//   @override
//   void dispose() {
//     closeWebSocketConnection();
//     super.dispose();
//   }

//   Widget buildCustomButton({
//     required String label,
//     required VoidCallback onTap,
//     bool isLoading = false,
//   }) {
//     return GestureDetector(
//       onTap: isLoading ? null : onTap,
//       child: Container(
//         margin: const EdgeInsets.symmetric(vertical: 2),
//         padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(8),
//           gradient: const LinearGradient(
//             colors: [LarosaColors.primary, LarosaColors.secondary],
//             begin: Alignment.centerLeft,
//             end: Alignment.centerRight,
//           ),
//         ),
//         child: isLoading
//             ? const Center(
//                 child: CircularProgressIndicator(
//                   strokeWidth: 2,
//                   valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                 ),
//               )
//             : Text(
//                 label,
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 15,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Theme.of(context)
//             .appBarTheme
//             .backgroundColor, // Adapts to the system theme
//         elevation: 2, // Minimal shadow for a clean look
//         centerTitle: true, // Title is centered for balance
//         title: Text(
//           'Supplier Dashboard',
//           style: TextStyle(
//             fontSize: 20,
//             fontWeight: FontWeight.w600,
//             letterSpacing: 1.0, // Elegant spacing
//             color: Theme.of(context)
//                 .appBarTheme
//                 .foregroundColor, // Matches the theme
//           ),
//         ),
//         shape: const RoundedRectangleBorder(
//           borderRadius: BorderRadius.vertical(
//             bottom: Radius.circular(20), // Smoothly rounded bottom edge
//           ),
//         ),
//         bottom: PreferredSize(
//           preferredSize:
//               const Size.fromHeight(50), // Additional height for bottom design
//           child: Container(
//             decoration: BoxDecoration(
//               color: Theme.of(context)
//                   .colorScheme
//                   .secondaryContainer, // Adapts to theme
//               borderRadius: const BorderRadius.vertical(
//                 bottom: Radius.circular(20), // Matches the AppBar shape
//               ),
//             ),
//             alignment: Alignment.center,
//             child: Padding(
//               padding: const EdgeInsets.all(12.0),
//               child: Text(
//                 'Welcome back! Stay on top of your tasks 🚀',
//                 style: TextStyle(
//                   fontSize: 14,
//                   fontStyle: FontStyle.italic,
//                   fontWeight: FontWeight.w500,
//                   color: Theme.of(context)
//                       .colorScheme
//                       .onSecondaryContainer, // Text matches theme
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             ...supplierNotifications.map((notification) {
//               final int index = supplierNotifications.indexOf(notification);
//               return Card(
//                 margin: const EdgeInsets.all(8.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     ListTile(
//                       leading: const Icon(Icons.notifications),
//                       title: Text('Notification ID: ${notification['id']}'),
//                       subtitle: Text('Message: ${notification['message']}'),
//                     ),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceAround,
//                       children: [
//                         buildCustomButton(
//                           label: 'Acknowledge',
//                           onTap: () => acknowledgeNotification(
//                               notification['id'], index),
//                           isLoading: notification['isAcknowledgeLoading'],
//                         ),
//                         buildCustomButton(
//                           label: 'Mark Ready',
//                           onTap: () =>
//                               markAsReadyForPickup(notification['id'], index),
//                           isLoading: notification['isReadyLoading'],
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               );
//             }),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'dart:convert';
import 'package:flutter/material.dart';
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
  _SupplierDashboardState createState() => _SupplierDashboardState();
}

class _SupplierDashboardState extends State<SupplierDashboard> {
  late StompClient stompClient;
  List<Map<String, dynamic>> supplierNotifications = [];
  int pageNumber = 0;
  bool isLoading = false;

  final String token = AuthService.getToken();

  // Future<void> _loadNotifications() async {
  //   if (isLoading) return;

  //   setState(() {
  //     isLoading = true;
  //   });

  //   final String url =
  //       '${LarosaLinks.baseurl}/api/v1/notifications/supplier/$pageNumber';

  //   try {
  //     final response = await http.get(
  //       Uri.parse(url),
  //       headers: {
  //         'Content-Type': 'application/json',
  //         'Authorization': 'Bearer $token',
  //       },
  //     );
  //     print(response.body);
  //     if (response.statusCode == 200) {
  //       final List<dynamic> notifications = jsonDecode(response.body);
  //       setState(() {
  //         supplierNotifications.addAll(notifications.map((notification) {
  //           return {
  //             'id': notification['orderId'],
  //             'message': notification['caption'],
  //             'isAcknowledgeLoading': false,
  //             'isReadyLoading': false,
  //           };
  //         }).toList());
  //       });
  //       pageNumber++;
  //     } else {
  //       LogService.logError(
  //           'Failed to fetch notifications: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     LogService.logError('Error fetching notifications: $e');
  //   } finally {
  //     setState(() {
  //       isLoading = false;
  //     });
  //   }
  // }

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
        setState(() {
          // Add notifications with state management fields
          supplierNotifications.addAll(
            notifications.map((dynamic notification) {
              return {
                ...(notification as Map<String, dynamic>),
                'isAcknowledgeLoading': false,
                'isReadyLoading': false,
              };
            }).toList(),
          );
        });
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
          final Map<String, dynamic> notification = jsonDecode(frame.body!);
          setState(() {
            supplierNotifications.insert(0, {
              'id': notification['orderId'],
              'message': notification['caption'],
              'isAcknowledgeLoading': false,
              'isReadyLoading': false,
            });
          });
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

  // Future<void> acknowledgeNotification(int notificationId, int index) async {
  //   final String endpoint =
  //       '${LarosaLinks.baseurl}/notifications/acknowledge/$notificationId';
  //   setState(() {
  //     supplierNotifications[index]['isAcknowledgeLoading'] = true;
  //   });

  //   try {
  //     final response = await http.post(
  //       Uri.parse(endpoint),
  //       headers: {'Content-Type': 'application/json'},
  //       body: jsonEncode({'notificationId': notificationId}),
  //     );
  //     print(response.statusCode);
  //     if (response.statusCode == 200) {
  //       // LogService.logInfo('Acknowledged: ${response.body}');
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('Notification acknowledged')),
  //       );
  //     } else {
  //       // LogService.logError('Failed to acknowledge: ${response.body}');
  //       // ScaffoldMessenger.of(context).showSnackBar(
  //       //   SnackBar(content: Text('Failed to acknowledge: ${response.body}')),
  //       // );
  //     }
  //   } catch (e) {
  //     LogService.logError('Error acknowledging notification: $e');
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Error: $e')),
  //     );
  //   } finally {
  //     setState(() {
  //       supplierNotifications[index]['isAcknowledgeLoading'] = false;
  //     });
  //   }
  // }

  Future<void> acknowledgeNotification(
      int? notificationId, int? productId, int index) async {
    if (notificationId == null || productId == null) {
      print(
          'Invalid IDs: notificationId=$notificationId, productId=$productId');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid data. Cannot acknowledge.')),
      );
      return;
    }
// print('Invalid IDs: notificationId=$notificationId, productId=$productId');
    final String token = AuthService.getToken(); // Get the token
    final String endpoint =
        '${LarosaLinks.baseurl}/api/v1/notifications/acknowledge/$notificationId';

    // Create the request body with dynamic key
    final Map<String, dynamic> requestBody = {productId.toString(): true};

    setState(() {
      supplierNotifications[index]['isAcknowledgeLoading'] = true;
    });

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Add the Authorization header
        },
        body: jsonEncode(requestBody), // Send dynamic key-value pair
      );
      print('Responce status code : ${response.statusCode}');
      print('Responce body : ${response.body}');
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification acknowledged')),
        );

        // Reload notifications after successful acknowledgment
        await _loadNotifications();
      } else {
        LogService.logError('Failed to acknowledge: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to acknowledge: ${response.body}')),
        );
      }
    } catch (e) {
      LogService.logError('Error acknowledging notification: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        supplierNotifications[index]['isAcknowledgeLoading'] = false;
      });
    }
  }

  // Future<void> markAsReadyForPickup(int notificationId, int index) async {
  //   final String endpoint =
  //       '${LarosaLinks.baseurl}/notifications/ready-for-pickup/$notificationId';
  //   setState(() {
  //     supplierNotifications[index]['isReadyLoading'] = true;
  //   });

  //   try {
  //     final response = await http.post(Uri.parse(endpoint));
  //     if (response.statusCode == 200) {
  //       // LogService.logInfo('Marked as ready: ${response.body}');
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('Marked as ready for pickup')),
  //       );
  //     } else {
  //       // LogService.logError('Failed to mark as ready: ${response.body}');
  //       // ScaffoldMessenger.of(context).showSnackBar(
  //       //   SnackBar(content: Text('Failed to mark as ready: ${response.body}')),
  //       // );
  //     }
  //   } catch (e) {
  //     LogService.logError('Error marking as ready: $e');
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Error: $e')),
  //     );
  //   } finally {
  //     setState(() {
  //       supplierNotifications[index]['isReadyLoading'] = false;
  //     });
  //   }
  // }

  Future<void> markAsReadyForPickup(int notificationId, int index) async {
    final String token = AuthService.getToken(); // Fetch the token
    final String endpoint =
        '${LarosaLinks.baseurl}/api/v1/notifications/ready-for-pickup/$notificationId';

    setState(() {
      supplierNotifications[index]['isReadyLoading'] = true;
    });

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Add the Authorization header
        },
      );

      print(response.statusCode);
      print(response.body);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Marked as ready for pickup')),
        );

        // Reload notifications after successful acknowledgment
        await _loadNotifications();
      } else {
        LogService.logError('Failed to mark as ready: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to mark as ready: ${response.body}')),
        );
      }
    } catch (e) {
      LogService.logError('Error marking as ready: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        supplierNotifications[index]['isReadyLoading'] = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
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
              // decoration: BoxDecoration(
              //   border: Border(
              //     bottom: BorderSide(color: Colors.grey.shade300),
              //   ),
              // ),
              child: Row(
                children: [
                  const Icon(Icons.notifications, size: 24.0),
                  const SizedBox(
                      width: 16.0), // Space between the icon and text
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
                        const SizedBox(
                            height: 4.0), // Space between title and subtitle
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
                  elevation: 3,
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
                                Text('${product['availabilityStatus']}', style: const TextStyle(
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
                                Text('${product['weightCategoryName']?.toUpperCase()}', style: const TextStyle(
                            fontSize: 12,
                          )),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Size',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                Text('${product['sizeCategoryName']?.toUpperCase()}', style: const TextStyle(
                            fontSize: 12,
                          ),),
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
                                notification['notificationId'], index),
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
          minWidth: double.infinity, // Full width
          minHeight: 50, // Set a minimum height for the button
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
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Center(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
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
    print(supplierNotifications);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context)
            .appBarTheme
            .backgroundColor, // Matches the system theme
        elevation: 1, // Subtle shadow for a polished look
        centerTitle: false, // Left-aligned title for a professional tone
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              child: Icon(
                Icons.business_center,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
                size: 20, // Icon size within the avatar
              ),
            ),
            const SizedBox(width: 12), // Space between avatar and title
            Text(
              'Supplier Dashboard',
              style: TextStyle(
                fontSize: 18, // Professional and readable size
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: Theme.of(context).appBarTheme.foregroundColor,
              ),
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
            bottom:
                Radius.circular(16), // Smooth rounded bottom for a premium feel
          ),
        ),
        bottom: PreferredSize(
          preferredSize:
              const Size.fromHeight(60), // Extended height for modern look
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .secondaryContainer, // Clean, modern theme
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16), // Matches the AppBar shape
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Welcome back, Aslay Mihogo!', // Dynamic welcome text
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    // Action for "View Insights"
                  },
                  icon: Icon(
                    Icons.insights_outlined,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  label: Text(
                    'View Insights',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ...supplierNotifications.map((notification) {
              final int index = supplierNotifications.indexOf(notification);
              return buildNotificationCard(notification, index);
            }),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              )
            else
              ElevatedButton(
                onPressed: _loadNotifications,
                child: const Text('Load More Notifications'),
              ),
          ],
        ),
      ),
    );
  }
}