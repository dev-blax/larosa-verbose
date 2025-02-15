import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:iconsax/iconsax.dart';
import 'package:http/http.dart' as http;
import 'package:larosa_block/Components/bottom_navigation.dart';
import 'package:larosa_block/Features/Profiles/Components/favourites.dart';
import 'package:larosa_block/Features/Profiles/Components/personal_cover.dart';
import 'package:larosa_block/Features/Profiles/Components/personal_details.dart';
import 'package:larosa_block/Features/Profiles/Components/self_all_posts.dart';
import 'package:larosa_block/Features/Profiles/Components/self_image_posts.dart';
import 'package:larosa_block/Features/Profiles/Components/self_liked_strings.dart';
import 'package:larosa_block/Features/Profiles/Components/statistics.dart';
import 'package:larosa_block/Services/auth_service.dart';
import 'package:larosa_block/Services/log_service.dart';
import 'package:larosa_block/Utils/colors.dart';
import 'package:larosa_block/Utils/helpers.dart';
import 'package:larosa_block/Utils/links.dart';
import 'package:larosa_block/Utils/svg_paths.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';

import 'dashboard.dart';

class HomeProfileScreen extends StatefulWidget {
  const HomeProfileScreen({super.key});

  @override
  State<HomeProfileScreen> createState() => _HomeProfileScreenState();
}

class _HomeProfileScreenState extends State<HomeProfileScreen> {
  Map<String, dynamic>? profile;
  bool isLoading = true;

  Future<void> _saveProfileLocally(Map<String, dynamic> data) async {
    var box = Hive.box('profileBox');
    LogService.logDebug('saving profile locally: data $data');
    await box.put('profileData', jsonEncode(data));
  }

  Future<Map<String, dynamic>?> _getProfileFromLocal() async {
    var box = Hive.box('profileBox');
    String? profileData = box.get('profileData');
    if (profileData != null) {
      LogService.logDebug('retrieved profile locally: $profileData');
      return jsonDecode(profileData);
    }
    return null;
  }

  Future<void> _fetchProfile({bool forceRefresh = false}) async {
    String token = AuthService.getToken();

    if (token.isEmpty) {
      LogService.logError('no token found');
      HelperFunctions.logout(context);
      return;
    }

    Map<String, dynamic>? localProfile = await _getProfileFromLocal();

    if (localProfile != null) {
      setState(() {
        profile = localProfile;
        isLoading = false;
      });
    } else {
      HelperFunctions.larosaLogger('No local profile found');
    }

    Map<String, String> headers = {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
      'Authorization': 'Bearer $token',
    };

    final bool isBusiness = AuthService.isBusinessAccount();

    LogService.logInfo('isBusinessAccount $isBusiness');
    var url = Uri.https(
      LarosaLinks.nakedBaseUrl,
      !isBusiness ? '/personal/myProfile' : '/brand/myProfile',
    );

    try {
      HelperFunctions.larosaLogger('profile Id: ${AuthService.getProfileId()}');
      final response = await http.post(
        url,
        headers: headers,
      );

      if (response.statusCode == 200) {
        HelperFunctions.larosaLogger('200 OK Fetching profile');
        LogService.logInfo('loaded profile successfully');

        final Map<String, dynamic> data = json.decode(response.body);
        LogService.logInfo('profiel data: $data');

        setState(() {
          profile = data;
          isLoading = false;
        });

        LogService.logFatal('profile: $profile');

        await _saveProfileLocally(data);

        return;
      }

      //await AuthService.refreshToken();
      bool isRefreshed = await AuthService.booleanRefreshToken();
      if (!isRefreshed) {
        HelperFunctions.logout(context);
        return;
      }
      await _fetchProfile(forceRefresh: true);
      return;
    } catch (e) {
      LogService.logError(
        'An error occurred while loading profile: ',
      );
      //HelperFunctions.displaySnackbar('Operation Failed');
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchProfile();
    });
  }

  Widget _businessCoverAndDetails() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CachedNetworkImage(
          imageUrl: profile!['coverPhoto'] ??
              'https://images.pexels.com/photos/1123250/pexels-photo-1123250.jpeg?auto=compress&cs=tinysrgb&w=600',
          height: 200,
          width: MediaQuery.of(context).size.width,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.low,
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
        const Positioned(
          bottom: 5,
          left: 10,
          child: Text(
            " Monthly Orders",
            style: TextStyle(color: Colors.white),
          ),
        ),
        Positioned(
          right: 12,
          bottom: -70,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(70),
            child: profile!['profilePicture'] != null
                ? CachedNetworkImage(
                    imageUrl: profile!['profilePicture'] ??
                        'https://images.pexels.com/photos/4202392/pexels-photo-4202392.jpeg?auto=compress&cs=tinysrgb&w=600',
                    fit: BoxFit.cover,
                    height: 140,
                    width: 140,
                    filterQuality: FilterQuality.low,
                  )
                : const Icon(
                    Iconsax.user4,
                    color: Colors.red,
                    size: 140,
                  ),
          ),
        ),
      ],
    );
  }

  Widget _businessDetails() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                profile!['name'],
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const Gap(5),
              SvgPicture.asset(
                SvgIconsPaths.sharpVerified,
                colorFilter:
                    const ColorFilter.mode(Colors.blue, BlendMode.srcIn),
                height: 20,
              ),
            ],
          ),
          Text(
            //"business Name",
            profile!['username'],
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Row(
            children: [
              SvgPicture.asset(
                'assets/icons/MaterialSymbolsKidStar.svg',
                width: 20,
                height: 20,
                colorFilter:
                    const ColorFilter.mode(Colors.orange, BlendMode.srcIn),
                semanticsLabel: 'Rate Icon',
              ),
              const SizedBox(
                width: 5,
              ),
              Text(
                profile!['rates'].toString(),
                style: const TextStyle(fontWeight: FontWeight.w700),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _actionButtons(bool isLoading) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                context.pushNamed('settings');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: isLoading
                      ? const SpinKitCircle(
                          size: 16,
                          color: LarosaColors.light,
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Iconsax.setting,
                              color: Colors.white,
                            ),
                            SizedBox(
                              width: 4,
                            ),
                            Text(
                              'Settings',
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            )
                          ],
                        ),
                ),
              ),
            ),
          ),
          const Gap(5),

          Expanded(
            child: InkWell(
              onTap: () {
                //Get.to(const EditProfileScreen());
                context.pushNamed('profile_edit');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                    //color: Colors.grey.withOpacity(0.4),
                    border: Border.all(color: LarosaColors.primary, width: 2),
                    borderRadius: BorderRadius.circular(30)),
                child: Center(
                  child: isLoading
                      ? const SpinKitCircle(
                          size: 16,
                          color: LarosaColors.primary,
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              'assets/svg_icons/MaterialSymbolsPersonEditOutlineRounded.svg',
                              height: 23,
                              colorFilter: const ColorFilter.mode(
                                LarosaColors.primary,
                                BlendMode.srcIn,
                              ),
                              semanticsLabel: '',
                            ),
                            const SizedBox(
                              width: 4,
                            ),
                            Text(
                              'Edit Profile',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                    color: LarosaColors.primary,
                                  ),
                            )
                          ],
                        ),
                ),
              ),
            ),
          ),

          const Gap(5),

          // share
          Expanded(
            child: InkWell(
              onTap: () {
                Share.share(
                  'Check this new social media platfrom: explorelarosa.com',
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [LarosaColors.primary, LarosaColors.secondary],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight),
                    borderRadius: BorderRadius.circular(30)),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        SvgIconsPaths.streamlineSend,
                        height: 20,
                        colorFilter: const ColorFilter.mode(
                          LarosaColors.light,
                          BlendMode.srcIn,
                        ),
                        semanticsLabel: 'A red up arrow',
                      ),
                      const SizedBox(
                        width: 4,
                      ),
                      Text(
                        'Share',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: LarosaColors.light,
                            ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget profileShimmer(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image Shimmer
            Stack(
              children: [
                Shimmer.fromColors(
                  baseColor: isDarkMode ? Colors.grey[900]! : Colors.grey[400]!,
                  highlightColor:
                      isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
                  child: Container(
                    height: 180, // Adjust height to match your cover image
                    width: double.infinity,
                    color: Colors.grey[300],
                  ),
                ),
                // Profile Image Shimmer (positioned inside and to the right)
                Positioned(
                  bottom: 10,
                  right: 16,
                  child: Shimmer.fromColors(
                    baseColor:
                        isDarkMode ? Colors.grey[900]! : Colors.grey[400]!,
                    highlightColor:
                        isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Colors.grey[300],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Profile Info Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(width: 16), // Add spacing for alignment
                  // Text Shimmer for Username, Handle, and Bio
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Shimmer.fromColors(
                        baseColor:
                            isDarkMode ? Colors.grey[900]! : Colors.grey[400]!,
                        highlightColor:
                            isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
                        child: Container(
                          width: 150,
                          height: 15,
                          color: Colors.grey[300],
                        ),
                      ),
                      const SizedBox(height: 5),
                      Shimmer.fromColors(
                        baseColor:
                            isDarkMode ? Colors.grey[900]! : Colors.grey[400]!,
                        highlightColor:
                            isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
                        child: Container(
                          width: 100,
                          height: 10,
                          color: Colors.grey[300],
                        ),
                      ),
                      const SizedBox(height: 5),
                      Shimmer.fromColors(
                        baseColor:
                            isDarkMode ? Colors.grey[900]! : Colors.grey[400]!,
                        highlightColor:
                            isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
                        child: Container(
                          width: 200,
                          height: 10,
                          color: Colors.grey[300],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Info Counters (Powersize, Strings, Following, Followers)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(4, (index) {
                  return Column(
                    children: [
                      Shimmer.fromColors(
                        baseColor:
                            isDarkMode ? Colors.grey[900]! : Colors.grey[400]!,
                        highlightColor:
                            isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
                        child: Container(
                          width: 60,
                          height: 10,
                          color: Colors.grey[300],
                        ),
                      ),
                      const SizedBox(height: 5),
                      Shimmer.fromColors(
                        baseColor:
                            isDarkMode ? Colors.grey[900]! : Colors.grey[400]!,
                        highlightColor:
                            isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
                        child: Container(
                          width: 40,
                          height: 10,
                          color: Colors.grey[300],
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
            const SizedBox(height: 20),
            // Buttons (Settings, Edit Profile, Share)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Shimmer.fromColors(
                    baseColor:
                        isDarkMode ? Colors.grey[900]! : Colors.grey[400]!,
                    highlightColor:
                        isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
                    child: Container(
                      width: 100,
                      height: 35,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: Colors.grey[300],
                      ),
                    ),
                  ),
                  Shimmer.fromColors(
                    baseColor:
                        isDarkMode ? Colors.grey[900]! : Colors.grey[400]!,
                    highlightColor:
                        isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
                    child: Container(
                      width: 100,
                      height: 35,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: Colors.grey[300],
                      ),
                    ),
                  ),
                  Shimmer.fromColors(
                    baseColor:
                        isDarkMode ? Colors.grey[900]! : Colors.grey[400]!,
                    highlightColor:
                        isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
                    child: Container(
                      width: 100,
                      height: 35,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: Colors.grey[300],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Four small buttons above the grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(10, (index) {
                  return Shimmer.fromColors(
                    baseColor:
                        isDarkMode ? Colors.grey[900]! : Colors.grey[400]!,
                    highlightColor:
                        isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.rectangle,
                        color: Colors.grey[300],
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Grid Items Placeholder
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:
                      2, // Matching the 2-column structure in your screenshot
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1,
                ),
                itemCount: 4, // Placeholder count for grid items
                itemBuilder: (context, index) {
                  return Shimmer.fromColors(
                    baseColor:
                        isDarkMode ? Colors.grey[900]! : Colors.grey[400]!,
                    highlightColor:
                        isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => _fetchProfile(forceRefresh: true),
      child: isLoading
          ? profileShimmer(
              context) // Use the ProfileShimmer widget when loading
          : Scaffold(
              body: Stack(
                children: [
                  NestedScrollView(
                    headerSliverBuilder:
                        (BuildContext context, bool innerBoxIsScrolled) {
                      return <Widget>[
                        SliverToBoxAdapter(
                          child: profile!['accountTypeName'] != 'PERSONAL'
                              ? _businessCoverAndDetails()
                              : PersonalCoverComponent(
                                  isLoading: false,
                                  profile: profile!,
                                ),
                        ),
                        SliverList(
                          delegate: SliverChildListDelegate(
                            [
                              profile!['accountTypeName'] != 'PERSONAL'
                                  ? _businessDetails()
                                  : PersonaDetailsComponent(
                                      isLoading: false,
                                      profile: profile,
                                    ),
                              // _statistics(false),
                              StatisticsComponent(
                                followers: profile!['followers'],
                                isLoading: false,
                                profile: profile,
                              ),
                              _actionButtons(false),
// Text('Hello ${AuthService.isBusinessAccount()}'),
                              if (AuthService.isBusinessAccount())
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        final int? supplierId =
                                            AuthService.getProfileId();

                                        if (supplierId != null) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  Dashboard(
                                                      supplierId: supplierId
                                                          .toString()),
                                            ),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Supplier ID not found. Please try again.')),
                                          );
                                        }
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 2),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10, horizontal: 30),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                              8), // Rounded corners
                                          gradient: const LinearGradient(
                                              colors: [
                                                LarosaColors.primary,
                                                LarosaColors.secondary
                                              ],
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight),
                                        ),
                                        child: const Text(
                                          'Business Dashboard',
                                          style: TextStyle(
                                            color: Colors.white, // Text color
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ];
                    },
                    body: DefaultTabController(
                      length: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          TabBar(
                            labelColor: Colors.blue,
                            unselectedLabelColor: Colors.black,
                            tabs: [
                              Tab(
                                child: SvgPicture.asset(
                                  'assets/svg_icons/MingcuteDotGridLine.svg',
                                  colorFilter: ColorFilter.mode(
                                      Theme.of(context).colorScheme.secondary,
                                      BlendMode.srcIn),
                                ),
                              ),
                              Tab(
                                child: SvgPicture.asset(
                                  'assets/svg_icons/IonImagesOutline.svg',
                                  colorFilter: ColorFilter.mode(
                                      Theme.of(context).colorScheme.secondary,
                                      BlendMode.srcIn),
                                  height: 22,
                                ),
                              ),
                              Tab(
                                child: SvgPicture.asset(
                                  'assets/svg_icons/SolarHeartAngleBroken.svg',
                                  colorFilter: ColorFilter.mode(
                                      Theme.of(context).colorScheme.secondary,
                                      BlendMode.srcIn),
                                ),
                              ),
                              Tab(
                                child: SvgPicture.asset(
                                  'assets/svg_icons/CircumStar.svg',
                                  height: 28,
                                  colorFilter: ColorFilter.mode(
                                      Theme.of(context).colorScheme.secondary,
                                      BlendMode.srcIn),
                                ),
                              ),
                            ],
                          ),
                          Expanded(
                            child: TabBarView(
                              children: <Widget>[
                                Animate(
                                  effects: const [
                                    SlideEffect(
                                      begin: Offset(.2, 0),
                                      end: Offset(0, 0),
                                      curve: Curves.elasticOut,
                                      duration: Duration(seconds: 4),
                                    ),
                                  ],
                                  child: SelfAllPosts(
                                    profileId: AuthService.getProfileId()!,
                                  ),
                                ),
                                Animate(
                                  effects: const [
                                    SlideEffect(
                                      begin: Offset(.2, 0),
                                      end: Offset(0, 0),
                                      curve: Curves.elasticOut,
                                      duration: Duration(seconds: 4),
                                    ),
                                  ],
                                  child: SelfImagePostsComponent(
                                    profileId: AuthService.getProfileId()!,
                                  ),
                                ),
                                Animate(
                                  effects: const [
                                    SlideEffect(
                                      begin: Offset(.2, 0),
                                      end: Offset(0, 0),
                                      curve: Curves.elasticOut,
                                      duration: Duration(seconds: 4),
                                    ),
                                  ],
                                  child: SelfLikedStringsComponent(
                                    profileId: AuthService.getProfileId()!,
                                  ),
                                ),
                                Animate(
                                  effects: const [
                                    SlideEffect(
                                      begin: Offset(.2, 0),
                                      end: Offset(0, 0),
                                      curve: Curves.elasticOut,
                                      duration: Duration(seconds: 4),
                                    ),
                                  ],
                                  child: FavouritesComponent(
                                    profileId: AuthService.getProfileId()!,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Positioned(
                    bottom: 10,
                    left: 10,
                    right: 10,
                    child: BottomNavigation(
                      activePage: ActivePage.account,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
