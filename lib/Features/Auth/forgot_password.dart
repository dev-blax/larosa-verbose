import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:larosa_block/Services/log_service.dart';
import 'package:larosa_block/Utils/helpers.dart';
import 'package:larosa_block/Utils/links.dart';
import 'package:larosa_block/Services/dio_service.dart';

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
                  child: Container(
                    height: 65,
                    decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xff34a4f9), Color(0xff0a1282)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(20)),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          elevation: 0.0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.all(16.0),
                          backgroundColor: Colors.transparent),
                      onPressed: isLoading
                          ? null
                          : () {
                              handleForgotPassword();
                            },
                      child: isLoading
                          ? const SpinKitCircle(
                              color: Colors.blue,
                            )
                          : const Center(
                              child: Text(
                                'SEND LINK',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
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

        LogService.logInfo('sending forgot password ');

        await _dioService.dio.post(
          LarosaLinks.forgetPassword,
          data: jsonEncode(
            {
              "email": emailController.text,
            },
          ),
        );
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
