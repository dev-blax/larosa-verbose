import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larosa_block/Services/log_service.dart';
import 'package:larosa_block/Utils/helpers.dart';
import 'package:larosa_block/Utils/links.dart';
import 'package:larosa_block/Services/dio_service.dart';

import 'verification_code_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  );

  late final Animation<Offset> _rightOffsetAnimation = Tween<Offset>(
    begin: const Offset(-2.5, 0),
    end: Offset.zero,
  ).animate(CurvedAnimation(
    parent: _animationController,
    curve: Curves.elasticOut,
  ));

  late final Animation<Offset> _leftOffsetAnimation = Tween<Offset>(
    begin: const Offset(2.5, 0),
    end: Offset.zero,
  ).animate(CurvedAnimation(
    parent: _animationController,
    curve: Curves.elasticOut,
  ));

  final DioService _dioService = DioService();

  @override
  void initState() {
    super.initState();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  bool isLoading = false;
  TextEditingController emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(
              CupertinoIcons.back,
            ),
          ),
          title: const Text('Forgot Password'),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Form(
              child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter your email, we will send you a link to create a new password',
                  style: TextStyle(color: Colors.grey, fontSize: 15),
                ),

                const SizedBox(
                  height: 10,
                ),

                SlideTransition(
                  position: _rightOffsetAnimation,
                  child: TextFormField(
                    keyboardType: TextInputType.emailAddress,
                    controller: emailController,
                    decoration: const InputDecoration(
                      hintText: 'Email',
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                // Sign in button
                SlideTransition(
                  position: _leftOffsetAnimation,
                  child: CupertinoButton.filled(
                    onPressed: isLoading
                        ? null
                        : () {
                            handleForgotPassword();
                          },
                    child: isLoading
                        ? Center(
                          child: const CupertinoActivityIndicator(
                            ),
                        )
                        : const Center(
                            child: Text(
                              'Get Verification Code',
                            ),
                          ),
                  ),
                ),
              ],
            ),
          )),
        ));
  }

  void handleForgotPassword() async {
    if (emailController.text == '' ||
        !HelperFunctions.isValidEmail(emailController.text)) {
    } else {
      try {
        setState(() {
          isLoading = true;
        });

        final response = await _dioService.dio.post(
          LarosaLinks.forgetPassword,
          data: jsonEncode(
            {
              "email": emailController.text,
            },
          ),
        );

        if (response.statusCode == 200) {
          if (mounted) {
            //context.push('/verification', extra: emailController.text);
            // cupertino page route
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => VerificationCodeScreen(
                  email: emailController.text,
                ),
              ),
            );
          }
        }
      } catch (e) {
        LogService.logError('Error $e');
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
}

