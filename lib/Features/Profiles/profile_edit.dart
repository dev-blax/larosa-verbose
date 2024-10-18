import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';
import 'package:larosa_block/Services/auth_service.dart';
import 'package:larosa_block/Utils/colors.dart';
import 'package:larosa_block/Utils/links.dart';


class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _fullnameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  bool isloading = true;
  Map<String, dynamic>? profile;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    String token = AuthService.getToken();
    Map<String, String> headers = {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
      'Authorization': token.isNotEmpty ? 'Bearer $token' : '',
    };

    var url = Uri.https(
      LarosaLinks.nakedBaseUrl,
      '/personal/myProfile',
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

      print('data: ${response.body}');

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
          alignment: Alignment.center,
          children: [
            CachedNetworkImage(
              imageUrl:
                  'https://images.pexels.com/photos/1590549/pexels-photo-1590549.jpeg?auto=compress&cs=tinysrgb&w=600',
              height: 200,
              width: MediaQuery.of(context).size.width,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.low,
            ),

            //
            IconButton.filled(
              onPressed: () {},
              icon: SvgPicture.asset(
                'assets/svg_icons/IonImagesOutline.svg',
                colorFilter: ColorFilter.mode(
                    Theme.of(context).colorScheme.secondary, BlendMode.srcIn),
                height: 22,
              ),
            ),
          ],
        ),
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black, Colors.transparent],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
        ),

        // profile image
        Positioned(
          right: 12,
          bottom: -70,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              alignment: Alignment.center,
              children: [
                CachedNetworkImage(
                  imageUrl:
                      'https://images.pexels.com/photos/5794559/pexels-photo-5794559.jpeg?auto=compress&cs=tinysrgb&w=600',
                  fit: BoxFit.cover,
                  height: 140,
                  width: 140,
                  filterQuality: FilterQuality.low,
                ),
                IconButton.filled(
                  onPressed: () {},
                  icon: SvgPicture.asset(
                    'assets/svg_icons/IonImagesOutline.svg',
                    colorFilter: ColorFilter.mode(
                        Theme.of(context).colorScheme.secondary,
                        BlendMode.srcIn),
                    height: 22,
                  ),
                ),
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
          onPressed: () {
           // Get.back();
          },
          icon: const Icon(
            Iconsax.arrow_left_2,
            color: LarosaColors.primary,
          ),
        ),
        title: const Text(
          'Profile',
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: LarosaColors.primary,
              ),
              //onPressed: updateUserData,
              onPressed: () {},
              child: Row(
                children: [
                  Text(
                    'Update',
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Form(
            child: Column(
              children: [
                _personalCoverAndDetails(),
                const Gap(100),
                TextField(
                  controller: _fullnameController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Iconsax.user_edit,
                      color: LarosaColors.primary,
                    ),
                    labelText: 'Name',
                    labelStyle: const TextStyle(color: LarosaColors.primary),
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
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Iconsax.user,
                      color: LarosaColors.primary,
                    ),
                    labelText: 'Username',
                    labelStyle: const TextStyle(
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
                // TextInputComponent(
                //   label: 'Username',
                //   controller: _usernameController,
                //   iconData: Iconsax.direct,
                //   inputType: TextInputType.phone,
                // ),
                const Gap(10),
                TextField(
                  minLines: 3,
                  maxLines: 5,
                  controller: _bioController,
                  decoration: InputDecoration(
                    prefixIcon: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: SvgPicture.asset(
                        'assets/svg_icons/MdiCardAccountDetailsStar.svg',
                        height: 10,
                        colorFilter: const ColorFilter.mode(
                          LarosaColors.primary,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    labelText: 'Bio',
                    //hintText: 'Drey',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                // TextInputComponent(
                //   label: 'Bio',
                //   controller: _bioController,
                //   iconData: Iconsax.direct,
                // ),
                const Gap(10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
