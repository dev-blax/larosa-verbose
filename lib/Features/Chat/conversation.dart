import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:hive/hive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:larosa_block/Features/Chat/Components/chat_bubble.dart';
import 'package:larosa_block/Services/auth_service.dart';
import 'package:larosa_block/Services/log_service.dart';
import 'package:larosa_block/Utils/colors.dart';
import 'package:larosa_block/Utils/helpers.dart';
import 'package:larosa_block/Utils/links.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:go_router/go_router.dart';

class TimeBubble extends StatelessWidget {
  final String duration;
  const TimeBubble({super.key, required this.duration});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        duration,
        style: Theme.of(context).textTheme.labelMedium,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class LarosaConversation extends StatefulWidget {
  final int profileId;
  final bool isBusiness;
  final String username;

  const LarosaConversation({
    super.key,
    required this.profileId,
    required this.isBusiness,
    required this.username,
  });

  @override
  State<LarosaConversation> createState() => _LarosaConversationState();
}

class _LarosaConversationState extends State<LarosaConversation> {
  final TextEditingController messageController = TextEditingController();
  String currentUserUid = '';
  final String socketChannel = '${LarosaLinks.baseurl}/ws';
  late StompClient _stompClient;
  Map<String, dynamic>? profile;
  String fullname = '';
  bool isVerified = false;
  String profilePicture = '';
  bool isLoadingProfile = true;
  List<Widget> messageWidgets = [];
  List<String> timeBubbleTexts = [];

  String formatTime(int duration) {
    final now = DateTime.now();
    final dateTime = now.subtract(Duration(seconds: duration));

    final differenceInDays = now.difference(dateTime).inDays;

    if (differenceInDays == 0) {
      return timeago.format(dateTime, locale: 'en_short');
    } else if (differenceInDays == 1) {
      return 'Yesterday';
    } else if (differenceInDays < 7) {
      return timeago.format(dateTime); // '5 days ago'
    } else {
      final dateFormat = DateFormat('EEEE, MMMM d');
      return dateFormat.format(dateTime); // 'Friday, June 7'
    }
  }

  Future<void> _fetchUserDetails() async {
    String token = AuthService.getToken();
    Map<String, String> headers = {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
      'Authorization': 'Bearer $token',
    };

    var url = Uri.https(
      LarosaLinks.nakedBaseUrl,
      widget.isBusiness ? '/brand/visit' : '/personal/visit',
    );

    try {
      final response = await http.post(
        url,
        body: jsonEncode({
          'id': widget.profileId,
        }),
        headers: headers,
      );

      if (response.statusCode != 200) {
        //Get.snackbar('Explore Larosa', response.body);
        return;
      }

      final Map<String, dynamic> data = json.decode(response.body);

      LogService.logInfo('profile data: $data');

      setState(() {
        profile = data;
        isLoadingProfile = false;
        fullname = profile!['username'];
        isVerified = profile!['verificationStatus'] != 'VERIFIED';
        profilePicture = profile!['profilePicture'];
      });
    } catch (e) {}
  }

  Future<void> _fetchChatMessages() async {
    var box = Hive.box('userBox');
    String chatId = widget.profileId.toString();
    String localStorageKey = 'chat_$chatId';

    List<dynamic>? localMessages = box.get(localStorageKey);
    if (localMessages != null) {
      LogService.logInfo('we have local messages');
      List<Widget> bubbles = [];
      for (var chat in localMessages) {
        bool isSentByMe = chat['senderId'] == AuthService.getProfileId();

        if (chat['content'].isNotEmpty) {
          String timeBubbleText = formatTime(chat['duration']);

          if (!timeBubbleTexts.contains(timeBubbleText)) {
            timeBubbleTexts.add(timeBubbleText);
            bubbles.add(
              TimeBubble(
                duration: timeBubbleText,
              ),
            );
          }

          bubbles.add(
            Animate(
              effects: const [
                SlideEffect(),
              ],
              child: ChatBubbleComponent(
                message: chat['content'],
                isSentByMe: isSentByMe,
                messageType: MessageType.text,
                comment: chat,
              ),
            ),
          );
        }
      }

      bubbles = bubbles.reversed.toList();

      setState(() {
        messageWidgets = bubbles;
      });
    }

    String token = AuthService.getToken();
    Map<String, String> headers = {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
      'Authorization': 'Bearer $token',
    };

    var url = Uri.https(
      LarosaLinks.nakedBaseUrl,
      '/messages/${AuthService.getProfileId()}/$chatId',
    );

    try {
      LogService.logInfo('requesting chats');
      final response = await http.get(
        url,
        headers: headers,
      );

      if (response.statusCode != 200) {
        LogService.logError(' Non 200');
        return;
      }

      LogService.logInfo('got chats');

      List<dynamic> data = json.decode(response.body);

      List<Widget> bubbles = [];

      timeBubbleTexts.clear();

      for (var chat in data) {
        bool isSentByMe = chat['senderId'] == AuthService.getProfileId();

        LogService.logInfo(chat.toString());

        String timeBubbleText = formatTime(chat['duration']);

        if (!timeBubbleTexts.contains(timeBubbleText)) {
          timeBubbleTexts.add(timeBubbleText);
          bubbles.add(
            TimeBubble(
              duration: timeBubbleText,
            ),
          );
        }

        bubbles.add(
          Animate(
            effects: const [
              SlideEffect(),
            ],
            child: ChatBubbleComponent(
              message: chat['content'],
              isSentByMe: isSentByMe,
              messageType: MessageType.text,
              comment: chat,
            ),
          ),
        );
      }

      bubbles = bubbles.reversed.toList();

      setState(() {
        messageWidgets = bubbles;
      });

      box.put(localStorageKey, data);
    } catch (e) {
      LogService.logError('error: $e');
    }
  }

  Future<void> _connectToStomp(
    String url,
    Function(StompFrame) onConnectCallback,
  ) async {
    _stompClient = StompClient(
      config: StompConfig.sockJS(
        url: url,
        onConnect: onConnectCallback,
        onWebSocketError: (dynamic error) {
          print('WebSocket error occurred: $error');
        },
        onStompError: (StompFrame frame) {
          print('Stomp error occurred: ${frame.body}');
        },
        onDisconnect: (_) {
          print('Disconnected');
        },
      ),
    );
    _stompClient.activate();
  }

  void _stompController() async {
    HelperFunctions.larosaLogger('connecting to stomp');
    try {
      await _connectToStomp(
        socketChannel,
        _onConnectCallback,
      );
    } catch (e) {
      HelperFunctions.larosaLogger('Error connecting to stomp');
    }
  }

  void _onConnectCallback(StompFrame connectFrame) {
    _stompClient.subscribe(
      destination: '/user/${AuthService.getProfileId()}/queue/ack',
      callback: _onMessageReceived,
    );
  }

  void _onMessageReceived(StompFrame frame) {
    //Get.snackbar('Message Received', frame.body!);
  }

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
    _fetchChatMessages();
    _stompController();
    messageController.addListener(_onMessageChanged);
  }

  @override
  void dispose() {
    messageController.removeListener(_onMessageChanged);
    messageController.dispose();
    _stompClient.deactivate();
    super.dispose();
  }

  void _onMessageChanged() {
    setState(() {});
  }

  Future<void> _sendMessage() async {
    String token = AuthService.getToken();
    Map<String, String> headers = {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
      'Authorization': 'Bearer $token',
    };

    var url = Uri.https(
      LarosaLinks.nakedBaseUrl,
      '/message/send',
    );

    try {
      String message = messageController.text;
      messageController.clear();
      final response = await http.post(
        url,
        body: jsonEncode({
          'senderId': AuthService.getProfileId(),
          'recipientId': widget.profileId,
          'content': message,
          "tempMessageId": 1000000000,
        }),
        headers: headers,
      );

      if (response.statusCode == 403 || response.statusCode == 302) {
        await AuthService.refreshToken();
        await _sendMessage();
        return;
      }

      if (response.statusCode != 200) {
        // Get.snackbar('Explore Larosa', response.body);
        return;
      }

      HelperFunctions.larosaLogger('response: ${response.statusCode} ');

      await _fetchChatMessages();
    } catch (e) {
      HelperFunctions.larosaLogger('error: $e');
    }
  }

  Widget _chatInputs() {
    return Container(
      decoration: BoxDecoration(
        gradient: LarosaColors.blueGradient,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(5),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: messageController,
              decoration: InputDecoration(
                prefixIcon: IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Iconsax.microphone,
                    color: Colors.white,
                  ),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide.none,
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide.none,
                ),
                filled: false,
                fillColor: Colors.grey.withOpacity(.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(8),
                hintText: 'Write your message!',
                suffixIcon: IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Iconsax.camera,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const Gap(8),
          GestureDetector(
            onTap: () async {
              if (messageController.text.isNotEmpty) {
                //messageController.clear();
                await _sendMessage();
              }
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LarosaColors.blueGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Text(
                    'Send',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  Gap(5),
                  Icon(
                    Iconsax.send_14,
                    color: Colors.white,
                  )
                ],
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
      onRefresh: _fetchChatMessages,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () {
              context.pop();
            },
            icon: const Icon(
              Iconsax.arrow_left_2,
            ),
          ),
          title: Animate(
            effects: const [
              SlideEffect(),
              FadeEffect(),
            ],
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    context.push(
                      '/profilevisit/?profileId=${widget.profileId}&accountType=${widget.isBusiness}',
                    );
                  },
                  child: profilePicture.isEmpty
                      ? ClipOval(
                          child: Image.asset(
                            'assets/images/EXPLORE.png',
                            height: 40,
                            width: 40,
                            fit: BoxFit.cover,
                          ),
                        )
                      : CircleAvatar(
                          backgroundImage: profilePicture.isNotEmpty
                              ? CachedNetworkImageProvider(profilePicture)
                              : null,
                          child: profilePicture.isEmpty
                              ? const Icon(Iconsax.user4)
                              : null,
                        ),
                ),
                const Gap(10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        context.push(
                          '/profilevisit/?profileId=${widget.profileId}&accountType=${widget.isBusiness}',
                        );
                      },
                      child: Row(
                        children: [
                          Text(
                            widget.username,
                          ),
                          const Gap(3),
                          if (isVerified)
                            SvgPicture.asset(
                              'assets/svg_icons/IcSharpVerified.svg',
                              height: 18,
                              colorFilter: const ColorFilter.mode(
                                LarosaColors.primary,
                                BlendMode.srcIn,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Gap(3),
                    // Text(
                    //   'online',
                    //   style: Theme.of(context).textTheme.bodySmall,
                    // ),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: ListView(
                  reverse: true,
                  children: messageWidgets,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6),
              child: _chatInputs(),
            ),
          ],
        ),
      ),
    );
  }
}
