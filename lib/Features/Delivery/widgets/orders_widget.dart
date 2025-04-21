import 'dart:convert';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../Services/auth_service.dart';
import '../../../Services/log_service.dart';
import '../../../Utils/colors.dart';
import '../../../Utils/helpers.dart';
import '../../../Utils/links.dart';
import '../explore_services.dart';
import 'ride_history_modal.dart';

class OrdersWidget extends StatefulWidget {
  const OrdersWidget({super.key});

  @override
  State<OrdersWidget> createState() => _OrdersWidgetState();
}

class _OrdersWidgetState extends State<OrdersWidget> {
  List<dynamic> orders = [];
  List<dynamic> rideHistory = [];

  void asyncInit() async {
    _loadOrders();
    _loadRideHistory();
  }

  @override
  void initState(){
    super.initState();
    asyncInit();
  }

  Future<void> _loadOrders() async {
    String token = AuthService.getToken();
    LogService.logDebug('token $token');
    Map<String, String> headers = {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
      'Authorization': 'Bearer $token',
    };

    var url = Uri.parse('${LarosaLinks.baseurl}/api/v1/orders/history');

    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200 || response.statusCode == 201) {
        LogService.logFatal('Orders fetch successful');
        //LogService.logInfo(response.body);
        setState(() {
          orders = jsonDecode(response.body);
          //orders = orders.reversed.toList();
        });

        LogService.logInfo('Orders loaded: ${orders}');
      } else {
        LogService.logError('Error fetching orders: ${response.statusCode}');
      }
    } catch (e) {
      LogService.logError('Failed to fetch orders: $e');
    }
  }

  Future<void> _loadRideHistory() async {
    String token = AuthService.getToken();
    LogService.logDebug('token $token');
    Map<String, String> headers = {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
      'Authorization': 'Bearer $token',
    };

    var url = Uri.parse('${LarosaLinks.baseurl}/api/v1/ride-customer/rides');

    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200 || response.statusCode == 201) {
        LogService.logFatal('Ride history fetch successful');
        LogService.logInfo(response.body);
        setState(() {
          rideHistory = jsonDecode(response.body);
        });
      } else {
        LogService.logError(
            'Error fetching ride history: ${response.statusCode}');
      }
    } catch (e) {
      LogService.logError('Failed to fetch ride history: $e');
    }
  }

  Route _createRoute() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => ExploreModal(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);
        return SlideTransition(position: offsetAnimation, child: child);
      },
    );
  }

  Widget creativeOrderCard(Map<String, dynamic> order) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = (order['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final totalItems = items.fold<int>(0, (sum, item) => sum + ((item['quantity'] as num?)?.toInt() ?? 0));
    final deliveryLocation = order['deliveryLocation'] as Map<String, dynamic>? ?? {};
    final driver = order['driver'] as Map<String, dynamic>? ?? {};

    // Collect all media from items
    final allMedia = items.expand<String>((item) {
      final mediaLinks = (item['mediaLink'] as List?)?.cast<String>() ?? [];
      return mediaLinks;
    }).toList();

    LogService.logInfo('Order: $order');

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? LarosaColors.dark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Status and Amount
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(order['status']?.toString()).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: _getStatusColor(order['status']?.toString()),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                order['status']?.toString().toUpperCase() ?? 'PENDING',
                                style: TextStyle(
                                  color: _getStatusColor(order['status']?.toString()),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '#${order['id']?.toString() ?? 'N/A'}',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'TSh ${HelperFunctions.formatPrice((order['totalAmount'] as num?)?.toDouble() ?? 0.0)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? LarosaColors.primary : LarosaColors.primary.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Media Gallery
              if (allMedia.isNotEmpty) ...[
                Container(
                  height: 120,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: allMedia.length,
                    itemBuilder: (context, index) {
                      final mediaUrl = allMedia[index];
                      final isVideo = mediaUrl.toLowerCase().endsWith('.mp4');
                      
                      return Container(
                        width: 100,
                        margin: EdgeInsets.only(right: index < allMedia.length - 1 ? 12 : 0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                mediaUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: isDark ? Colors.white12 : Colors.black.withOpacity(0.05),
                                    child: Icon(
                                      CupertinoIcons.photo,
                                      color: isDark ? Colors.white30 : Colors.black26,
                                    ),
                                  );
                                },
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    color: isDark ? Colors.white12 : Colors.black.withOpacity(0.05),
                                    child: Center(
                                      child: CupertinoActivityIndicator(
                                        color: isDark ? Colors.white54 : Colors.black45,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              if (isVideo)
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        Colors.black.withOpacity(0.4),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      CupertinoIcons.play_circle_fill,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              
              // Order Details
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Location and Driver Info
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.location_solid,
                          size: 18,
                          color: isDark ? Colors.white60 : Colors.black45,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                deliveryLocation['city']?.toString() ?? 'Location Pending',
                                style: TextStyle(
                                  color: isDark ? Colors.white70 : Colors.black87,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (driver['name'] != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Driver: ${driver['name']}',
                                  style: TextStyle(
                                    color: isDark ? Colors.white60 : Colors.black54,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Items Summary
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark 
                            ? Colors.white.withOpacity(0.05) 
                            : LarosaColors.primary.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$totalItems ${totalItems == 1 ? 'item' : 'items'}',
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Delivery: TSh ${HelperFunctions.formatPrice((order['deliveryAmount'] as num?)?.toDouble() ?? 0.0)}',
                            style: TextStyle(
                              color: isDark ? Colors.white60 : Colors.black54,
                              fontSize: 13,
                            ),
                          ),
                        ],
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
  }

  Color _getStatusColor(String? status) {
    switch(status?.toUpperCase()) {
      case 'COMPLETED':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [LarosaColors.secondary, LarosaColors.purple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: const Text(
                  'Your Orders',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [LarosaColors.secondary, LarosaColors.purple],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (BuildContext context) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                LarosaColors.secondary.withOpacity(0.55),
                                LarosaColors.purple.withOpacity(0.4),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                            child: RideHistoryModal(rideHistory: rideHistory),
                          ),
                        );
                      },
                    );
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: Text(
                    'Ride History',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : LarosaColors.light,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: 80,
                        color: LarosaColors.mediumGray,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "No current orders",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "It looks like you haven't placed any orders yet.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(_createRoute());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: LarosaColors.purple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 14,
                          ),
                          elevation: 5,
                          shadowColor: LarosaColors.primary.withOpacity(0.5),
                        ),
                        child: const Text(
                          "Make a New Order",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    return creativeOrderCard(orders[index]);
                  },
                ),
          const SizedBox(height: 70),
        ],
      ),
    );
  }
}
