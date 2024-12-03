import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../../Services/log_service.dart';
import '../../Utils/links.dart';
import '../../Utils/colors.dart';

class SupplierDashboard extends StatefulWidget {
  final String supplierId;

  const SupplierDashboard({Key? key, required this.supplierId}) : super(key: key);

  @override
  _SupplierDashboardState createState() => _SupplierDashboardState();
}

class _SupplierDashboardState extends State<SupplierDashboard> {
  late StompClient stompClient;
  final List<Map<String, dynamic>> supplierNotifications = [];

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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('WebSocket error: $error')),
          );
        },
        onStompError: (StompFrame frame) =>
            LogService.logWarning('Stomp error: ${frame.body}'),
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
            supplierNotifications.add({
              'id': notification['id'],
              'message': notification['message'],
              'isAcknowledgeLoading': false,
              'isReadyLoading': false,
            });
          });
          LogService.logInfo('Notification received: ${frame.body}');
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
    final String endpoint = '${LarosaLinks.baseurl}/notifications/acknowledge/$notificationId';
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
        LogService.logInfo('Acknowledged: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification acknowledged')),
        );
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

  Future<void> markAsReadyForPickup(int notificationId, int index) async {
    final String endpoint = '${LarosaLinks.baseurl}/notifications/ready-for-pickup/$notificationId';
    setState(() {
      supplierNotifications[index]['isReadyLoading'] = true;
    });

    try {
      final response = await http.post(Uri.parse(endpoint));
      if (response.statusCode == 200) {
        LogService.logInfo('Marked as ready: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Marked as ready for pickup')),
        );
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
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
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
            : Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Supplier Dashboard')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Supplier Notifications',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            ...supplierNotifications.map((notification) {
              final int index = supplierNotifications.indexOf(notification);
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.notifications),
                      title: Text('Notification ID: ${notification['id']}'),
                      subtitle: Text('Message: ${notification['message']}'),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        buildCustomButton(
                          label: 'Acknowledge',
                          onTap: () =>
                              acknowledgeNotification(notification['id'], index),
                          isLoading: notification['isAcknowledgeLoading'],
                        ),
                        buildCustomButton(
                          label: 'Mark Ready',
                          onTap: () =>
                              markAsReadyForPickup(notification['id'], index),
                          isLoading: notification['isReadyLoading'],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
