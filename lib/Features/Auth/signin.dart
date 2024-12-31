import 'dart:convert';
import 'dart:ui';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:gap/gap.dart';
import 'package:iconsax/iconsax.dart';
import 'package:larosa_block/Components/text_input.dart';
import 'package:larosa_block/Features/Auth/Components/oauth_buttons.dart';
import 'package:larosa_block/Services/log_service.dart';
import 'package:larosa_block/Utils/colors.dart';
import 'package:larosa_block/Utils/helpers.dart';
import 'package:larosa_block/Utils/links.dart';
import 'package:larosa_block/Utils/routing.dart';
import 'package:larosa_block/Utils/validation_helpers.dart';

class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> signin() async {
    Map<String, String> headers = {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
    };

    var uri = Uri.https(
      LarosaLinks.nakedBaseUrl,
      LarosaLinks.loginEndpoint,
    );

    try {
      LogService.logDebug('Sending login request');
      var response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode({
          "username": _usernameController.text.trim(),
          "password": _passwordController.text.trim(),
        }),
      );

      if (response.statusCode != 200) {
        HelperFunctions.showToast(
          'Wrong credentials',
          false,
        );
        return;
      }

      final data = jsonDecode(response.body);

      var box = await Hive.openBox('userBox');
      await box.clear();
      // print('Categories : ${data}');
      box.put('profileId', data['profileId']);
      box.put('accountId', data['accountType']['id']);
      box.put('accountName', data['accountType']['name']);
      box.put('reservation', data['reservation']);
//       if (data['categories'] != null && data['categories'].isNotEmpty && data['categories'][0] != null) {
//   box.put('categories', data['categories'][0]);
// } else {
//   print('No valid categories to add.');
// }

      box.put('token', data['jwtAuthenticationResponse']['token']);
      LogService.logInfo(
          'got toke ${data['jwtAuthenticationResponse']['token']}');
      box.put(
        'refreshToken',
        data['jwtAuthenticationResponse']['refreshToken'],
      );

      Routings.home(context);
    } catch (e) {
      HelperFunctions.showToast(
        'An error occured! Please try again',
        false,
      );
      LogService.logError('error $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          //height: Helpers.screenHeight(),
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/dog-and-flower.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 30,
            vertical: 50,
          ),
          child: Animate(
            effects: const [
              SlideEffect(
                begin: Offset(0, .5),
                end: Offset(0, 0),
                duration: Duration(
                  seconds: 3,
                ),
                curve: Curves.elasticOut,
              )
            ],
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Form(
                    key: _formKey,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Center(
                            child: Text(
                              'Sign In To Explore Larosa',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall!
                                  .copyWith(
                                    color: LarosaColors.light,
                                  ),
                            ),
                          ),
                          const Gap(10),
                          const OauthButtons(),
                          const Gap(10),
                          // Divider
                          const Row(
                            children: [
                              Flexible(
                                child: Divider(
                                  color: Colors.white,
                                  thickness: 3,
                                  indent: 10,
                                  endIndent: 5,
                                ),
                              ),
                              Text(
                                'OR',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white),
                              ),
                              Flexible(
                                  child: Divider(
                                color: Colors.white,
                                thickness: 3,
                                indent: 5,
                                endIndent: 10,
                              )),
                            ],
                          ),

                          const Gap(10),
                          Animate(
                            effects: const [
                              SlideEffect(
                                begin: Offset(.5, 0),
                                end: Offset(0, 0),
                                duration: Duration(seconds: 3),
                                curve: Curves.elasticOut,
                              )
                            ],
                            child: TextInputComponent(
                              iconData: Iconsax.happyemoji,
                              label: 'Username',
                              inputType: TextInputType.name,
                              controller: _usernameController,
                              validator:
                                  ValidationHelpers.validateRequiredField,
                            ),
                          ),
                          const Gap(10),
                          Animate(
                            effects: const [
                              SlideEffect(
                                begin: Offset(.5, 0),
                                end: Offset(0, 0),
                                duration: Duration(seconds: 3),
                                curve: Curves.elasticOut,
                                delay: Duration(
                                  milliseconds: 500,
                                ),
                              )
                            ],
                            child: TextInputComponent(
                              isPassword: true,
                              iconData: Iconsax.key,
                              label: 'Password',
                              controller: _passwordController,
                              validator:
                                  ValidationHelpers.validateRequiredField,
                            ),
                          ),

                          TextButton(
                            onPressed: () => context.push('/forgot-password'),
                            child: const Text(
                              'Forgot Password',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),

                          !isLoading
                              ? Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                        colors: [
                                          Color(0xff34a4f9),
                                          Color(0xff0a1282)
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight),
                                    borderRadius: BorderRadius.circular(
                                      20,
                                    ),
                                  ),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      elevation: 0.0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.all(16.0),
                                      backgroundColor: Colors.transparent,
                                    ),
                                    onPressed: () async {
                                      if (_formKey.currentState!.validate()) {
                                        setState(() {
                                          isLoading = true;
                                        });
                                        await signin();

                                        setState(() {
                                          isLoading = false;
                                        });
                                      }
                                    },
                                    child: const Text(
                                      'Login',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                )
                              : const SpinKitCircle(
                                  color: Colors.blue,
                                ),
                          const Gap(10),

                          TextButton(
                            onPressed: () {
                              context.pushNamed('accountType');
                            },
                            child: const Text(
                              'Go to Register',
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
