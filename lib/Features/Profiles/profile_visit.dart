import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:http/http.dart' as http;
import 'package:larosa_block/Features/Profiles/Components/all_posts.dart';
import 'package:larosa_block/Features/Profiles/Components/favourites.dart';
import 'package:larosa_block/Features/Profiles/Components/image_posts.dart';
import 'package:larosa_block/Features/Profiles/Components/liked_strings.dart';
import 'package:larosa_block/Features/Profiles/Components/personal_cover.dart';
import 'package:larosa_block/Features/Profiles/Components/personal_details.dart';
import 'package:larosa_block/Features/Profiles/Components/statistics.dart';
import 'package:larosa_block/Services/auth_service.dart';
import 'package:larosa_block/Services/log_service.dart';
import 'package:larosa_block/Utils/colors.dart';
import 'package:larosa_block/Utils/helpers.dart';
import 'package:larosa_block/Utils/links.dart';
import 'package:larosa_block/Utils/svg_paths.dart';
import 'package:share_plus/share_plus.dart';

class ProfileVisitScreen extends StatefulWidget {
  final bool isBusiness;
  final int profileId;
  const ProfileVisitScreen({
    super.key,
    required this.isBusiness,
    required this.profileId,
  });

  @override
  State<ProfileVisitScreen> createState() => _ProfileVisitScreenState();
}

class _ProfileVisitScreenState extends State<ProfileVisitScreen> {
  Map<String, dynamic>? profile;
  bool isLoading = true;
  late bool isBusiness;
  late int _followers;
  late bool _isFollowing;
  List<dynamic> data = [];
  List<dynamic> posts = [];

  Future<void> _handleFollowUnfollow() async {
    print('un/following');
    String token = AuthService.getToken();
    Map<String, String> headers = {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
      'Authorization': 'Bearer $token',
    };

    var url = Uri.https(
      LarosaLinks.nakedBaseUrl,
      '/engage/follow-operation',
    );

    try {
      final response = await http.post(
        url,
        body: jsonEncode({
          'accountId': widget.profileId,
          'user': AuthService.getProfileId(),
        }),
        headers: headers,
      );

      if (response.statusCode == 403 || response.statusCode == 302) {
        await AuthService.refreshToken();
        await _handleFollowUnfollow();
        return;
      }

      if (response.statusCode == 200) {
        return;
      }

      setState(() {
        _isFollowing = !_isFollowing;
        if (_isFollowing) {
          _followers++;
        } else {
          _followers--;
        }
      });
    } catch (e) {
      // HelperFunctions.displaySnackbar('Failed to perform operation');

      setState(() {
        _isFollowing = !_isFollowing;
        if (_isFollowing) {
          _followers++;
        } else {
          _followers--;
        }
      });
    }
  }

  Future<void> _fetchProfile() async {
    LogService.logInfo('Requesting profile');
    String token = AuthService.getToken();
    if (token.isEmpty) {
      LogService.logError('No token found for profile');
      HelperFunctions.logout(context);
      return;
    }

    LogService.logInfo('token $token');

    Map<String, String> headers = {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
      'Authorization': 'Bearer $token',
    };
    var url = Uri.https(
      LarosaLinks.nakedBaseUrl,
      !isBusiness ? '/personal/visit' : '/brand/visit',
    );

    try {
      LogService.logDebug('owner id: ${widget.profileId}');

      final response = await http.post(
        url,
        body: jsonEncode({
          'ownerId': widget.profileId,
        }),
        headers: headers,
      );

      if (response.statusCode == 302 || response.statusCode == 403) {
        LogService.logDebug('Unauthorized ${response.statusCode}');
        LogService.logWarning(response.body);
        LogService.logTrace('Refreshing');
        AuthService.refreshToken();
        LogService.logTrace('fetching profile again');
        _fetchProfile();
        return;
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        LogService.logInfo('Got profile');

        final Map<String, dynamic> data = json.decode(response.body);

        LogService.logInfo('profile ${response.body}');

        setState(() {
          profile = data;
          _isFollowing = profile!['followProfile'];
          isLoading = false;
          _followers = profile!['followers'];
        });

        //await _isFollowingFuture();

        await _fetchUserPosts();

        return;
      }

      LogService.logFatal('response ${response.statusCode}');

      // Get.snackbar(
      //   'Explore Larosa',
      //   response.statusCode.toString(),
      // );
    } catch (e) {
      LogService.logError('some error: $e');
    }
  }

  Future<void> _fetchUserPosts() async {
    String token = AuthService.getToken();
    Map<String, String> headers = {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
      'Authorization': 'Bearer $token',
    };

    var url = Uri.https(
      LarosaLinks.nakedBaseUrl,
      '/feeds/fetch/specific',
    );

    try {
      final response = await http.post(
        url,
        body: jsonEncode(
          {
            'profileId': widget.profileId,
          },
        ),
        headers: headers,
      );

      if (response.statusCode != 200) {
        // Get.snackbar(
        //   'Explore Larosa',
        //   response.body,
        // );
        return;
      }

      List<dynamic> data = json.decode(response.body);
      setState(() {
        posts = data;
      });
    } catch (e) {
      print('error: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    isBusiness = widget.isBusiness;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchProfile();
    });
  }

  Widget _actionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 10,
        horizontal: 10,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Animate(
            effects: const [
              SlideEffect(
                begin: Offset(0, .4),
                end: Offset(0, 0),
                curve: Curves.elasticOut,
                duration: Duration(seconds: 2),
              )
            ],
            child: Expanded(
              flex: 4,
              child: InkWell(
                onTap: () async {
                  setState(() {
                    _isFollowing = !_isFollowing;
                    if (_isFollowing) {
                      _followers++;
                    } else {
                      _followers--;
                    }
                  });
                  await _handleFollowUnfollow();
                },
                child: ClipRRect(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: !_isFollowing ? null : Colors.grey,
                      gradient: !_isFollowing
                          ? const LinearGradient(
                              colors: [
                                LarosaColors.primary,
                                LarosaColors.secondary,
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            )
                          : null,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _isFollowing
                              ? const Icon(
                                  Iconsax.tick_circle,
                                  size: 25,
                                  color: Colors.white,
                                )
                              : const Icon(
                                  Iconsax.user_add,
                                  size: 25,
                                  color: Colors.white,
                                ),
                          const SizedBox(
                            width: 4,
                          ),
                          Text(
                            _isFollowing ? 'Following' : 'Follow',
                            style:
                                Theme.of(context).textTheme.bodyLarge!.copyWith(
                                      color: LarosaColors.softGrey,
                                    ),
                            overflow: TextOverflow.visible,
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const Gap(5),

          // chat
          Animate(
            effects: const [
              SlideEffect(
                begin: Offset(0, .4),
                end: Offset(0, 0),
                curve: Curves.elasticOut,
                duration: Duration(seconds: 2),
              )
            ],
            child: Expanded(
              flex: 3,
              child: GestureDetector(
                onTap: () {
                  // Get.to(
                  //   LarosaConversation(
                  //     username: profile!['username'],
                  //     profileId: widget.profileId,
                  //     isBusiness: widget.isBusiness,
                  //   ),
                  // );

                  String isBusiness = profile!['accountTypeId'] == 1 ? "false" : "true";

                  context.push(
                    '/conversation/${widget.profileId}?username=${profile!['username']}&isBusiness=$isBusiness',
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        LarosaColors.primary,
                        LarosaColors.secondary,
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Row(
                      children: [
                        const Icon(
                          Iconsax.message,
                          size: 25,
                          color: Colors.white,
                        ),
                        const SizedBox(
                          width: 4,
                        ),
                        Text(
                          'Text',
                          style:
                              Theme.of(context).textTheme.bodyLarge!.copyWith(
                                    color: LarosaColors.softGrey,
                                  ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Gap(5),

          // share
          Animate(
            effects: const [
              SlideEffect(
                begin: Offset(0, .4),
                end: Offset(0, 0),
                curve: Curves.elasticOut,
                duration: Duration(seconds: 2),
              )
            ],
            child: Expanded(
              flex: 3,
              child: GestureDetector(
                onTap: () {
                  Share.share(
                    'Check this new social media platfrom: explorelarosa.com',
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [
                            LarosaColors.primary,
                            LarosaColors.secondary
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight),
                      borderRadius: BorderRadius.circular(10)),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          SvgIconsPaths.streamlineSend,
                          height: 25,
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
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    color: LarosaColors.light,
                                  ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _businessCoverAndDetails() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Image.asset(
          'assets/images/banner_business.png',
          height: 200,
          width: MediaQuery.of(context).size.width,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.low,
        ),
        // Image.asset(
        //   imageUrl: profile!['coverPhoto'] ??
        //       'assets/images/banner_business.png',
        //   height: 200,
        //   width: MediaQuery.of(context).size.width,
        //   fit: BoxFit.cover,
        //   filterQuality: FilterQuality.low,
        // ),
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
                    imageUrl: profile!['profilePicture'],
                    fit: BoxFit.cover,
                    height: 140,
                    width: 140,
                    filterQuality: FilterQuality.low,
                  )
                : const CircleAvatar(
                    radius: 70,
                    child: Icon(
                      Iconsax.shop,
                      size: 60,
                    ),
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
              const Gap(10),
              if (profile!['verificationStatus'] == 'VERIFIED')
                SvgPicture.asset(
                  SvgIconsPaths.sharpVerified,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    Colors.blue,
                    BlendMode.srcIn,
                  ),
                )
            ],
          ),
          const Gap(5),
          Text(
            profile!['bio'],
            style: Theme.of(context)
                .textTheme
                .labelLarge!
                .copyWith(color: Colors.grey),
          ),
          const Gap(5),
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

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchProfile,
      child: Scaffold(
        body: isLoading
            ? NestedScrollView(
                headerSliverBuilder:
                    (BuildContext context, bool innerBoxIsScrolled) {
                  return [
                    SliverToBoxAdapter(
                      child: PersonalCoverComponent(
                        isLoading: true,
                        profile: profile,
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildListDelegate(
                        [
                          PersonaDetailsComponent(
                            isLoading: true,
                            profile: profile,
                          ),
                          StatisticsComponent(
                            followers: 0,
                            isLoading: true,
                            profile: profile,
                          )
                          //_actionButtons(true),
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
                      child: Stack(
                        alignment: Alignment.topLeft,
                        children: [
                          profile!['accountTypeName'] != 'PERSONAL'
                              ? _businessCoverAndDetails()
                              : PersonalCoverComponent(
                                  isLoading: false,
                                  profile: profile,
                                ),
                          Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: IconButton(
                              onPressed: () {
                                // => Get.back()
                              },
                              icon: const Icon(
                                Iconsax.arrow_left_2,
                                color: Colors.white,
                              ),
                            ),
                          )
                        ],
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
                          //_statistics(false),
                          StatisticsComponent(
                            followers: _followers,
                            isLoading: false,
                            profile: profile,
                          ),
                          _actionButtons(),
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
                            // All Posts
                            Animate(
                              effects: const [
                                SlideEffect(
                                  begin: Offset(.2, 0),
                                  end: Offset(0, 0),
                                  curve: Curves.elasticOut,
                                  duration: Duration(seconds: 4),
                                ),
                              ],
                              child: AllPosts(
                                profileId: widget.profileId,
                              ),
                            ),

                            // Images only
                            Animate(
                              effects: const [
                                SlideEffect(
                                  begin: Offset(.2, 0),
                                  end: Offset(0, 0),
                                  curve: Curves.elasticOut,
                                  duration: Duration(seconds: 4),
                                ),
                              ],
                              child: ImagePostsComponent(
                                profileId: widget.profileId,
                              ),
                            ),

                            // Liked Posts
                            Animate(
                              effects: const [
                                SlideEffect(
                                  begin: Offset(.2, 0),
                                  end: Offset(0, 0),
                                  curve: Curves.elasticOut,
                                  duration: Duration(seconds: 4),
                                )
                              ],
                              child: LikedStringsComponent(
                                profileId: widget.profileId,
                              ),
                            ),

                            // Favorites posts
                            Animate(
                              effects: const [
                                SlideEffect(
                                  begin: Offset(.2, 0),
                                  end: Offset(0, 0),
                                  curve: Curves.elasticOut,
                                  duration: Duration(seconds: 4),
                                )
                              ],
                              child: FavouritesComponent(
                                profileId: widget.profileId,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
