import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';
import 'package:larosa_block/Services/auth_service.dart';
import 'package:larosa_block/Services/log_service.dart';
import 'package:larosa_block/Utils/colors.dart';
import 'package:larosa_block/Utils/helpers.dart';
import 'package:larosa_block/Utils/links.dart';

class ChatsLand extends StatefulWidget {
  const ChatsLand({super.key});

  @override
  State<ChatsLand> createState() => _ChatsLandState();
}

class _ChatsLandState extends State<ChatsLand> {
  List<dynamic> chatList = [];
  late bool isLoadingChats;

  @override
  void initState() {
    super.initState();
    isLoadingChats = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchChats();
    });
  }

  Future<void> _fetchChats({int retryCount = 3}) async {
    var box = Hive.box('userBox');
    final profileId = box.get('profileId');

    if (profileId == null) {
      HelperFunctions.logout(context);
      context.go('/login');
      return;
    }

    List<dynamic>? localChats = box.get('chatList');
    if (localChats != null) {
      setState(() {
        isLoadingChats = false;
        chatList = localChats;
        chatList.sort((a, b) {
          int durationA = a['lastMessage']['duration'];
          int durationB = b['lastMessage']['duration'];
          return durationA.compareTo(durationB);
        });
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
      '/users/chat-history/$profileId',
    );

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          isLoadingChats = false;
          chatList = data;
          chatList.sort((a, b) {
            int durationA = a['lastMessage']['duration'];
            int durationB = b['lastMessage']['duration'];
            return durationA.compareTo(durationB);
          });
        });
        box.put(
          'chatList',
          data,
        );
      } else if (retryCount > 0) {
        await AuthService.refreshToken();
        await _fetchChats(retryCount: retryCount - 1);
      } else {
        throw Exception('Failed to load chats');
      }
    } catch (e) {
      if (localChats == null) {
        setState(() {
          isLoadingChats = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchChats,
      child: Scaffold(
        // backgroundColor: Colors.black,
        appBar: AppBar(
          centerTitle: true,
          leading: IconButton(
            onPressed: () {
              context.pop();
            },
            icon: const Icon(Iconsax.arrow_left_2),
          ),
          title: const Text('Chats'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: isLoadingChats
              ? const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SpinKitCircle(
                      color: LarosaColors.primary,
                    ),
                    Gap(10),
                    Text('Loading your chats...'),
                  ],
                )
              : chatList.isEmpty
                  ? Center(
                      child: Text(
                        'No chats available',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    )
                  : ListView.builder(
                      itemCount: chatList.length,
                      itemBuilder: (context, index) {
                        int duration =
                            chatList[index]['lastMessage']['duration'];
                        LogService.logInfo(
                          ' ${chatList[index]['lastMessage']['duration']}',
                        );
                        return Animate(
                          effects: [
                            SlideEffect(
                              begin: const Offset(0, -1),
                              end: const Offset(0, 0),
                              curve: Curves.elasticOut,
                              duration: const Duration(seconds: 3),
                              delay: Duration(milliseconds: 100 * index),
                            ),
                            const FadeEffect(
                              begin: 0,
                              end: 1,
                              duration: Duration(seconds: 3),
                            )
                          ],
                          child: _chat(
                            chatList[index]['username'],
                            chatList[index]['name'],
                            chatList[index]['profileId'].toString(),
                            chatList[index]['profilePicture'],
                            chatList[index]['lastMessage']['content'],
                            chatList[index]['unreadMessages'],
                            duration,
                            chatList[index]['verificationStatus'] == 'VERIFIED',
                            chatList[index]['profileId'],
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }

  Widget _chat(
    String username,
    String fullname,
    String userId,
    String? profileString,
    String lastMessage,
    int unreadMessages,
    int time,
    bool isVerified,
    int profileId,
  ) {
    DateTime messageTime = DateTime.now().subtract(Duration(seconds: time));

    return InkWell(
      onTap: () {
        context.push(
          '/conversation/$profileId?username=$username&isBusiness=false',
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: <Widget>[
            profileString == null
                ? ClipOval(
                    child: Image.asset(
                      'assets/images/EXPLORE.png',
                      height: 60,
                      width: 60,
                      fit: BoxFit.cover,
                    ),
                  )
                : CircleAvatar(
                    radius: 30,
                    backgroundImage: CachedNetworkImageProvider(profileString),
                  ),
            const Gap(10),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            fullname,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const Gap(5),
                          if (isVerified)
                            const Icon(
                              Iconsax.verify5,
                              size: 17,
                              color: Colors.blue,
                            ),
                        ],
                      ),
                      const Gap(5),
                      Text(
                        lastMessage,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        HelperFunctions.formatLastMessageTime(messageTime),
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const Gap(5),
                      if (unreadMessages > 0)
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              unreadMessages.toString(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        )
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
