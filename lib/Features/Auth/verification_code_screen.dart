import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../Services/dio_service.dart';
import '../../Services/log_service.dart';
import '../../Utils/links.dart';

class VerificationCodeScreen extends StatefulWidget {
  final String email;
  const VerificationCodeScreen({super.key, required this.email});

  @override
  State<VerificationCodeScreen> createState() => _VerificationCodeScreenState();
}

class _VerificationCodeScreenState extends State<VerificationCodeScreen> {
  List<TextEditingController> controllers = List.generate(6, (index) => TextEditingController());
  List<FocusNode> focusNodes = List.generate(6, (index) => FocusNode());
  final TextEditingController _passwordController = TextEditingController();
  final DioService _dioService = DioService();
  bool isLoading = false;
  bool _obscureText = true;

  @override
  void dispose() {
    for (var controller in controllers) {
      controller.dispose();
    }
    for (var node in focusNodes) {
      node.dispose();
    }
    _passwordController.dispose();
    super.dispose();
  }

  String getCompleteCode() {
    return controllers.map((controller) => controller.text).join();
  }

  void handleVerification() async {
    final code = getCompleteCode();
    if (code.length == 6 && _passwordController.text.isNotEmpty) {
      try {
        setState(() {
          isLoading = true;
        });

        final response = await _dioService.dio.post(
          LarosaLinks.verifyForgotPassword,
          data: jsonEncode({
            "email": widget.email,
            "token": code,
            "password": _passwordController.text,
          }),
        );

        if (response.statusCode == 200) {
          if (mounted) {
            // Show success message
            showCupertinoDialog(
              context: context,
              builder: (context) => CupertinoAlertDialog(
                title: const Text('Success'),
                content: const Text('Password has been reset successfully'),
                actions: [
                  CupertinoDialogAction(
                    child: const Text('OK'),
                    onPressed: () {
                      // Pop twice to go back to login screen
                      Navigator.of(context)
                        ..pop() // Close dialog
                        ..pop() // Close verification screen
                        ..pop(); // Close forgot password screen
                    },
                  ),
                ],
              ),
            );
          }
        }
      } catch (e) {
        LogService.logError('Error $e');
        if (mounted) {
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Error'),
              content: const Text('Failed to verify code. Please try again.'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          );
        }
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(CupertinoIcons.back),
        ),
        title: const Text('Enter Verification Code'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              'Enter the 6-digit code sent to ${widget.email}',
              style: const TextStyle(color: Colors.grey, fontSize: 15),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                6,
                (index) => SizedBox(
                  width: 45,
                  child: CupertinoTextField(
                    controller: controllers[index],
                    focusNode: focusNodes[index],
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    textAlign: TextAlign.center,
                    enabled: !isLoading,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty && index < 5) {
                        focusNodes[index + 1].requestFocus();
                      }
                      if (value.isEmpty && index > 0) {
                        focusNodes[index - 1].requestFocus();
                      }
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            CupertinoTextField(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              controller: _passwordController,
              placeholder: 'New Password',
              obscureText: _obscureText,
              enabled: !isLoading,
              suffix: GestureDetector(
                onTap: () => setState(() => _obscureText = !_obscureText),
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Icon(
                    _obscureText ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                    color: Colors.grey,
                  ),
                ),
              ),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton.filled(
                onPressed: isLoading ? null : handleVerification,
                child: isLoading
                    ? const Center(child: CupertinoActivityIndicator())
                    : const Text('Reset Password'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
