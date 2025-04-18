import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../Utils/colors.dart';

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
  final _accountController = TextEditingController();
  String? _selectedMethod;
  bool _isProcessing = false;

  final _paymentMethods = [
    {
      'name': 'M-Pesa',
      'icon': 'assets/icons/mpesa.jpg',
      'color': Color(0xFF00A0D1),
    },
    {
      'name': 'Tigo Pesa',
      'icon': 'assets/icons/mixx.jpg',
      'color': Color(0xFF0066B1),
    },
    {
      'name': 'Airtel Money',
      'icon': 'assets/icons/airtel.jpg',
      'color': Color(0xFFEE1C24),
    },
    {
      'name': 'Halo Pesa',
      'icon': 'assets/icons/halotel.jpg',
      'color': Color(0xFF7CB82F),
    },
    {
      'name': 'AzamPesa',
      'icon': 'assets/icons/azampesa.jpg',
      'color': Color(0xFFFE0000),
    },
    {
      'name': 'CRDB Bank',
      'icon': 'assets/icons/crdb.png',
      'color': Color(0xFF00A651),
    },
    {
      'name': 'NMB Bank',
      'icon': 'assets/icons/nmb.png',
      'color': Color(0xFF00A551),
    },
  ];

  @override
  void dispose() {
    _accountController.dispose();
    super.dispose();
  }

  void _processPayment() async {
    if (_selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a payment method'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_accountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your account number'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

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
                const CircularProgressIndicator(),
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

      // Simulate server request
      final response = await Future.delayed(
        const Duration(seconds: 2),
        () => {
          'status': 'success',
          'message': 'Payment initiated successfully',
          'data': {
            'reference': 'TX${DateTime.now().millisecondsSinceEpoch}',
            'amount': widget.totalPrice,
            'phone': _accountController.text,
            'payment_method': _selectedMethod,
          }
        },
      );

      // Close loading dialog
      if (!mounted) return;
      Navigator.of(context).pop();

      if (response['status'] == 'success') {
        // Show USSD notification dialog
        showDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('USSD Prompt'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.mobile_friendly_rounded,
                  size: 48,
                  color: LarosaColors.secondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'You will receive a USSD prompt on ${_accountController.text} to enter your PIN and complete the payment of Tsh ${widget.totalPrice.toStringAsFixed(2)}',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // Return to previous screen
                },
                child: const Text('Close'),
              ),
            ],
          ),
        );
      } else {
        throw 'Payment initiation failed';
      }
    } catch (e) {
      // Close loading dialog if open
      if (!mounted) return;
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => _isProcessing = false);
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
                  itemCount: _paymentMethods.length,
                  itemBuilder: (context, index) {
                    final method = _paymentMethods[index];
                    final isSelected = _selectedMethod == method['name'];

                    return InkWell(
                      onTap: () => setState(() => _selectedMethod = method['name'] as String),
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
                                fontSize: 12,
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
                  Text(
                    'Enter Account Number',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey,
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
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        hintText: _selectedMethod?.contains('Bank') == true
                            ? 'Enter account number'
                            : 'Enter phone number',
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
                        'Tsh ${widget.totalPrice.toStringAsFixed(2)}',
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
                      backgroundColor: LarosaColors.secondary,
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
