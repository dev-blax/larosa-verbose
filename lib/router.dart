import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:larosa_block/Features/Auth/account_type.dart';
import 'package:larosa_block/Features/Auth/business_register.dart';
import 'package:larosa_block/Features/Auth/business_verification.dart';
import 'package:larosa_block/Features/Auth/forgot_password.dart';
import 'package:larosa_block/Features/Auth/personal_register.dart';
import 'package:larosa_block/Features/Auth/signin.dart';
import 'package:larosa_block/Features/Cart/main_cart.dart';
import 'package:larosa_block/Features/Chat/chats_land.dart';
import 'package:larosa_block/Features/Chat/conversation.dart';
import 'package:larosa_block/Features/Delivery/new_delivery.dart';
import 'package:larosa_block/Features/Feeds/business_post.dart';
import 'package:larosa_block/Features/Feeds/camera_content.dart';
import 'package:larosa_block/Features/Feeds/old_home_feeds.dart';
import 'package:larosa_block/Features/Feeds/profile_posts.dart';
import 'package:larosa_block/Features/Onboarding/onboarding_screen.dart';
import 'package:larosa_block/Features/Profiles/profile_edit.dart';
import 'package:larosa_block/Features/Profiles/profile_visit.dart';
import 'package:larosa_block/Features/Profiles/self_profile.dart';
import 'package:larosa_block/Features/Reels/reels.dart';
import 'package:larosa_block/Features/Search/search.dart';
import 'package:larosa_block/Features/Settings/settings.dart';
import 'package:larosa_block/splash_screen.dart';
import 'package:provider/provider.dart';
import 'Features/Feeds/Controllers/business_post_controller.dart';
import 'Features/Profiles/Components/blocked_users.dart';
import 'Services/log_service.dart';

class RouterService {
  static bool _onboarded() {
    var box = Hive.box('onboardingBox');
    bool seenOnboarding = box.get('seenOnboarding', defaultValue: false);
    return seenOnboarding;
  }

  final GoRouter router = GoRouter(
    initialLocation: _onboarded() ? '/splash' : '/onboarding',
    routes: [
      // busines post
      GoRoute(
        name: 'business-post',
        path: '/business-post',
        builder: (context, state) => const BusinessPostScreen(),
      ),

      // verification routes
      GoRoute(
        name: 'verification',
        path: '/verification',
        builder: (context, state) => const BusinessVerificationScreen(),
      ),
      // Onboarding routes
      GoRoute(
        name: 'onboarding',
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // bottom nav routes
      GoRoute(
        name: 'home',
        path: '/',
        builder: (context, state) => const OldHomeFeedsScreen(),
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
        builder: (context, state) => const NewDelivery(),
      ),
      GoRoute(
        name: 'main-post',
        path: '/main-post',
        builder: (context, state) => ChangeNotifierProvider(
          create: (context) => BusinessCategoryProvider(),
          child: const BusinessPostScreen(),
        ),
        // builder: (context, state) => const ImagePostScreen(),
      ),

      // chat routes
      GoRoute(
        name: 'chatsland',
        path: '/chatsland',
        builder: (context, state) => const ChatsLand(),
      ),
      GoRoute(
        name: 'forgot-password',
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
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

      GoRoute(
        path: '/profilePosts',
        builder: (context, state) {
          final posts = state.extra as List<dynamic>;
          final activePost = state.uri.queryParameters['activePost'];
          final title = state.uri.queryParameters['title'];
          LogService.logInfo(
            'activepost $activePost, title $title',
          );

          return ProfilePostsScreen(
            posts: posts,
            //activePost: int.tryParse(activePost ?? '0') ?? 0,
            activePost: 0,
            title: title ?? 'Explore Larosa',
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
      
      GoRoute(
        name: 'blockedList',
        path: '/blockedList',
        builder: (context, state) => const BlockedUsersScreen(),
      ),

      // auth routes
      GoRoute(
        name: 'login',
        path: '/login',
        builder: (context, state) => const SigninScreen(),
      ),

      GoRoute(
        name: 'register',
        path: '/register',
        builder: (context, state) => const PersonalRegisterScreen(),
      ),
      GoRoute(
        name: 'businessRegister',
        path: '/businessRegister',
        builder: (context, state) => const BusinessRegisterScreen(),
      ),
      GoRoute(
        name: 'accountType',
        path: '/accountType',
        builder: (context, state) => const AccountType(),
      ),

      // profile visit routes
      GoRoute(
        name: 'profilevisit',
        path: '/profilevisit',
        builder: (context, state) {
          final String profileId = state.uri.queryParameters['profileId']!;
          final bool isBusiness =
              state.uri.queryParameters['accountType'] == '2';

          return ProfileVisitScreen(
            profileId: int.parse(profileId),
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
}
