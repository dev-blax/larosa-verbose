import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:larosa_block/Components/bottom_navigation.dart';
import 'package:larosa_block/Components/image_viewer.dart';
import 'package:larosa_block/Features/Search/Components/search_delegate.dart';
import 'package:larosa_block/Utils/colors.dart';
import 'package:larosa_block/Utils/links.dart';
import 'package:larosa_block/Utils/svg_paths.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../Services/auth_service.dart';
import '../../Services/dio_service.dart';
import '../../Services/log_service.dart';
import 'widgets/fullscreen_video_viewer.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static List<dynamic> suggestions = [];
  bool isLoadingSuggestions = true;
  bool isLoadingMore = false;
  int currentPage = 1;
  final Map<int, String> _videoThumbnails = {};
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSavedSuggestions();
    });
    _scrollController.addListener(_onScroll);
  }

  bool _isVideo(String url) {
    final mimeType = lookupMimeType(url);
    return mimeType != null && mimeType.startsWith('video/');
  }

  Future<void> _generateVideoThumbnail(String url, int index) async {
    final directory = await getTemporaryDirectory();
    final thumbnailPath = await VideoThumbnail.thumbnailFile(
      video: url,
      thumbnailPath: directory.path,
      imageFormat: ImageFormat.JPEG,
      maxWidth: 640,
      quality: 90,
    );

    if (thumbnailPath != null) {
      // Save the thumbnail path to local storage
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('video_thumbnail_$index', thumbnailPath);

      setState(() {
        _videoThumbnails[index] = thumbnailPath;
      });
    }
  }

  Future<void> _loadSavedSuggestions() async {
    LogService.logInfo('Loading saved suggestions');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedSuggestions = prefs.getString('suggestions');

    if (savedSuggestions != null) {
      LogService.logInfo('Loading saved suggestions');
      setState(() {
        suggestions = json.decode(savedSuggestions);
        isLoadingSuggestions = false;
      });

      // Load previously saved video thumbnails
      for (int i = 0; i < suggestions.length; i++) {
        String? thumbnailPath = prefs.getString('video_thumbnail_$i');
        if (thumbnailPath != null) {
          _videoThumbnails[i] = thumbnailPath;
        } else {
          String firstMedia = suggestions[i]['names'].split(',').toList()[0];
          if (_isVideo(firstMedia)) {
            _generateVideoThumbnail(firstMedia, i);
          }
        }
      }
    } else {
      LogService.logInfo('No saved suggestions found');
      _loadSuggestions();
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && !isLoadingMore) {
      _loadMoreSuggestions();
    }
  }

  Future<void> _loadMoreSuggestions() async {
    if (isLoadingMore) return;
    setState(() {
      isLoadingMore = true;
    });
    currentPage++;
    Map<String, dynamic> body = {
      'countryId': 1.toString(),
      'profileId': AuthService.getProfileId(),
      'page': currentPage.toString(),
    };

    LogService.logInfo('Loading more suggestions, page: $currentPage');
    LogService.logInfo('body: $body');

    final response = await DioService().dio.post(
      LarosaLinks.discover,
      data: body,
    );

    if (response.statusCode == 302 || response.statusCode == 403) {
      await AuthService.refreshToken();
      _loadMoreSuggestions();
      return;
    }

    if (response.statusCode != 200) {
      setState(() {
        isLoadingMore = false;
      });
      return;
    }

    LogService.logInfo('response: ${response.data}');

    List<dynamic> newData = response.data;
    setState(() {
      suggestions.addAll(newData);
      isLoadingMore = false;
    });

    // Save updated suggestions to SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('suggestions', json.encode(suggestions));

    for (int i = suggestions.length - newData.length; i < suggestions.length; i++) {
      String firstMedia = suggestions[i]['names'].split(',').toList()[0];
      LogService.logDebug(firstMedia);
      if (_isVideo(firstMedia)) {
        _generateVideoThumbnail(firstMedia, i);
      }
    }
  }

  Future<void> _loadSuggestions() async {
    setState(() {
      isLoadingSuggestions = true;
    });

    Map<String, dynamic> body = {
      'countryId': 1.toString(),
      'profileId': AuthService.getProfileId(),
      'page': '1',
    };

    LogService.logInfo('body: $body');

    final response = await DioService().dio.post(
      LarosaLinks.discover,
      data: body,
    );

    if (response.statusCode == 302 || response.statusCode == 403) {
      await AuthService.refreshToken();
      _loadSuggestions();
      return;
    }

    if (response.statusCode != 200) {
      setState(() {
        isLoadingSuggestions = false;
      });
      return;
    }

    LogService.logInfo('response: ${response.data}');

    List<dynamic> data = response.data;

    setState(() {
      suggestions = data;
      currentPage = 1;
      isLoadingSuggestions = false;
    });

    for (int i = 0; i < suggestions.length; i++) {
      String firstMedia = suggestions[i]['names'].split(',').toList()[0];
      LogService.logDebug(firstMedia);
      if (_isVideo(firstMedia)) {
        _generateVideoThumbnail(firstMedia, i);
      }
    }

    // Save suggestions to SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('suggestions', json.encode(suggestions));
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadSuggestions();
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text(
            'Discover',
          ),
          actions: [
            IconButton(
              onPressed: () {
                showSearch(context: context, delegate: CustomSearchDelegate());
              },
              icon: const Icon(
                CupertinoIcons.search,
              ),
            )
          ],
        ),
        body: Stack(
          children: [
            SizedBox(
              width: double.infinity,
              child: GridView.builder(
                controller: _scrollController,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 2.0,
                  mainAxisSpacing: 2.0,
                  childAspectRatio: 1,
                ),
                itemCount: isLoadingSuggestions ? 10 : suggestions.length,
                itemBuilder: (context, index) {
                  if (index >= suggestions.length) {
                    if (isLoadingMore) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return const SizedBox.shrink();
                  }
                  if (isLoadingSuggestions) {
                    return Animate(
                      effects: const [
                        ShimmerEffect(
                          duration: Duration(seconds: 1),
                        ),
                      ],
                      child: ClipRRect(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(10)),
                        child: Image.asset(
                          'assets/images/EXPLORE.png',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                    );
                  }

                  bool isVerified =
                      suggestions[index]['verification_status'] != 1;
                  var profilePicturePath = suggestions[index]['profilePicture'];
                  String name = suggestions[index]['name'];
                  List<String> medias = suggestions[index]['names'].split(',');
                  String firstMedia =
                      suggestions[index]['names'].split(',').toList()[0];

                  if (_isVideo(firstMedia)) {
                    String? thumbnailPath = _videoThumbnails[index];
                    return Animate(
                      effects: const [
                        ShimmerEffect(),
                        SlideEffect(
                          begin: Offset(0, -1),
                          end: Offset(0, 0),
                          curve: Curves.elasticOut,
                          duration: Duration(seconds: 3),
                        )
                      ],
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  FullScreenVideoViewer(videoUrl: firstMedia, post: suggestions[index],),
                            ),
                          );
                        },
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            if (thumbnailPath != null)
                              ClipRRect(
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(10),
                                ),
                                child: Image.file(
                                  File(thumbnailPath),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              )
                            else
                              const Center(
                                child: CupertinoActivityIndicator(
                                  color: LarosaColors.primary,
                                ),
                              ),
                            Container(
                              height: 70,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black.withOpacity(.8),
                                    Colors.transparent,
                                  ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundImage: profilePicturePath != null
                                        ? CachedNetworkImageProvider(
                                            profilePicturePath,
                                          ) as ImageProvider<Object>
                                        : const AssetImage(
                                            'assets/images/EXPLORE.png',
                                          ) as ImageProvider<Object>,
                                  ),
                                  const Gap(5),
                                  Text(
                                    name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge!
                                        .copyWith(
                                          color: Colors.white,
                                        ),
                                  ),
                                  const Gap(5),
                                  if (isVerified)
                                    SvgPicture.asset(
                                      SvgIconsPaths.sharpVerified,
                                      colorFilter: const ColorFilter.mode(
                                        Colors.blue,
                                        BlendMode.srcIn,
                                      ),
                                      height: 20,
                                    )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  LogService.logInfo(suggestions[index].toString());

                  return Animate(
                    effects: const [
                      SlideEffect(
                        begin: Offset(0, -.5),
                        end: Offset(0, 0),
                        curve: Curves.elasticOut,
                        duration: Duration(seconds: 3),
                      )
                    ],
                    child: Stack(
                      alignment: Alignment.bottomLeft,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ImageViewScreen(
                                  imageUrls: medias,
                                  initialIndex: index,
                                  displayName: name,
                                  postDetails: suggestions[index],
                                  onPostUpdated: (updatedPost) {
                                    setState(() {
                                      suggestions[index] = updatedPost;
                                    });
                                  },
                                ),
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius:
                                const BorderRadius.all(Radius.circular(10)),
                            child: CachedNetworkImage(
                              width: double.infinity,
                              height: double.infinity,
                              imageUrl: firstMedia,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Container(
                          height: 70,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withOpacity(.8),
                                Colors.transparent,
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundImage: profilePicturePath != null
                                    ? CachedNetworkImageProvider(
                                        profilePicturePath,
                                      ) as ImageProvider<Object>
                                    : const AssetImage(
                                        'assets/images/EXPLORE.png',
                                      ) as ImageProvider<Object>,
                              ),
                              const Gap(5),
                              Text(
                                name,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge!
                                    .copyWith(
                                      color: Colors.white,
                                    ),
                              ),
                              const Gap(5),
                              if (isVerified)
                                SvgPicture.asset(
                                  SvgIconsPaths.sharpVerified,
                                  colorFilter: const ColorFilter.mode(
                                    Colors.blue,
                                    BlendMode.srcIn,
                                  ),
                                  height: 20,
                                )
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: BottomNavigation(
                activePage: ActivePage.search,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
