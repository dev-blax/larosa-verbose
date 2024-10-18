import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
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
import 'package:shared_preferences/shared_preferences.dart';

class HomeProfileScreen extends StatefulWidget {
  const HomeProfileScreen({super.key});

  @override
  State<HomeProfileScreen> createState() => _HomeProfileScreenState();
}

class _HomeProfileScreenState extends State<HomeProfileScreen> {
  Map<String, dynamic>? profile;
  bool isLoading = true;
  bool isBusiness = false;

  Future<void> _saveProfileLocally(Map<String, dynamic> data) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    LogService.logDebug('saving profile locally: data $data');
    prefs.setString('profileData', jsonEncode(data));
  }

  Future<Map<String, dynamic>?> _getProfileFromLocal() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? profileData = prefs.getString('profileData');
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

    // If profile already exists
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
      'Authorization': token.isNotEmpty ? 'Bearer $token' : '',
    };
    var url = Uri.https(
      LarosaLinks.nakedBaseUrl,
      !isBusiness ? '/personal/myProfile' : '/brand/myProfile',
    );

    try {
      HelperFunctions.larosaLogger('profile Id: ${AuthService.getProfileId()}');
      final response = await http.post(
        url,
        // body: jsonEncode({
        //   'id': AuthService.getProfileId(),
        // }),
        headers: headers,
      );

      if (response.statusCode == 200) {
        HelperFunctions.larosaLogger('200 OK Fetching profile');
        LogService.logInfo('loaded profile successfully');
        final Map<String, dynamic> data = json.decode(response.body);

        setState(() {
          profile = data;
          isLoading = false;
        });

        await _saveProfileLocally(data);

        return;
      }

      if (response.statusCode == 403) {
        HelperFunctions.larosaLogger('403 unauthorized');
        await AuthService.refreshToken();
        await _fetchProfile(forceRefresh: true);
        return;
      }

      LogService.logInfo('neither 200 nor 403: status code is ${response.statusCode}');
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
          Text(
            'Angie Snacks',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          Text(
            'Restaurant',
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
                semanticsLabel: 'Like icon',
              ),
              const SizedBox(
                width: 5,
              ),
              const Text(
                '4.8',
                style: TextStyle(fontWeight: FontWeight.w700),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _actionButtons(bool isLoading) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
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

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => _fetchProfile(forceRefresh: true),
      child: Scaffold(
        body: Stack(
          children: [
            isLoading
                ? NestedScrollView(
                    headerSliverBuilder:
                        (BuildContext context, bool innerBoxIsScrolled) {
                      return <Widget>[
                        SliverToBoxAdapter(
                          child: PersonalCoverComponent(
                            isLoading: true,
                            profile: profile,
                          ),
                        ),
                        SliverList(
                          delegate: SliverChildListDelegate(
                            [
                              //_personalDetails(true),
                              PersonaDetailsComponent(
                                isLoading: true,
                                profile: profile,
                              ),
                              // _statistics(true),
                              StatisticsComponent(
                                followers: 0,
                                isLoading: true,
                                profile: profile,
                              ),
                              _actionButtons(true),
                            ],
                          ),
                        ),
                      ];
                    },
                    body: Container(),
                  )
                : NestedScrollView(
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
