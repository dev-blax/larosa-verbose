import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';
import 'dart:convert';
import '../../Services/auth_service.dart';
import '../../Services/log_service.dart';
import '../../Utils/colors.dart';
import '../../Utils/links.dart';
import '../cart_button.dart';

class PaymentProcessingModal extends StatefulWidget {
  final String paymentMethod;
  final String paymentType; // Either 'Bank' or 'Mobile'
  final double totalPrice;
  final int quantity;
  final int postId;
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final String? deliveryDestination;
  final double? currentLatitude;
  final double? currentLongitude;

  const PaymentProcessingModal({
    super.key,
    required this.paymentMethod,
    required this.paymentType,
    required this.totalPrice,
    required this.quantity,
    required this.postId,
    this.deliveryLatitude,
    this.deliveryLongitude,
    this.deliveryDestination,
    this.currentLatitude,
    this.currentLongitude,
  });

  @override
  _PaymentProcessingModalState createState() => _PaymentProcessingModalState();
}

class _PaymentProcessingModalState extends State<PaymentProcessingModal> {
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _merchantMobileNumberController =
      TextEditingController();
  final TextEditingController _merchantNameController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  Future<void> _submitOrder() async {
    String token = AuthService.getToken();
    Map<String, String> headers = {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
      'Authorization': token.isNotEmpty ? 'Bearer $token' : '',
    };

    var url = Uri.https(LarosaLinks.nakedBaseUrl, '/api/v1/orders/new');

    Map<String, dynamic> body = {
      "items": [
        {
          "itemId": widget.postId,
          "quantity": widget.quantity,
        }
      ],
      "paymentMethod": widget.paymentType.toUpperCase(),
      "accountNumber": _accountNumberController.text,
      "amount": widget.totalPrice,
      "latitude": widget.deliveryLatitude ?? widget.currentLatitude,
      "longitude": widget.deliveryLongitude ?? widget.currentLongitude,
    };

    // Add fields only if the payment type is "BANK"
    if (widget.paymentType == 'Bank') {
      body.addAll({
        "merchantMobileNumber": _merchantMobileNumberController.text,
        "merchantName": _merchantNameController.text,
        "otp": _otpController.text,
      });
    }

    try {
      final response = await http.post(
        url,
        body: jsonEncode(body),
        headers: headers,
      );

      // Log the status code and response body
      LogService.logInfo('Status Code: ${response.statusCode}');
      LogService.logInfo('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order placed successfully!'),
          ),
        );
        Navigator.pop(context);
      } else if (response.statusCode == 302 ||
          response.statusCode == 403 ||
          response.statusCode == 401) {
        await AuthService.refreshToken();
        await _submitOrder(); // Retry after refreshing the token
      } else {
        throw Exception('Failed to place order');
      }
    } catch (e) {
      LogService.logError('Error placing order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      child: Flexible(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        
            Center(
              child: Icon(
                widget.paymentType == 'Bank' ? Iconsax.bank : Iconsax.mobile,
                size: MediaQuery.of(context).size.height * 0.2, // Scales the icon based on the available space
                color: Colors.grey, // Set the icon color if needed
              ),
            ),
        
            SizedBox(height: widget.paymentType == 'Bank' ? 0 : 10),
        
            Center(
              child: Text(
                widget.paymentMethod,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  // color: Colors.black87,
                ),
              ),
            ),
        
            SizedBox(height: widget.paymentType == 'Bank' ? 0 : 5),
        
            const Center(
              child: Text(
                'Payment Processing',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  // color: Colors.black87,
                ),
              ),
            ),
        
            const SizedBox(height: 15),
            _buildPaymentForm(),
            
            SizedBox(height: widget.paymentType == 'Bank' ? 22 : 30),
            buildWideGradientButton(
              onTap: () {
                _submitOrder();
              },
              label: 'Confirm Payment',
              startColor: LarosaColors.secondary,
              endColor: Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentForm() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            controller: _accountNumberController,
            label:
                widget.paymentType == 'Bank' ? 'Account Number' : 'Mobile Number',
            hintText: widget.paymentType == 'Bank'
                ? 'Enter your account number'
                : 'Enter your mobile number',
          ),
          const SizedBox(height: 10),
          if (widget.paymentType == 'Bank') ...[
            _buildTextField(
              controller: _merchantMobileNumberController,
              label: 'Merchant Mobile Number',
              hintText: 'Enter merchant mobile number',
            ),
            const SizedBox(height: 10),
            _buildTextField(
              controller: _merchantNameController,
              label: 'Merchant Name',
              hintText: 'Enter merchant name',
            ),
            const SizedBox(height: 10),
            _buildTextField(
              controller: _otpController,
              label: 'OTP',
              hintText: 'Enter OTP (if required)',
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
    );
  }
}
