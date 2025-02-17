import 'dart:convert';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:iconsax/iconsax.dart';
import 'package:http/http.dart' as http;
import 'package:larosa_block/Components/text_input.dart';
import 'package:larosa_block/Features/Auth/Components/oauth_buttons.dart';
import 'package:larosa_block/Services/log_service.dart';
import 'package:larosa_block/Utils/colors.dart';
import 'package:larosa_block/Utils/helpers.dart';
import 'package:larosa_block/Utils/links.dart';
import 'package:larosa_block/Utils/validation_helpers.dart';

class PersonalRegisterScreen extends StatefulWidget {
  const PersonalRegisterScreen({super.key});

  @override
  State<PersonalRegisterScreen> createState() => _PersonalRegisterScreenState();
}

class _PersonalRegisterScreenState extends State<PersonalRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  final TextEditingController _fullnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _savePersonalUser() async {
    Map<String, String> headers = {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
    };

    var uri = Uri.https(
      LarosaLinks.nakedBaseUrl,
      LarosaLinks.registrationEndpoint,
    );

    try {
      var response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode({
          "accountTypeId": 1,
          "username": _usernameController.text,
          "email": _emailController.text,
          "password": _passwordController.text,
          "name": _fullnameController.text,
          "cityId": 1,
          "countryId": 2,
        }),
      );

      if (response.statusCode != 201) {
        LogService.logError('Error ${response.body}');
        HelperFunctions.showToast(response.body, false);
        return;
      }

      final data = jsonDecode(response.body);

      var box = Hive.box('userBox');

      box.put('profileId', data['profileId']);
      box.put('accountId', data['accountType']['id']);
      box.put('isBusiness', false);
      box.put('accountName', data['accountType']['name']);
      box.put('token', data['jwtAuthenticationResponse']['token']);
      box.put(
        'refreshToken',
        data['jwtAuthenticationResponse']['refreshToken'],
      );
      // Get.offAll(
      //   const HomeFeedsScreen(),
      // );

      context.goNamed('home');
    } catch (e) {
      LogService.logError('Error $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
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
                              'Sign Up To Explore Larosa',
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
                              iconData: Iconsax.user,
                              label: 'Name',
                              controller: _fullnameController,
                              validator:
                                  ValidationHelpers.validateRequiredField,
                            ),
                          ),
                          const Gap(10),
                          Animate(
                            effects: const [
                              SlideEffect(
                                begin: Offset(-.5, 0),
                                end: Offset(0, 0),
                                duration: Duration(seconds: 3),
                                curve: Curves.elasticOut,
                              )
                            ],
                            child: TextInputComponent(
                              inputType: TextInputType.emailAddress,
                              iconData: Iconsax.direct_inbox,
                              label: 'Email',
                              controller: _emailController,
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
                              )
                            ],
                            child: TextInputComponent(
                              iconData: Iconsax.happyemoji,
                              label: 'Username',
                              controller: _usernameController,
                              validator:
                                  ValidationHelpers.validateRequiredField,
                            ),
                          ),
                          const Gap(10),
                          Animate(
                            effects: const [
                              SlideEffect(
                                begin: Offset(-.5, 0),
                                end: Offset(0, 0),
                                duration: Duration(seconds: 3),
                                curve: Curves.elasticOut,
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
                          const Gap(10),

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
                                      end: Alignment.bottomRight,
                                    ),
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
                                        await _savePersonalUser();

                                        setState(() {
                                          isLoading = false;
                                        });
                                      }
                                    },
                                    child: const Text(
                                      'Register',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                )
                              : CupertinoActivityIndicator(
                                  radius: 15,
                                  color: LarosaColors.light,
                              ),
                          const Gap(10),

                          TextButton(
                            onPressed: () {
                              context.pushNamed('login');
                            },
                            child: const Text(
                              'Go to Login',
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
