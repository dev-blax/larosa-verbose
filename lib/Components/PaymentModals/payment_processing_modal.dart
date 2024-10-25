import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';
import 'package:larosa_block/Utils/helpers.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
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

  final ScrollController _scrollController = ScrollController();

  // Separate FocusNodes for each TextField
  final FocusNode _accountNumberFocusNode = FocusNode();
  final FocusNode _merchantMobileFocusNode = FocusNode();
  final FocusNode _merchantNameFocusNode = FocusNode();
  final FocusNode _otpFocusNode = FocusNode();

  bool _isLoading = false;

  bool connectedToSocket = false;

  late StompClient stompClient;
  final String socketChannel =
      '${LarosaLinks.baseurl}/ws/topic/customer/${AuthService.getProfileId()}';

  Future<void> _socketConnection2() async {
    const String wsUrl = 'https://exploretest.uc.r.appspot.com/ws';
    stompClient = StompClient(
      config: StompConfig.sockJS(
        url: wsUrl,
        onConnect: onConnect,
        onWebSocketError: (dynamic error) =>
            LogService.logError('WebSocket error: $error'),
        onStompError: (StompFrame frame) =>
            LogService.logWarning('Stomp error: ${frame.body}'),
        onDisconnect: (StompFrame frame) =>
            LogService.logFatal('Disconnected from WebSocket'),
      ),
    );

    stompClient.activate();
  }

  // Callback for handling successful connection
  void onConnect(StompFrame frame) {
    setState(() {
      connectedToSocket = true;
    });
    LogService.logInfo('Connected to WebSocket server: $frame');

    stompClient.subscribe(
      destination: '/topic/customer/${AuthService.getProfileId()}',
      callback: (StompFrame message) {
        LogService.logInfo(
          'Received message from /topic/customer/${AuthService.getProfileId()}: ${message.body}',
        );

        HelperFunctions.showToast(
          message.body.toString(),
          true,
        );
      },
    );

    LogService.logInfo('Successfully subscribed to /topic/customer/48');
  }

  Future<void> _submitOrder() async {
    setState(() {
      _isLoading = true;
    });

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
      "provider": widget.paymentMethod,
      "paymentMethod": widget.paymentType.toUpperCase(),
      "accountNumber": _accountNumberController.text,
      "amount": widget.totalPrice,
      "latitude": widget.deliveryLatitude ?? widget.currentLatitude,
      "longitude": widget.deliveryLongitude ?? widget.currentLongitude,
      "city": "Dodoma",
      "country": "Tanzania",
    };

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
        await _submitOrder();
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
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _socketConnection2();

    // Adding listeners for each FocusNode to scroll the view when a specific field gains focus
    _accountNumberFocusNode
        .addListener(() => _scrollToFocusedInput(_accountNumberFocusNode));
    _merchantMobileFocusNode
        .addListener(() => _scrollToFocusedInput(_merchantMobileFocusNode));
    _merchantNameFocusNode
        .addListener(() => _scrollToFocusedInput(_merchantNameFocusNode));
    _otpFocusNode.addListener(() => _scrollToFocusedInput(_otpFocusNode));
  }

  @override
  void dispose() {
    // Dispose of controllers and focus nodes
    _accountNumberFocusNode.dispose();
    _merchantMobileFocusNode.dispose();
    _merchantNameFocusNode.dispose();
    _otpFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToFocusedInput(FocusNode focusNode) {
    if (focusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 15,
            right: 15),
        child: SingleChildScrollView(
          controller: _scrollController,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Icon(
                      widget.paymentType == 'Bank'
                          ? Iconsax.bank
                          : Iconsax.mobile,
                      size: MediaQuery.of(context).size.height * 0.2,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      widget.paymentMethod,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Center(
                    child: Text(
                      'Payment Processing',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Expanded(
                    child: _buildPaymentForm(),
                  ),
                  const SizedBox(height: 20),
                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(),
                    )
                  else
                    buildWideGradientButton(
                      onTap: _submitOrder,
                      label: 'Confirm Payment',
                      startColor: LarosaColors.secondary,
                      endColor: Colors.purple,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          controller: _accountNumberController,
          label:
              widget.paymentType == 'Bank' ? 'Account Number' : 'Mobile Number',
          hintText: widget.paymentType == 'Bank'
              ? 'Enter your account number'
              : 'Enter your mobile number',
          focusNode: _accountNumberFocusNode,
        ),
        const SizedBox(height: 10),
        if (widget.paymentType == 'Bank') ...[
          _buildTextField(
            controller: _merchantMobileNumberController,
            label: 'Merchant Mobile Number',
            hintText: 'Enter merchant mobile number',
            focusNode: _merchantMobileFocusNode,
          ),
          const SizedBox(height: 10),
          _buildTextField(
            controller: _merchantNameController,
            label: 'Merchant Name',
            hintText: 'Enter merchant name',
            focusNode: _merchantNameFocusNode,
          ),
          const SizedBox(height: 10),
          _buildTextField(
            controller: _otpController,
            label: 'OTP',
            hintText: 'Enter OTP (if required)',
            focusNode: _otpFocusNode,
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required FocusNode focusNode,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
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
