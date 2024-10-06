import 'package:flutter/material.dart';
import 'package:larosa_block/Features/Auth/signin.dart';
import 'package:larosa_block/Features/Cart/main_cart.dart';
import 'package:larosa_block/Features/Chat/chats_land.dart';
import 'package:larosa_block/Features/Chat/conversation.dart';
import 'package:larosa_block/Features/Delivery/main_delivery.dart';
import 'package:larosa_block/Features/Feeds/Controllers/content_controller.dart';
import 'package:larosa_block/Features/Feeds/Controllers/home_feeds_controller.dart';
import 'package:larosa_block/Features/Feeds/camera_content.dart';
import 'package:larosa_block/Features/Feeds/home_feeds.dart';
import 'package:larosa_block/Features/Profiles/profile_edit.dart';
import 'package:larosa_block/Features/Profiles/profile_visit.dart';
import 'package:larosa_block/Features/Profiles/self_profile.dart';
import 'package:larosa_block/Features/Reels/reels.dart';
import 'package:larosa_block/Features/Search/search.dart';
import 'package:larosa_block/Features/Settings/settings.dart';
import 'package:larosa_block/Services/log_service.dart';
import 'package:larosa_block/Utils/theme.dart';
import 'package:go_router/go_router.dart';
import 'package:larosa_block/splash_screen.dart';
import 'package:provider/provider.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final GoRouter _router = GoRouter(
    initialLocation: '/splash',
    routes: [
      // bottom nav routes
      GoRoute(
        name: 'home',
        path: '/',
        builder: (context, state) => const HomeFeedsScreen(),
      ),
      GoRoute(
        name: 'homeprofile',
        path: '/homeprofile',
        builder: (context, state) => const HomeProfileScreen(),
      ),
      GoRoute(
        name: 'search',
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        name: 'maindelivery',
        path: '/maindelivery',
        builder: (context, state) => const MainDeliveryScreen(),
      ),

      // chat routes
      GoRoute(
        name: 'chatsland',
        path: '/chatsland',
        builder: (context, state) => const ChatsLand(),
      ),
      GoRoute(
        path: '/conversation/:profileId',
        builder: (context, state) {
          final profileId = int.parse(state.pathParameters['profileId']!);
          final bool isBusiness =
              state.uri.queryParameters['isBusiness'] == 'true';
          final String username = state.uri.queryParameters['username']!;

          return LarosaConversation(
            profileId: profileId,
            isBusiness: isBusiness,
            username: username,
          );
        },
      ),

      // cart routes
      GoRoute(
        name: 'maincart',
        path: '/maincart',
        builder: (context, state) => MyCart(),
      ),

      // reels routes
      GoRoute(
        name: 'reels',
        path: '/reels',
        builder: (context, state) => const DeReelsScreen(),
      ),

      // login routes
      GoRoute(
        name: 'login',
        path: '/login',
        builder: (context, state) => const SigninScreen(),
      ),

      // profile visit routes
      GoRoute(
        name: 'profilevisit',
        path: '/profilevisit',
        builder: (context, state) {
          final profileId = state.uri.queryParameters['profileId'];
          final bool isBusiness =
              state.uri.queryParameters['accountType'] == '1';
          LogService.logDebug(
            'profileId $profileId isBusiness $isBusiness ',
          );

          return ProfileVisitScreen(
            profileId: int.parse(profileId!),
            isBusiness: isBusiness,
          );
        },
      ),

      GoRoute(
        name: 'settings',
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        name: 'profile_edit',
        path: '/profile_edit',
        builder: (context, state) => const EditProfileScreen(),
      ),

      // Splash
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // camera content
      GoRoute(
        name: 'cameraContent',
        path: '/cameraContent',
        builder: (context, state) => const CameraContent(),
      ),
    ],
  );
  @override
  Widget build(BuildContext context) {
    // return ChangeNotifierProvider(
    //   create: (_) => HomeFeedsController(),
    //   child: MaterialApp.router(
    //     routerConfig: _router,
    //     themeMode: ThemeMode.system,
    //     theme: LarosaAppTheme.lightTheme,
    //     darkTheme: LarosaAppTheme.darkTheme,
    //   ),
    // );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeFeedsController()),
        ChangeNotifierProvider(create: (_) => ContentController()),
      ],
        child: MaterialApp.router(
        routerConfig: _router,
        themeMode: ThemeMode.system,
        theme: LarosaAppTheme.lightTheme,
        darkTheme: LarosaAppTheme.darkTheme,
      ),
    );
  }
}
