import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:go_router/go_router.dart';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:gap/gap.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:larosa_block/Services/auth_service.dart';
import 'package:larosa_block/Services/log_service.dart';
import 'package:larosa_block/Utils/colors.dart';
import 'package:larosa_block/Utils/helpers.dart';
import 'package:larosa_block/Utils/links.dart';
import 'package:dio/dio.dart' as dio;

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _fullnameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  bool isUpdating = false;
  bool isloading = true;
  String? _selectedProfilePath;
  String? _selectedCoverImage;
  Map<String, dynamic>? profile;
  final client = dio.Dio();

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _updateProfile() async {
    String token = AuthService.getToken();
    Map<String, String> headers = {
      'content-type': 'multipart/form-data',
      "Access-Control-Allow-Origin": "*",
      'Authorization': 'Bearer $token',
    };

    dio.FormData formData = dio.FormData.fromMap({
      'profileId': AuthService.getProfileId(),
      'bio': _bioController.text,
      'address': _addressController.text,
    });

    if (_selectedCoverImage != null) {
      formData.files.add(
        MapEntry(
          'coverPhoto',
          await dio.MultipartFile.fromFile(
            _selectedCoverImage!,
          ),
        ),
      );
    }

    if (_selectedProfilePath != null) {
      formData.files.add(
        MapEntry(
          'profilePicture',
          await dio.MultipartFile.fromFile(_selectedProfilePath!),
        ),
      );
    }

    dio.Options myOptions = dio.Options(
      headers: headers,
      contentType: 'application/',
    );

    try {
      setState(() {
        isUpdating = true;
      });
      dio.Response response = await client.post(
        '${LarosaLinks.baseurl}/profile/update',
        data: formData,
        options: myOptions,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        LogService.logFatal('success');

        HelperFunctions.showToast('Profile Updated Successfully', true);
        if (context.mounted) {
          context.goNamed('homeprofile');
        }
        return;
      } else {
        LogService.logError('failed: $e');
        HelperFunctions.showToast(
          'Failed to Updated Profile! Please try again',
          false,
        );
      }
    } catch (e) {
      LogService.logError('error updating profile $e');
    } finally {
      setState(() {
        isUpdating = false;
      });
    }
  }

  Future<void> _fetchProfileData() async {
    String token = AuthService.getToken();
    Map<String, String> headers = {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
      'Authorization': token.isNotEmpty ? 'Bearer $token' : '',
    };

    bool isBusinessAccount = AuthService.isBusinessAccount();

    var url = Uri.https(
      LarosaLinks.nakedBaseUrl,
      isBusinessAccount ? '/brand/myProfile' : '/personal/myProfile',
    );

    try {
      final response = await http.post(
        url,
        body: jsonEncode({
          'id': AuthService.getProfileId(),
        }),
        headers: headers,
      );

      if (response.statusCode != 200) {
        // Get.snackbar('Explore Larosa', response.body);
        return;
      }

      LogService.logFatal('data: ${response.body}');

      final Map<String, dynamic> data = json.decode(response.body);

      setState(() {
        profile = data;
        _fullnameController.text = profile!['name'];
        _usernameController.text = profile!['username'];
        _bioController.text = profile!['bio'] ?? 'write';
      });
    } catch (e) {
      // Get.snackbar('Explore Larosa', 'an error occured');
    }
  }

  Widget _personalCoverAndDetails() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // cover image
        Stack(
          alignment: Alignment.topRight,
          children: [
            _selectedCoverImage != null
                ? Image.file(
                    File(_selectedCoverImage!),
                    height: 200,
                    width: MediaQuery.of(context).size.width,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                  )
                : profile!['coverPhoto'] != null
                    ? CachedNetworkImage(
                        imageUrl: profile!['coverPhoto'],
                        height: 200,
                        width: MediaQuery.of(context).size.width,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.high,
                      )
                    : CachedNetworkImage(
                        imageUrl:
                            'https://images.pexels.com/photos/1590549/pexels-photo-1590549.jpeg?auto=compress&cs=tinysrgb&w=600',
                        height: 200,
                        width: MediaQuery.of(context).size.width,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.low,
                      ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                child: IconButton(
                    onPressed: () async {
                      final XFile? image = await _imagePicker.pickImage(
                        source: ImageSource.gallery,
                      );
                      if (image != null) {
                        final imageData = await image.readAsBytes();
                        final String tempPath =
                            '${Directory.systemTemp.path}/${DateTime.now().millisecondsSinceEpoch}.png';
                        final File imageFile = File(tempPath)
                          ..writeAsBytesSync(imageData);
                        setState(() {
                          _selectedCoverImage = imageFile.path;
                        });
                      }
                    },
                    icon: const Icon(
                      CupertinoIcons.photo,
                    )),
              ),
            ),
          ],
        ),
        // Positioned.fill(
        //   child: Container(
        //     decoration: const BoxDecoration(
        //       gradient: LinearGradient(
        //         colors: [Colors.black, Colors.transparent],
        //         begin: Alignment.bottomCenter,
        //         end: Alignment.topCenter,
        //       ),
        //     ),
        //   ),
        // ),

        // profile image
        Positioned(
          right: 12,
          bottom: -70,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                _selectedProfilePath != null
                    ? GestureDetector(
                        onTap: () async {
                          final XFile? image = await _imagePicker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (image != null) {
                            final imageData = await image.readAsBytes();
                            final String tempPath =
                                '${Directory.systemTemp.path}/${DateTime.now().millisecondsSinceEpoch}.png';
                            final File imageFile = File(tempPath)
                              ..writeAsBytesSync(imageData);
                            setState(() {
                              _selectedProfilePath = imageFile.path;
                            });
                          }
                        },
                        child: Image.file(
                          File(
                            _selectedProfilePath!,
                          ),
                          height: 140,
                          width: 140,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.high,
                        ),
                      )
                    : profile!['coverPhoto'] != null
                        ? GestureDetector(
                            onTap: () async {
                              final XFile? image = await _imagePicker.pickImage(
                                source: ImageSource.gallery,
                              );
                              if (image != null) {
                                final imageData = await image.readAsBytes();
                                final String tempPath =
                                    '${Directory.systemTemp.path}/${DateTime.now().millisecondsSinceEpoch}.png';
                                final File imageFile = File(tempPath)
                                  ..writeAsBytesSync(imageData);
                                setState(() {
                                  _selectedProfilePath = imageFile.path;
                                });
                              }
                            },
                            child: CachedNetworkImage(
                              imageUrl: profile!['profilePicture'],
                              fit: BoxFit.cover,
                              height: 140,
                              width: 140,
                              filterQuality: FilterQuality.high,
                            ),
                          )
                        : Container(
                            height: 140,
                            width: 140,
                            color: Theme.of(context).colorScheme.secondary,
                            child: IconButton(
                              onPressed: () async {
                                final XFile? image =
                                    await _imagePicker.pickImage(
                                  source: ImageSource.gallery,
                                );
                                if (image != null) {
                                  final imageData = await image.readAsBytes();
                                  final String tempPath =
                                      '${Directory.systemTemp.path}/${DateTime.now().millisecondsSinceEpoch}.png';
                                  final File imageFile = File(tempPath)
                                    ..writeAsBytesSync(imageData);
                                  setState(() {
                                    _selectedProfilePath = imageFile.path;
                                  });
                                }
                              },
                              icon: const Icon(
                                CupertinoIcons.person_add,
                                size: 40,
                              ),
                            ),
                          ),
                // Padding(
                //   padding: const EdgeInsets.all(8.0),
                //   child: CircleAvatar(
                //     child: IconButton(
                //       onPressed: () async {
                //         final XFile? image = await _imagePicker.pickImage(
                //           source: ImageSource.gallery,
                //         );
                //         if (image != null) {
                //           final imageData = await image.readAsBytes();
                //           final String tempPath =
                //               '${Directory.systemTemp.path}/${DateTime.now().millisecondsSinceEpoch}.png';
                //           final File imageFile = File(tempPath)
                //             ..writeAsBytesSync(imageData);
                //           setState(() {
                //             _selectedProfilePath = imageFile.path;
                //           });
                //         }
                //       },
                //       icon: const Icon(
                //         CupertinoIcons.person_add,
                //       ),
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(
            CupertinoIcons.back,
            color: LarosaColors.primary,
          ),
        ),
        title: const Text(
          'Profile',
        ),
        centerTitle: true,
      ),
      body: Form(
        child: ListView(
          children: [
            _personalCoverAndDetails(),
            const Gap(100),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Name'),
                  const Gap(2),
                  TextField(
                    controller: _fullnameController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Iconsax.user_edit,
                        color: LarosaColors.primary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const Gap(10),
                  const Text('Username'),
                  const Gap(2),
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Iconsax.user,
                        color: LarosaColors.primary,
                      ),

                      //hintText: 'Drey',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const Gap(10),
                  const Text('Bio'),
                  const Gap(2),
                  TextField(
                    minLines: 3,
                    maxLines: 5,
                    controller: _bioController,
                    decoration: InputDecoration(
                      //hintText: 'Drey',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const Gap(10),
                  SizedBox(
                    width: double.infinity,
                    child: isUpdating
                        ? const SpinKitCircle(
                            color: LarosaColors.primary,
                            size: 25,
                          )
                        : FilledButton(
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              backgroundColor: LarosaColors.primary,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(20),
                                ),
                              ),
                            ),
                            //onPressed: updateUserData,
                            onPressed: _updateProfile,
                            child: Text(
                              'Update',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall!
                                  .copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
