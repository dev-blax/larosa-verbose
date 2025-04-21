import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:larosa_block/Features/Feeds/Controllers/old_home_feeds_controller.dart';
import 'package:larosa_block/Features/Stories/providers/story_provider.dart';
import 'package:provider/provider.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:toastification/toastification.dart';
import 'Features/Cart/controllers/cart_controller.dart';
import 'Features/Feeds/Controllers/content_controller.dart';
import 'Features/Feeds/Controllers/home_feeds_controller.dart';
import 'Features/Feeds/Controllers/second_business_category_provider.dart';
import 'Features/Onboarding/onboarding_controller.dart';
import 'Services/auth_service.dart';
import 'Services/log_service.dart';
import 'Services/navigation_service.dart';
import 'Utils/helpers.dart';
import 'Utils/links.dart';
import 'Utils/theme.dart';
import 'router.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final routerService = RouterService();

  bool connectedToSocket = false;

  late StompClient stompClient;
  final String socketChannel =
      '${LarosaLinks.baseurl}/ws/topic/customer/${AuthService.getProfileId()}';

  Future<void> _socketConnection2() async {
    const String wsUrl = '${LarosaLinks.baseurl}/ws';
    stompClient = StompClient(
      config: StompConfig.sockJS(
        url: wsUrl,
        onConnect: onConnect,
        onWebSocketError: (dynamic error) =>
            LogService.logError('WebSocket error: $error'),
        onStompError: (StompFrame frame) =>
            LogService.logWarning('Stomp error: ${frame.body}'),
        onDisconnect: (StompFrame frame) =>
            LogService.logFatal('Disconnected from WebSocket'),
      ),
    );

    stompClient.activate();
  }
  
  void onConnect(StompFrame frame) {
    setState(() {
      connectedToSocket = true;
    });
    LogService.logInfo('Connected to WebSocket server: $frame');

    stompClient.subscribe(
      destination: '/topic/customer/${AuthService.getProfileId()}',
      callback: (StompFrame message) {
        LogService.logInfo(
          'Received message from /topic/customer/${AuthService.getProfileId()}: ${message.body}',
        );

        HelperFunctions.showToast(
          message.body.toString(),
          true,
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _socketConnection2();
    _setSystemUIOverlayStyle();
  }

  void _setSystemUIOverlayStyle() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light, 
      statusBarBrightness: Brightness.dark, 
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeFeedsController()),
        ChangeNotifierProvider(create: (_) => OldHomeFeedsController()),
        ChangeNotifierProvider(create: (_) => ContentController()),
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
        ChangeNotifierProvider(create: (_) => CartController()),
        ChangeNotifierProvider(create: (_) => StoryProvider()),
        ChangeNotifierProvider(create: (_) => SecondBusinessCategoryProvider()),

      ],
      child: ToastificationWrapper(
        child: MaterialApp.router(
          routerConfig: routerService.router,
          themeMode: ThemeMode.system,
          theme: LarosaAppTheme.lightTheme,
          darkTheme: LarosaAppTheme.darkTheme,
          builder: (context, child) {
            NavigationService.setContext(context);
            Brightness brightness = Theme.of(context).brightness;
            SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: 
                brightness == Brightness.dark ? Brightness.light : Brightness.dark,
              statusBarBrightness: 
                brightness == Brightness.dark ? Brightness.light : Brightness.dark,
              systemNavigationBarColor: 
                brightness == Brightness.dark ? Colors.black : Colors.white,
              systemNavigationBarIconBrightness: 
                brightness == Brightness.dark ? Brightness.light : Brightness.dark,
            ));
            return child!;
          },
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
