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

  Future<void> _loadNotifications() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    final String token = AuthService.getToken();
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

      if (response.statusCode == 200) {
        final List<dynamic> notifications = jsonDecode(response.body);
        setState(() {
          supplierNotifications.addAll(notifications.map((notification) {
            return {
              'id': notification['orderId'],
              'message': notification['caption'],
              'isAcknowledgeLoading': false,
              'isReadyLoading': false,
            };
          }).toList());
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

  Future<void> acknowledgeNotification(int notificationId, int index) async {
    final String endpoint =
        '${LarosaLinks.baseurl}/notifications/acknowledge/$notificationId';
    setState(() {
      supplierNotifications[index]['isAcknowledgeLoading'] = true;
    });

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'notificationId': notificationId}),
      );
      if (response.statusCode == 200) {
        // LogService.logInfo('Acknowledged: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification acknowledged')),
        );
      } else {
        // LogService.logError('Failed to acknowledge: ${response.body}');
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text('Failed to acknowledge: ${response.body}')),
        // );
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

  Future<void> markAsReadyForPickup(int notificationId, int index) async {
    final String endpoint =
        '${LarosaLinks.baseurl}/notifications/ready-for-pickup/$notificationId';
    setState(() {
      supplierNotifications[index]['isReadyLoading'] = true;
    });

    try {
      final response = await http.post(Uri.parse(endpoint));
      if (response.statusCode == 200) {
        // LogService.logInfo('Marked as ready: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Marked as ready for pickup')),
        );
      } else {
        // LogService.logError('Failed to mark as ready: ${response.body}');
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text('Failed to mark as ready: ${response.body}')),
        // );
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
    closeWebSocketConnection();
    super.dispose();
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
            .backgroundColor, // Adapts to the system theme
        elevation: 2, // Minimal shadow for a clean look
        centerTitle: true, // Title is centered for balance
        title: Text(
          'Supplier Dashboard',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0, // Elegant spacing
            color: Theme.of(context)
                .appBarTheme
                .foregroundColor, // Matches the theme
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20), // Smoothly rounded bottom edge
          ),
        ),
        bottom: PreferredSize(
          preferredSize:
              const Size.fromHeight(50), // Additional height for bottom design
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .secondaryContainer, // Adapts to theme
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(20), // Matches the AppBar shape
              ),
            ),
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                'Welcome back! Stay on top of your tasks 🚀',
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context)
                      .colorScheme
                      .onSecondaryContainer, // Text matches theme
                ),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ...supplierNotifications.map((notification) {
              final int index = supplierNotifications.indexOf(notification);
              return
                  // Card(
                  //   margin: const EdgeInsets.all(8.0),
                  //   child: Column(
                  //     crossAxisAlignment: CrossAxisAlignment.start,
                  //     children: [
                  //       ListTile(
                  //         leading: const Icon(Icons.notifications),
                  //         title: Text('Notification ID: ${notification['id']}'),
                  //         subtitle: Text('Message: ${notification['message']}'),
                  //       ),
                  //       Row(
                  //         mainAxisAlignment: MainAxisAlignment.spaceAround,
                  //         children: [
                  //           buildCustomButton(
                  //             label: 'Acknowledge',
                  //             onTap: () => acknowledgeNotification(
                  //                 notification['id'], index),
                  //             isLoading: notification['isAcknowledgeLoading'],
                  //           ),
                  //           buildCustomButton(
                  //             label: 'Mark Ready',
                  //             onTap: () =>
                  //                 markAsReadyForPickup(notification['id'], index),
                  //             isLoading: notification['isReadyLoading'],
                  //           ),
                  //         ],
                  //       ),
                  //     ],
                  //   ),
                  // );

                  Card(
  margin: const EdgeInsets.all(8.0),
  child: Padding(
    padding: const EdgeInsets.all(8.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: const Icon(Icons.notifications),
          title: Text('Notification ID: ${notification['id']}'),
          subtitle: Text('Message: ${notification['message']}'),
        ),
        const SizedBox(height: 8), // Space between ListTile and buttons

        // Acknowledge button
        if (!notification['isAcknowledgeLoading'] &&
            !notification['isReadyLoading'])
          buildCustomButton(
            label: 'Acknowledge',
            onTap: () => acknowledgeNotification(notification['id'], index),
            isLoading: notification['isAcknowledgeLoading'],
          ),

        // Mark Ready button
        if (notification['isAcknowledgeLoading'] &&
            !notification['isReadyLoading'])
          buildCustomButton(
            label: 'Mark Ready',
            onTap: () => markAsReadyForPickup(notification['id'], index),
            isLoading: notification['isReadyLoading'],
          ),

        // Success message
        if (notification['isAcknowledgeLoading'] &&
            notification['isReadyLoading'])
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              // color: LarosaColors.successBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: LarosaColors.success),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Order processed successfully! 🎉 Thank you for your action.',
                    style: TextStyle(
                      // color: LarosaColors.successText,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  ),
);

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
