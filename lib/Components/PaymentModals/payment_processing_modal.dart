import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../Services/auth_service.dart';
import '../../Services/log_service.dart';
import '../../Utils/colors.dart';
import '../../Utils/links.dart';
import '../cart_button.dart';

class PaymentProcessingModal extends StatefulWidget {
  final String paymentMethod;
  final String paymentType;
  final double totalPrice;
  final int quantity;
  final List<int> postId;
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final String? deliveryDestination;
  final double? currentLatitude;
  final double? currentLongitude;

  final int adults; // New parameter
  final int children; // New parameter
  final String fullName; // New parameter
  final bool isReservation; // New parameter

  final List<Map<String, dynamic>> items;

  final DateTime? checkInDate; // Allow null values
  final DateTime? checkOutDate; // Allow null values

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
    required this.adults, // Initialize in constructor
    required this.children, // Initialize in constructor
    required this.fullName, // Initialize in constructor
    required this.isReservation,
    required this.items,
    required this.checkInDate,
    required this.checkOutDate, // Initialize in constructor // Initialize in constructor
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

  String formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('yyyy-MM-dd').format(date);
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

    var url = Uri.https(
        LarosaLinks.nakedBaseUrl,
        widget.isReservation
            ? '/api/v1/reservations/new'
            : '/api/v1/orders/new');

    Map<String, dynamic> body = {
      "items": widget.items,
      "provider": widget.paymentMethod,
      "paymentMethod": widget.paymentType.toUpperCase(),
      "accountNumber": _accountNumberController.text,
      "amount": widget.totalPrice,
      "latitude": widget.deliveryLatitude ?? widget.currentLatitude,
      "longitude": widget.deliveryLongitude ?? widget.currentLongitude,
      "city": "Dodoma",
      "country": "Tanzania",
    };

    if (widget.isReservation) {
      body.addAll({
        "adults": widget.adults,
        "children": widget.children,
        "fullName": widget.fullName,
        "checkInDate": formatDate(widget.checkInDate),
        "checkOutDate": formatDate(widget.checkOutDate),
      });
    }

    if (widget.paymentType == 'Bank') {
      body.addAll({
        "merchantMobileNumber": _merchantMobileNumberController.text,
        "merchantName": _merchantNameController.text,
        "otp": _otpController.text,
      });
    }

    LogService.logInfo('Request Body: $body');

    try {
      final response = await http.post(
        url,
        body: jsonEncode(body),
        headers: headers,
      );

      LogService.logInfo('Status Code: ${response.statusCode}');
      LogService.logInfo('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        _showSuccessDialog('Reservation is under processing.');
      } else if (response.statusCode == 409) {
        // Handle date conflict (already booked)
        _showConflictDialog(response.body);
      } else if ([302, 403, 401].contains(response.statusCode)) {
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

  void _showConflictDialog(String responseBody) {
    List<String> unavailableDates = [];
    try {
      final parsedBody = jsonDecode(responseBody);
      unavailableDates = List<String>.from(parsedBody['unavailableDates']);
    } catch (e) {
      LogService.logError('Error parsing response: $e');
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Dates Unavailable'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'The selected dates are already booked. Please choose different dates.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              if (unavailableDates.isNotEmpty)
                Text(
                  'Unavailable dates:\n${unavailableDates.join(", ")}',
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();

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

  // void _showSuccessDialog(String responseBody) {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         backgroundColor: Colors.black,
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(15.0),
  //         ),
  //         content: Stack(
  //           children: [
  //             // Background bubble animation
  //             Positioned.fill(
  //               child: Lottie.asset(
  //                 'assets/lotties/bubbles.json',
  //                 fit: BoxFit.cover,
  //                 repeat: true,
  //               ),
  //             ),
  //             Column(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 // Green checkmark icon
  //                 const Icon(
  //                   Icons.check_circle,
  //                   color: Color.fromARGB(255, 13, 72, 15),
  //                   size: 100,
  //                 ),
  //                 const SizedBox(height: 20),
  //                 const Text(
  //                   'Payment Successful!',
  //                   textAlign: TextAlign.center,
  //                   style: TextStyle(
  //                     fontSize: 24,
  //                     fontWeight: FontWeight.bold,
  //                     color: Color.fromARGB(255, 15, 106, 18),
  //                   ),
  //                 ),
  //                 const SizedBox(height: 16),
  //                 const Padding(
  //                   padding: EdgeInsets.symmetric(horizontal: 16.0),
  //                   child: Column(
  //                     crossAxisAlignment: CrossAxisAlignment.center,
  //                     children: [
  //                       Text(
  //                         "Your payment is now under processing.",
  //                         textAlign: TextAlign.center,
  //                         style: TextStyle(
  //                           fontSize: 16,
  //                           fontStyle: FontStyle.normal,
  //                           height: 1.5,
  //                         ),
  //                       ),
  //                       SizedBox(height: 8),
  //                       Text(
  //                         "We will notify you shortly with an update on its status.",
  //                         textAlign: TextAlign.center,
  //                         style: TextStyle(
  //                           fontSize: 16,
  //                           fontStyle: FontStyle.normal,
  //                           height: 1.5,
  //                         ),
  //                       ),
  //                       SizedBox(height: 8),
  //                       Text(
  //                         "Once confirmed, you'll receive detailed information about your order's next steps.",
  //                         textAlign: TextAlign.center,
  //                         style: TextStyle(
  //                           fontSize: 16,
  //                           fontStyle: FontStyle.normal,
  //                           height: 1.5,
  //                         ),
  //                       ),
  //                       SizedBox(height: 8),
  //                       Text(
  //                         "We truly value your trust in us and are committed to delivering an exceptional experience.",
  //                         textAlign: TextAlign.center,
  //                         style: TextStyle(
  //                           fontSize: 16,
  //                           fontStyle: FontStyle.normal,
  //                           height: 1.5,
  //                         ),
  //                       ),
  //                       SizedBox(height: 20),
  //                       Text(
  //                         "Thank you for choosing us!",
  //                         textAlign: TextAlign.center,
  //                         style: TextStyle(
  //                           fontSize: 16,
  //                           fontStyle: FontStyle.italic,
  //                           height: 1.5,
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //                 const SizedBox(height: 16),
  //                 const Text(
  //                   'LAROSA EXPLORE',
  //                   textAlign: TextAlign.center,
  //                   style: TextStyle(
  //                     fontSize: 16,
  //                     fontWeight: FontWeight.bold,
  //                     fontStyle: FontStyle.italic,
  //                     letterSpacing: 1.5,
  //                   ),
  //                 ),
  //                 const SizedBox(height: 20),

  //                 buildWideGradientButton(
  //                   onTap: () {
  //                     Navigator.of(context).pop(); // Close the dialog
  //                     Navigator.pop(context); // Navigate back
  //                   },
  //                   label: 'OK',
  //                   startColor: const Color.fromARGB(255, 13, 72, 15),
  //                   endColor: Colors.purple,
  //                 ),
  //               ],
  //             ),
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }

  // void _showSuccessDialog(String responseBody) {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         backgroundColor: Colors.black,
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(15.0),
  //         ),
  //         content: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             // Green checkmark icon
  //             const Icon(
  //               Icons.check_circle,
  //               color: Color.fromARGB(255, 13, 72, 15),
  //               size: 80,
  //             ),
  //             const SizedBox(height: 20),
  //             const Text(
  //               'Payment Successful!',
  //               textAlign: TextAlign.center,
  //               style: TextStyle(
  //                 fontSize: 22,
  //                 fontWeight: FontWeight.bold,
  //                 color: Color.fromARGB(255, 15, 106, 18),
  //               ),
  //             ),
  //             const SizedBox(height: 12),
  //             const Text(
  //               "Your payment is being processed. We'll notify you with an update soon.",
  //               textAlign: TextAlign.center,
  //               style: TextStyle(
  //                 fontSize: 16,
  //                 height: 1.5,
  //               ),
  //             ),
  //             const SizedBox(height: 12),
  //             const Text(
  //               'Thank you for choosing LAROSA EXPLORE!',
  //               textAlign: TextAlign.center,
  //               style: TextStyle(
  //                 fontSize: 16,
  //                 fontStyle: FontStyle.italic,
  //                 fontWeight: FontWeight.bold,
  //                 letterSpacing: 1.2,
  //               ),
  //             ),
  //             const SizedBox(height: 20),
  //             buildWideGradientButton(
  //               onTap: () {
  //                 Navigator.of(context).pop(); // Close the dialog
  //                 Navigator.pop(context); // Navigate back
  //               },
  //               label: 'OK',
  //               startColor: const Color.fromARGB(255, 13, 72, 15),
  //               endColor: Colors.purple,
  //             ),
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }

  void _showSuccessDialog(String responseBody) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDarkMode ? Colors.black : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Green checkmark icon
              Icon(
                Icons.check_circle,
                color: isDarkMode
                    ? const Color.fromARGB(
                        255, 50, 205, 50) // Light green in dark mode
                    : const Color.fromARGB(
                        255, 13, 72, 15), // Darker green in light mode
                size: 80,
              ),
              const SizedBox(height: 20),
              Text(
                'Payment Successful!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode
                      ? const Color.fromARGB(
                          255, 144, 238, 144) // Light green text
                      : const Color.fromARGB(
                          255, 15, 106, 18), // Dark green text
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Your payment is being processed. We'll notify you with an update soon.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Thank you for choosing LAROSA EXPLORE!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),
              buildWideGradientButton(
                onTap: () {
                  Navigator.of(context).pop(); // Close the dialog
                  Navigator.pop(context); // Navigate back
                },
                label: 'OK',
                startColor: isDarkMode
                    ? const Color.fromARGB(255, 50, 205, 50)
                    : const Color.fromARGB(255, 13, 72, 15),
                endColor: Colors.purple,
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        // left: 15,
        // right: 15,
      ),
      child: SingleChildScrollView(
        controller: _scrollController,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight:
                MediaQuery.of(context).size.height * 0.9, // Increased height
          ),
          child: IntrinsicHeight(
            child: Container(
              color: isDarkMode ? Colors.black : Colors.white,
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
                      child: CupertinoActivityIndicator(
                        radius: 10.0, // Adjust the size as needed
                      ),
                    )
                  else if (_validateMobilePaymentFields())
                    Padding(
                      padding: EdgeInsets.only(
                        left: 5,
                        right: 5,
                        bottom: isIOS ? 40.0 : 0.0, // Add extra padding for iOS
                      ),
                      child: buildWideGradientButton(
                        onTap: _submitOrder,
                        label: 'Confirm Payment',
                        startColor: LarosaColors.secondary,
                        endColor: LarosaColors.purple,
                      ),
                    ),
                  if (!_validateMobilePaymentFields())
                    Center(
                      child: Text(
                        'Please ensure all mobile payment fields are valid.',
                        style: TextStyle(
                          color: isDarkMode
                              ? Colors.grey[300]
                              : Colors.grey[700], // Adjust based on theme
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(
                    height: 10,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _validateMobilePaymentFields() {
    if (widget.paymentType == 'Mobile') {
      return _accountNumberController.text.isNotEmpty &&
          validateMobileNumber(
                  _accountNumberController.text, widget.paymentMethod) ==
              null;
    }
    return true; // For non-mobile payment types, always return true
  }

  Widget _buildPaymentForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            controller: _accountNumberController,
            label: widget.paymentType == 'Bank'
                ? 'Account Number'
                : 'Mobile Number',
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
      ),
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
      onChanged: (value) {
        setState(() {}); // Trigger rebuild for validation
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        errorText: validateMobileNumber(
          _accountNumberController.text,
          widget.paymentMethod, // Pass the selected payment method
        ),
        errorStyle: const TextStyle(
          color: Color.fromARGB(
              255, 174, 25, 14), // Change to your preferred color
          fontSize: 12.0, // Optionally adjust font size
          fontWeight: FontWeight.bold, // Optionally adjust font weight
        ),
        // Custom error border when not focused
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(
            color: Color.fromARGB(255, 174, 25, 14), // Error border color
            width: 2.0, // Border width
          ),
        ),
        // Custom error border when focused
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(
            color:
                Color.fromARGB(255, 174, 25, 14), // Focused error border color
            width: 2.0, // Border width
          ),
        ),
      ),
    );
  }

  String? validateMobileNumber(String number, String paymentMethod) {
    // Define valid prefixes for each payment method
    const providerPrefixes = {
      'Airtel': ['068', '078', '069'],
      'Tigo': ['065', '067', '071'],
      'Halopesa': ['077'],
      'Azampesa': ['076'],
      'Mpesa': ['075', '074', '073'],
    };

    // Check if the payment method is among the defined providers
    if (providerPrefixes.containsKey(paymentMethod) && number.isNotEmpty) {
      final prefixes = providerPrefixes[paymentMethod]!;

      // Validate prefix for the specific payment method
      if (!prefixes.any((prefix) => number.startsWith(prefix))) {
        return 'Invalid $paymentMethod number. Must start with ${prefixes.join(", ")} (e.g., ${prefixes[0]}1234567).';
      }

      // Validate length for mobile numbers
      if (number.length != 10) {
        return '$paymentMethod number must be exactly 10 digits long (e.g., ${prefixes[0]}1234567).';
      }
    } else if (number.isEmpty) {
      // Check if the field is empty
      return 'Please enter your $paymentMethod number.';
    } else {
      // For unsupported payment methods or fallback
      return 'Invalid payment method selected.';
    }

    return null; // Return null if validation passes
  }
}
