import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:larosa_block/Utils/helpers.dart';
import '../../../Services/dio_service.dart';
import '../../../Services/log_service.dart';
import '../../../Utils/colors.dart';
import 'package:intl/intl.dart';

import '../../../Utils/links.dart'; // Import intl for formatDate

class PaymentMethodScreen extends StatefulWidget {
  final double totalPrice;
  final List<int> postId;
  final List<Map<String, dynamic>> items;
  final int quantity;
  final String? deliveryDestination;
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final int? adults;
  final int? children;
  final String fullName;
  final DateTime? checkInDate;
  final DateTime? checkOutDate;
  final bool isReservation;

  const PaymentMethodScreen({
    super.key,
    required this.totalPrice,
    required this.postId,
    required this.items,
    required this.quantity,
    this.deliveryDestination,
    this.deliveryLatitude,
    this.deliveryLongitude,
    this.adults,
    this.children,
    required this.fullName,
    this.checkInDate,
    this.checkOutDate,
    required this.isReservation,
  });

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  final TextEditingController _accountController = TextEditingController();
  String? _selectedMethod;
  bool _isProcessing = false;

  final List<Map<String, dynamic>> paymentMethods = [
    {
      'type': 'Bank',
      'name': 'CRDB Bank',
      'value': 'CRDB',
      'icon': 'assets/icons/crdb.png',
      'color': Color(0xFF00A651),
    },
    {
      'type': 'Bank',
      'name': 'NMB Bank',
      'value': 'NMB',
      'icon': 'assets/icons/nmb.png',
      'color': Color(0xFF00A551),
    },
    {
      'type': 'Mobile',
      'name': 'M-Pesa',
      'value': 'Mpesa',
      'icon': 'assets/icons/mpesa.jpg',
      'color': Color(0xFF00A0D1),
    },
    {
      'type': 'Mobile',
      'name': 'Tigo Pesa',
      'value': 'Tigo',
      'icon': 'assets/icons/mixx.jpg',
      'color': Color(0xFF0066B1),
    },
    {
      'type': 'Mobile',
      'name': 'Airtel Money',
      'value': 'Airtel',
      'icon': 'assets/icons/airtel.jpg',
      'color': Color(0xFFEE1C24),
    },
    {
      'type': 'Mobile',
      'name': 'Halopesa',
      'value': 'Halopesa',
      'icon': 'assets/icons/halotel.jpg',
      'color': Color(0xFF7CB82F),
    },
    {
      'type': 'Mobile',
      'name': 'Azampesa',
      'value': 'Azampesa',
      'icon': 'assets/icons/azampesa.jpg',
      'color': Color(0xFFFE0000),
    },
  ];

  @override
  void dispose() {
    _accountController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CupertinoActivityIndicator(
                  radius: 20,
                ),
                const SizedBox(height: 24),
                Text(
                  'Initiating Payment',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please wait...',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[400]
                        : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final dio = DioService().dio;

      String url = LarosaLinks.baseurl + (widget.isReservation
          ? '/api/v1/reservations/new'
          : '/api/v1/orders/new');

      LogService.logInfo('Payment URL: $url');

      Map<String, dynamic> body = {
        "items": widget.items,
        "provider": _selectedMethod,
        "paymentMethod": (paymentMethods.firstWhere((method) => method['value'] == _selectedMethod)['type'] ?? '').toUpperCase(),
        "accountNumber": _accountController.text,
        "amount": widget.totalPrice,
        "latitude": widget.deliveryLatitude ?? 0,
        "longitude": widget.deliveryLongitude ?? 0,
        "city": "Dodoma",
        "country": "Tanzania",
      };

      if (widget.isReservation) {
        body.addAll({
          "adults": widget.adults,
          "children": widget.children,
          "fullName": widget.fullName,
          "checkInDate": DateFormat('yyyy-MM-dd').format(widget.checkInDate!),
          "checkOutDate": DateFormat('yyyy-MM-dd').format(widget.checkOutDate!),
        });
      }

      final response = await dio.post(url, data: body);
      
      LogService.logDebug('got response');
      // Pop loading dialog
      Navigator.of(context).pop();

      if (response.statusCode == 200) {
        if (mounted) {
          showDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Payment Initiated'),
            content: Text('Your Order is Being Processed!'),
            actions: [
              CupertinoDialogAction(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go('/maindelivery');
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
        }
      }
    } catch (error) {
      // Pop loading dialog if still showing
      if (context.mounted) Navigator.of(context).pop();
      
      // DioService will handle error messages through its interceptors
      LogService.logError('Payment processing error: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Method'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Select Payment Method',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: paymentMethods.length,
                  itemBuilder: (context, index) {
                    final method = paymentMethods[index];
                    final isSelected = _selectedMethod == method['value'];

                    return InkWell(
                      onTap: () => setState(() => _selectedMethod = method['value'] as String),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? method['color'] as Color
                                : isDark
                                    ? Colors.grey[800]!
                                    : Colors.grey[300]!,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                method['icon'] as String,
                                height: 64,
                                width: 64,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              method['name'] as String,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? method['color'] as Color
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                if (_selectedMethod != null) ...[
                  RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.titleMedium,
                      children: [
                        const TextSpan(
                          text: 'Enter ',
                          style: TextStyle(color: Colors.grey),
                        ),
                        TextSpan(
                          text: paymentMethods
                              .firstWhere((method) => method['value'] == _selectedMethod)['value']
                              .toString()
                              .toUpperCase(),
                          style: TextStyle(
                            color: paymentMethods
                                .firstWhere((method) => method['value'] == _selectedMethod)['color'] as Color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: paymentMethods.firstWhere((method) => method['value'] == _selectedMethod)['type'] == 'Bank'
                              ? ' account number'
                              : ' phone number',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                      ),
                    ),
                    // 
                    child: TextField(
                      controller: _accountController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[850] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Amount',
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      Text(
                        'Tsh ${HelperFunctions.formatPrice(widget.totalPrice)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _processPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LarosaColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Proceed to Pay'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
