import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:iconsax/iconsax.dart';
import 'package:larosa_block/Services/dio_service.dart';
import 'package:larosa_block/Services/log_service.dart';
import 'package:larosa_block/Utils/helpers.dart';
import 'package:larosa_block/Utils/links.dart';
import 'package:provider/provider.dart';
import '../../Utils/colors.dart';
import '../Feeds/Controllers/business_post_controller.dart';

class BusinessRegisterScreen extends StatefulWidget {
  const BusinessRegisterScreen({super.key});

  @override
  State<BusinessRegisterScreen> createState() => _BusinessRegisterScreenState();
}

class _BusinessRegisterScreenState extends State<BusinessRegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final DioService _dioService = DioService();
  int? _selectedCountry;
  String _businessName = '';
  String _userName = '';
  String _email = '';
  String _password = '';
  bool isSaving = false;
  int businessCategoryId = 0;
  List<dynamic> _countries = [];
  bool acceptedTerms = false;
  bool acceptedPrivacy = false;

  // initState
  @override
  void initState() {
    super.initState();
    fetchCountries();
  }

  Future<void> fetchCountries() async {

    try {
      var response = await _dioService.dio.post('${LarosaLinks.baseurl}/countries/all');
      var jsonResponse = response.data;
      setState(() {
        _countries = jsonResponse;
      });
    } catch (e) {
      LogService.logError(e.toString());
    }
  }

  Future<void> _saveBusinessAccount() async {

    try {
      setState(() {
        isSaving = true;
      });

      var response = await _dioService.dio.post(
        '${LarosaLinks.baseurl}/api/v1/accounts/register',
        data: jsonEncode({
          "name": _businessName,
          "accountTypeId": 2,
          "username": _userName.toLowerCase().trim(),
          "email": _email,
          "password": _password,
          "businessCategoryIds": [businessCategoryId],
          "cityId": 1,
          "countryId": 1,
          "street": "123 Main Street",
          "latitude": 37.7749,
          "longitude": -122.4194
        }),
      );

      final data = response.data;
      var box = Hive.box('userBox');
      await box.clear();
      box.put('profileId', data['profileId']);
      box.put('accountId', data['accountType']['id']);
      box.put('isBusinessAccount', true);
      box.put('accountName', data['accountType']['name']);
      box.put('token', data['jwtAuthenticationResponse']['token']);
      box.put(
        'refreshToken',
        data['jwtAuthenticationResponse']['refreshToken'],
      );

      HelperFunctions.showToast('Welcome To Explore Larosa', true);

      context.go('/');
    } catch (e) {
      LogService.logError('Error: $e');
    } finally {
      setState(() {
        isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          Stack(
            children: [
              CachedNetworkImage(
                imageUrl:
                    'https://images.pexels.com/photos/5414010/pexels-photo-5414010.jpeg?auto=compress&cs=tinysrgb&w=600',
                height: 300,
                width: MediaQuery.of(context).size.width,
                fit: BoxFit.cover,
              ),
              Positioned(
                width: MediaQuery.of(context).size.width,
                bottom: 0,
                child: Container(
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      const Icon(
                        Iconsax.shop,
                        color: Colors.white,
                      ),
                      const Gap(10),
                      Text(
                        'Business Registration',
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                              color: Colors.white,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Gap(20),
                  const Text('Business Category'),
                  Consumer<BusinessCategoryProvider>(
                    builder: (context, categoryProvider, child) {
                      return DropdownButtonFormField<int>(
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(20)),
                            borderSide: BorderSide.none,
                          ),
                          fillColor: Theme.of(context).colorScheme.onPrimary,
                          filled: true,
                        ),
                        items:
                            categoryProvider.businessCategories.map((category) {
                          return DropdownMenuItem<int>(
                            value: category['id'],
                            child: Text(category['name']),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              businessCategoryId = value;
                            });
                          }
                        },
                        isExpanded: true,
                        hint: const Text("Search"),
                        validator: (value) => value == null
                            ? "Please select a business category"
                            : null,
                      );
                    },
                  ),
                  const Gap(20),
                  const Text('Business Name'),
                  TextFormField(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.onPrimary,
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _businessName = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a business name';
                      }
                      return null;
                    },
                  ),
                  const Gap(20),
                  const Text('Username'),
                  TextFormField(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.onPrimary,
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _userName = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a username';
                      }
                      return null;
                    },
                  ),
                  const Gap(20),
                  const Text('Country of Operation'),
                  DropdownButtonFormField<int>(
                    icon: const Icon(Iconsax.arrow_circle_down),
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                        borderSide: BorderSide.none,
                      ),
                      fillColor: Theme.of(context).colorScheme.onPrimary,
                      filled: true,
                    ),
                    value: _selectedCountry,
                    items: _countries.map((var country) {
                      return DropdownMenuItem<int>(
                        value: country['id'],
                        child: Text(country['name']),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedCountry = newValue;
                      });
                    },
                    validator: (value) {
                      if (value == null || value == 0) {
                        return 'Please select a country of operation';
                      }
                      return null;
                    },
                  ),
                  const Gap(20),
                  const Text('Business Email'),
                  TextFormField(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.onPrimary,
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (value) {
                      setState(() {
                        _email = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                          .hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const Gap(20),
                  const Text('Password'),
                  TextFormField(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.onPrimary,
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    obscureText: true,
                    onChanged: (value) {
                      setState(() {
                        _password = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      } else if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const Gap(30),
                  Row(
                    children: [
                      Checkbox(
                        value: acceptedTerms,
                        onChanged: (value) {
                          setState(() {
                            acceptedTerms = value ?? false;
                          });
                        },
                        checkColor: Colors.white,
                        fillColor: MaterialStateProperty.resolveWith<Color>(
                          (Set<MaterialState> states) {
                            return LarosaColors.primary;
                          },
                        ),
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
                              style: const TextStyle(color: Colors.white),
                              children: [
                                TextSpan(
                                  text: 'Terms of Service',
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
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
                        fillColor: WidgetStateProperty.resolveWith<Color>(
                          (Set<WidgetState> states) {
                            return LarosaColors.primary;
                          },
                        ),
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
                              style: const TextStyle(color: Colors.white),
                              children: [
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
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
                      ? (!isSaving
                          ? Container(
                              width: MediaQuery.of(context).size.width,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xff34a4f9),
                                    Color(0xff0a1282)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              height: 65,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  elevation: 0,
                                  backgroundColor: Colors.transparent,
                                ),
                                onPressed: () async {
                                  if (_formKey.currentState!.validate() &&
                                      !isSaving) {
                                    await _saveBusinessAccount();
                                  } else {
                                    // snackbar
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Please fill all the fields')),
                                    );
                                  }
                                },
                                child: isSaving
                                    ? const SpinKitThreeBounce(
                                        color: Colors.white,
                                      )
                                    : const Text(
                                        'Create Business Account',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 18,
                                        ),
                                      ),
                              ),
                            )
                          : Center(
                            child: const CupertinoActivityIndicator(
                                radius: 15,
                                color: Colors.white,
                              ),
                          ))
                      : const Text(
                          'Please accept the terms and privacy policy to continue',
                          style: TextStyle(color: Colors.white),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
