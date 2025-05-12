import 'dart:convert';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:iconsax/iconsax.dart';
import 'package:larosa_block/Components/text_input.dart';
import 'package:larosa_block/Features/Auth/Components/oauth_buttons.dart';
import 'package:larosa_block/Features/Auth/email_verification_code_screen.dart';
import 'package:larosa_block/Services/dio_service.dart';
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
  bool acceptedTerms = false;
  bool acceptedPrivacy = false;
  final TextEditingController _fullnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final DioService _dioService = DioService();

  Future<void> _savePersonalUser() async {
    try {
      setState(() {
        isLoading = true;
      });

      final response = await _dioService.dio.post(
        '${LarosaLinks.baseurl}/api/v1/auth/register',
        data: jsonEncode({
          "name": _fullnameController.text,
          "accountTypeId": 1,
          "username": _usernameController.text,
          "email": _emailController.text,
          "password": _passwordController.text,
          // "dob": _dobController.text,
          "cityId": 1,
          "countryId": 1,
        }),
      );

      LogService.logInfo('Registration response: ${response.data}');
      final data = response.data;
      if (response.statusCode != 201) {
        LogService.logError(
            'Registration failed with status ${response.statusCode}: ${response.data}');
        return;
      }

      LogService.logInfo('Registration successful: ${data}');

      var box = Hive.box('userBox');
      await box.clear();

      try {

        if (mounted) {
          Navigator.push(
              context,
              CupertinoPageRoute(
                  builder: (context) => EmailVerificationCodeScreen(
                        email: _emailController.text,
                      )));
        }
      } catch (storageError) {
        LogService.logError('Failed to store user data: $storageError');
        HelperFunctions.showToast(
            'Registration successful but failed to save user data. Please try logging in.',
            false);
        return;
      }
    } catch (e) {
      LogService.logError('Registration error');
      print(e);
      String errorMessage = 'Registration failed. ';

      if (e is DioException) {
        switch (e.type) {
          case DioExceptionType.connectionTimeout:
          case DioExceptionType.sendTimeout:
          case DioExceptionType.receiveTimeout:
            errorMessage += 'Please check your internet connection.';
            break;
          case DioExceptionType.badResponse:
            final responseData = e.response?.data;
            if (responseData != null) {
              try {
                final parsedData = jsonDecode(responseData);
                LogService.logError(
                    'Registration failed with message: ${parsedData}');
                errorMessage = parsedData['message'] ?? 'Please try again.';
              } catch (_) {
                errorMessage += responseData.toString();
              }
            }
            break;
          default:
            errorMessage += 'Please try again.';
        }
      }

      //HelperFunctions.showToast(errorMessage, false);
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
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
                          // const OauthButtons(),
                          const Gap(10),
                          const Divider(),
                          const Row(
                            children: [
                              Flexible(
                                child: Divider(
                                  color: CupertinoColors.white,
                                  thickness: 3,
                                  indent: 10,
                                  endIndent: 5,
                                ),
                              ),
                              Text(
                                'OR',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: CupertinoColors.white),
                              ),
                              Flexible(
                                  child: Divider(
                                color: CupertinoColors.white,
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
                            child: TextFormField(
                              readOnly: true,
                              onTap: () {
                                showCupertinoModalPopup(
                                  context: context,
                                  builder: (BuildContext context) => Container(
                                    height: 300,
                                    padding: const EdgeInsets.only(top: 6.0),
                                    color: CupertinoColors.systemBackground.darkColor,
                                    child: SafeArea(
                                      top: false,
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              CupertinoButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('Done'),
                                              ),
                                            ],
                                          ),
                                          Expanded(
                                            child: CupertinoDatePicker(
                                              mode: CupertinoDatePickerMode.date,
                                              initialDateTime: DateTime.now().subtract(const Duration(days: 365 * 18)),
                                              maximumDate: DateTime.now(),
                                              minimumDate: DateTime(1900),
                                              onDateTimeChanged: (DateTime newDate) {
                                                setState(() {
                                                  _dobController.text = DateFormat('yyyy-MM-dd').format(newDate);
                                                });
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                              keyboardType: TextInputType.datetime,
                              style: const TextStyle(color: CupertinoColors.white),
                              decoration: InputDecoration(
                                prefixIcon: Icon(Iconsax.calendar, color: CupertinoColors.white),
                                hintText: 'Date of Birth',
                                hintStyle: const TextStyle(color: CupertinoColors.white),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: const BorderSide(
                                    color: CupertinoColors.white,
                                  ),
                                ),
                                filled: false,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: const BorderSide(
                                    color: CupertinoColors.white,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: const BorderSide(
                                    color: CupertinoColors.white,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: const BorderSide(
                                    color: CupertinoColors.white,
                                  ),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: const BorderSide(
                                    color: CupertinoColors.white,
                                  ),
                                ),
                              ),
                              // inputType: TextInputType.datetime,
                              // iconData: Iconsax.calendar,
                              // label: 'Date of Birth',
                              controller: _dobController,
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

                          // Terms and Privacy Policy checkboxes
                          Row(
                            children: [
                              Checkbox(
                                value: acceptedTerms,
                                onChanged: (value) {
                                  setState(() {
                                    acceptedTerms = value ?? false;
                                  });
                                },
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(5),
                                  ),
                                ),
                                checkColor: Colors.white,
                                fillColor: WidgetStatePropertyAll(CupertinoColors.systemBlue),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      acceptedTerms = !acceptedTerms;
                                    });
                                  },
                                  child: RichText(
                                    text: TextSpan(
                                      text: 'I accept the ',
                                      style:
                                          const TextStyle(color: Colors.white),
                                      children: [
                                        TextSpan(
                                          text: 'Terms of Service',
                                          style: const TextStyle(
                                            color: Colors.blue,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () {
                                              HelperFunctions.launchURL(
                                                  'https://explore-larosa.serialsoftpro.com/terms',
                                                  context);
                                            },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Checkbox(
                                value: acceptedPrivacy,
                                onChanged: (value) {
                                  setState(() {
                                    acceptedPrivacy = value ?? false;
                                  });
                                },
                                checkColor: Colors.white,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(5),
                                  ),
                                ),
                                fillColor: WidgetStatePropertyAll(CupertinoColors.systemBlue),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      acceptedPrivacy = !acceptedPrivacy;
                                    });
                                  },
                                  child: RichText(
                                    text: TextSpan(
                                      text: 'I accept the ',
                                      style:
                                          const TextStyle(color: Colors.white),
                                      children: [
                                        TextSpan(
                                          text: 'Privacy Policy',
                                          style: const TextStyle(
                                            color: Colors.blue,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () {
                                              HelperFunctions.launchURL(
                                                  'https://explore-larosa.serialsoftpro.com/privacy',
                                                  context);
                                            },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Gap(10),

                          (acceptedTerms && acceptedPrivacy)
                              ? (!isLoading
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
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          padding: const EdgeInsets.all(16.0),
                                          backgroundColor: Colors.transparent,
                                        ),
                                        onPressed: () async {
                                          if (_formKey.currentState!
                                              .validate()) {
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
                                    ))
                              : const Text(
                                  'Please accept the terms and privacy policy to continue',
                                  style: TextStyle(color: Colors.white),
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

  @override
  void dispose() {
    _fullnameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _dobController.dispose();
    super.dispose();
  }
}
