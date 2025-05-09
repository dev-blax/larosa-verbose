import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../Services/dio_service.dart';
import '../../Services/encryption_service.dart';
import '../../Services/log_service.dart';
import '../../Utils/links.dart';

class EnableE2eScreen extends StatefulWidget {
  const EnableE2eScreen({super.key});

  @override
  State<EnableE2eScreen> createState() => _EnableE2eScreenState();
}

class _EnableE2eScreenState extends State<EnableE2eScreen> {
  final DioService _dioService = DioService();
  TextEditingController passwordController = TextEditingController();
  // obscure text
  bool obscureText = true;
  // is loading
  bool isLoading = false;

  Future<void> _enableE2e() async {
    try {
      setState(() {
        isLoading = true;
      });
      final response = await _dioService.dio.post(
        '${LarosaLinks.baseurl}/api/v1/keys/generate',
        data: jsonEncode({
          'password': passwordController.text,
        }),
      );

      if (response.statusCode == 201) {
        final encryptionService = EncryptionService();
        await encryptionService.storeE2EKeys(
            response.data['publicKey'], response.data['encryptedPrivateKey']);
        await encryptionService.setE2EEnabled(true);
        LogService.logInfo('E2E enabled successfully');

        // store password
        // await encryptionService.storeE2EPassword(passwordController.text);

        if (!mounted) {
          LogService.logInfo('Enable E2E: Not mounted');
          // ScaffoldMessenger.of(context).showSnackBar(
          //   const SnackBar(
          //     content: Text('E2E enabled successfully'),
          //   ),
          // );
          return;
        }
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Success'),
            content: const Text('E2E enabled successfully'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () {
                  context.pop();
                  context.pushReplacementNamed('settings');
                },
              ),
            ],
          ),
        );
      }
    } catch (e) {
      LogService.logError('Error enabling E2E: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enable End to End Encryption'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const Gap(20),
            const Text(
              'End to end encryption provides an additional layer of security for your messages.',
              textAlign: TextAlign.center,
            ),
            const Gap(20),
            // enter password
            CupertinoTextField(
              controller: passwordController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              obscureText: obscureText,
              prefix: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: const Icon(CupertinoIcons.lock),
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).colorScheme.surface,
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
              ),
              suffix: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  icon: Icon(
                    obscureText ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () {
                    setState(() {
                      obscureText = !obscureText;
                    });
                  },
                ),
              ),
            ),
            const Gap(20),
            SizedBox(
              width: double.infinity,
              child: isLoading
                  ? const CupertinoActivityIndicator()
                  : CupertinoButton.filled(
                      onPressed: () {
                        _enableE2e();
                      },
                      child: const Text('Enable'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
