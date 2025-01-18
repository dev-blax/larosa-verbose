import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:hive/hive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http_parser/http_parser.dart';
import 'package:iconsax/iconsax.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:larosa_block/Features/Chat/Components/chat_bubble.dart';
import 'package:larosa_block/Services/auth_service.dart';
import 'package:larosa_block/Services/log_service.dart';
import 'package:larosa_block/Utils/colors.dart';
import 'package:larosa_block/Utils/helpers.dart';
import 'package:larosa_block/Utils/links.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

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

  // Generate a unique ID for each message
  String generateMessageId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

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
      LogService.logDebug('fetching user details for ${widget.profileId}');
      final response = await http.post(
        url,
        body: jsonEncode({
          'ownerId': widget.profileId,
        }),
        headers: headers,
      );

      if (response.statusCode != 200) {
        LogService.logError('Non 200: ${response.body}');
        return;
      }

      final Map<String, dynamic> data = json.decode(response.body);

      LogService.logInfo('profile data: $data');

      setState(() {
        profile = data;
        isLoadingProfile = false;
        fullname = profile!['username'];
        isVerified = profile!['verificationStatus'] == 'VERIFIED';
        profilePicture = profile!['profilePicture'] ?? '';
      });
    } catch (e) {
      LogService.logError('Error fetching user details: $e');
    } finally {
      LogService.logInfo('Finished fetching user details');
    }
  }

  Future<void> _fetchChatMessages() async {
    var box = Hive.box('userBox');
    String chatId = widget.profileId.toString();
    String localStorageKey = 'chat_$chatId';

    List<dynamic>? localMessages = box.get(localStorageKey);
    List<Widget> bubbles = [];
    List<String> timeBubbleTexts = [];

    if (localMessages != null) {
      for (var chat in localMessages) {
        bool isSentByMe = chat['senderId'] == AuthService.getProfileId();

        // Determine the message type based on mediaUrl or mediaType
        MessageType messageType;
        if (chat['mediaUrl'] != null && chat['mediaUrl'] != '') {
          if (chat['mediaUrl'].endsWith('.mp4')) {
            messageType = MessageType.image;
          } else if (chat['mediaUrl'].endsWith('.webp') ||
              chat['mediaUrl'].endsWith('.jpg') ||
              chat['mediaUrl'].endsWith('.png')) {
            messageType = MessageType.image;
          } else {
            messageType = MessageType.audio;
          }
        } else {
          messageType = MessageType.text;
        }

        // Format and group messages by time
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
          ChatBubbleComponent(
            message: chat['mediaUrl'] ?? chat['content'],
            isSentByMe: isSentByMe,
            messageType: messageType,
            comment: chat,
          ),
        );
      }

      setState(() {
        messageWidgets =
            bubbles.reversed.toList(); // Reverse messages for latest-first view
      });
    }

    // Fetch messages from API and apply the same grouping logic
    try {
      LogService.logInfo('Requesting chats...');
      final response = await http.get(
        Uri.https(LarosaLinks.nakedBaseUrl,
            '/messages/${AuthService.getProfileId()}/$chatId'),
        headers: {
          'Authorization': 'Bearer ${AuthService.getToken()}',
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode != 200) {
        LogService.logError('Error: ${response.body}');
        return;
      }

      List<dynamic> data = json.decode(response.body);
      bubbles = [];
      timeBubbleTexts.clear();

      for (var chat in data) {
        bool isSentByMe = chat['senderId'] == AuthService.getProfileId();

        // Determine message type based on mediaUrl or mediaType
        MessageType messageType;
        if (chat['mediaUrl'] != null && chat['mediaUrl'] != '') {
          if (chat['mediaUrl'].endsWith('.mp4')) {
            messageType = MessageType.image;
          } else if (chat['mediaUrl'].endsWith('.webp') ||
              chat['mediaUrl'].endsWith('.jpg') ||
              chat['mediaUrl'].endsWith('.png')) {
            messageType = MessageType.image;
          } else {
            messageType = MessageType.audio;
          }
        } else {
          messageType = MessageType.text;
        }

        // Format and group messages by time
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
          ChatBubbleComponent(
            message: chat['mediaUrl'] ?? chat['content'],
            isSentByMe: isSentByMe,
            messageType: messageType,
            comment: chat,
          ),
        );
      }

      setState(() {
        messageWidgets =
            bubbles.reversed.toList(); // Reverse messages for latest-first view
      });

      box.put(localStorageKey, data); // Cache the latest messages
    } catch (e) {
      LogService.logError('Error fetching messages: $e');
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
    LogService.logInfo('connecting to stomp');
    try {
      await _connectToStomp(
        socketChannel,
        _onConnectCallback,
      );
    } catch (e) {
      LogService.logError('Error connecting to stomp');
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
    _fetchChatMessages();
  }

  @override
  void initState() {
    super.initState();
    _stompController();
    _fetchUserDetails();
    _fetchChatMessages();

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

  // Define sendingMessages with dynamic value types to store both bool and String
  Map<String, Map<String, dynamic>> sendingMessages = {};

// Your sendMessage function
  Future<void> _sendMessage(
      {String? retryMessageId, String? messageContent}) async {
    String token = AuthService.getToken();
    String messageId =
        retryMessageId ?? generateMessageId(); // Use retry ID if retrying
    String message = messageContent ??
        messageController.text; // Use passed content if retrying

    // Determine the message type
    MessageType messageType;
    if (pickedFile != null) {
      messageType = MessageType.image;
    } else if (audioData != null) {
      messageType = MessageType.audio;
    } else {
      messageType = MessageType.text;
    }

    setState(() {
      // Track message with both isSending and hasFailed flags
      sendingMessages[messageId] = {
        'isSending': true,
        'hasFailed': false,
        'content': message, 
      };
      messageWidgets.insert(
        0,
        ChatBubbleComponent(
          message: message,
          isSentByMe: true,
          messageType: messageType,
          comment: {'duration': 0},
          isSending: sendingMessages[messageId]?['isSending'] ?? false,
          hasFailed: sendingMessages[messageId]?['hasFailed'] ?? false,
          onRetry: () => _retryMessage(messageId), 
        ),
      );
    });

    try {
      messageController.clear();

      var request = http.MultipartRequest(
        'POST',
        Uri.https(LarosaLinks.nakedBaseUrl, '/message/send'),
      )
        ..headers.addAll({
          'Authorization': 'Bearer $token',
          "Access-Control-Allow-Origin": "*",
        })
        ..fields['recipientId'] = widget.profileId.toString()
        ..fields['content'] = message;

      if (audioData != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'mediaFile',
          audioData!,
          filename: 'recording.aac',
          contentType: MediaType('audio', 'aac'),
        ));
      }

      if (pickedFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'mediaFile',
          pickedFile!.path,
        ));
      }

      final response = await request.send();

      if (response.statusCode == 200) {
        // Update message status to sent successfully
        setState(() {
          sendingMessages[messageId] = {'isSending': false, 'hasFailed': false};
          _fetchChatMessages(); // Reload chat to fetch the new message state


          // Clear the input file and reset video controller
        pickedFile = null;
        audioData = null;
        _videoController?.dispose();
        _videoController = null;

        });
      } else {
        throw Exception('Failed to send message');
      }
    } catch (e) {
      LogService.logError('Error sending message: $e');
      setState(() {
        // Set hasFailed to true in case of failure
        sendingMessages[messageId] = {
          'isSending': false,
          'hasFailed': true,
          'content': message, // Keep content for retries
        };
        // Re-render the message with failed state
        messageWidgets[0] = ChatBubbleComponent(
          message: message,
          isSentByMe: true,
          messageType: messageType,
          comment: {'duration': 0},
          isSending: sendingMessages[messageId]?['isSending'] ?? false,
          hasFailed: sendingMessages[messageId]?['hasFailed'] ?? true,
          onRetry: () => _retryMessage(messageId), // Retry callback
        );
      });
    }
  }

// Retry function with message content retrieval
  void _retryMessage(String messageId) {
    String? originalMessageContent = sendingMessages[messageId]
        ?['content']; // Get the original message content

    setState(() {
      sendingMessages[messageId] = {
        'isSending': true,
        'hasFailed': false,
        'content': originalMessageContent
      };
      _sendMessage(
          retryMessageId: messageId,
          messageContent:
              originalMessageContent); // Retry with original content
    });
  }

// Initialize FlutterSoundRecorder and FlutterSoundPlayer for recording and playback
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool isRecording = false;
  bool isPlaying = false;
  Uint8List? audioData; // Use Uint8List for audioData

  File? pickedFile; // Holds the selected image or video file
  VideoPlayerController? _videoController;

  Future<void> startRecording() async {
    // Check and request microphone permission
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      LogService.logError('Microphone permission not granted');
      return;
    }

    if (pickedFile != null) {
      setState(() {
        pickedFile = null;
        _videoController?.dispose();
        _videoController = null;
      });
    }

    try {
      await _recorder.openRecorder();
      final Directory tempDir = await getTemporaryDirectory();
      final String path = '${tempDir.path}/temp.aac';

      await _recorder.startRecorder(
        toFile: path,
      );

      setState(() => isRecording = true);
    } catch (e) {
      LogService.logError('Error starting recording: $e');
    }
  }

  Future<void> stopRecording() async {
    try {
      final String? path = await _recorder.stopRecorder();
      if (path != null) {
        File audioFile = File(path);
        audioData = await audioFile.readAsBytes(); // Convert audio to Uint8List
      }

      await _recorder.closeRecorder(); // Close the recorder

      setState(() {
        isRecording = false;
      });
    } catch (e) {
      LogService.logError('Error stopping recording: $e');
    }
  }

  Future<void> playAudio() async {
    if (audioData != null && !isPlaying) {
      await _player.openPlayer();
      await _player.startPlayer(
        fromDataBuffer: audioData,
        whenFinished: () {
          setState(() => isPlaying = false);
          _player.closePlayer();
        },
      );
      setState(() => isPlaying = true);
    } else if (isPlaying) {
      await _player.stopPlayer();
      setState(() => isPlaying = false);
    }
  }

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.media,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);

      setState(() {
        pickedFile = file;
        audioData = null; // Remove audio if a file is picked

        if (file.path.endsWith('.mp4')) {
          _videoController = VideoPlayerController.file(file)
            ..initialize().then((_) {
              setState(() {}); // Refresh to show video preview
              _videoController?.setLooping(true);
              _videoController?.play();
            });
        } else {
          _videoController
              ?.dispose(); // Dispose of any existing video controller
          _videoController = null;
        }
      });
    }
  }

  Widget _chatInputs() {
    return Column(
      children: [
        if (audioData != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: LarosaColors.blueGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Iconsax.music,
                  color: Colors.white,
                ),
                const Gap(8),
                const Expanded(
                  child: Text(
                    'Voice Note',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isPlaying ? Iconsax.pause : Iconsax.play,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    playAudio();
                  },
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      audioData = null;
                    });
                  },
                ),
              ],
            ),
          )
        else if (pickedFile != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: LarosaColors.blueGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _previewMedia(),
                IconButton(
                  icon: const Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      pickedFile = null;
                      _videoController?.dispose();
                      _videoController = null;
                    });
                  },
                ),
              ],
            ),
          ),
        const SizedBox(
          height: 10,
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LarosaColors.blueGradient,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(5),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      prefixIcon: isRecording
                          ? AvatarGlow(
                              glowRadiusFactor:
                                  1.0, // Adjust for desired glow effect
                              glowColor: Colors.white,
                              child: IconButton(
                                onPressed: () async {
                                  if (!isRecording) {
                                    await startRecording();
                                  } else {
                                    await stopRecording();
                                  }
                                },
                                icon: const Icon(
                                  Iconsax.stop,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : IconButton(
                              onPressed: () async {
                                if (!isRecording) {
                                  await startRecording();
                                } else {
                                  await stopRecording();
                                }
                              },
                              icon: const Icon(
                                Iconsax.microphone,
                                color: Colors.white,
                              ),
                            ),
                      suffixIcon: IconButton(
                        onPressed: pickFile, // Open file picker when clicked
                        icon: const Icon(
                          Iconsax.camera,
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
                      hintStyle: const TextStyle(
                        color: Colors.white,
                        fontStyle: FontStyle.italic,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
              const Gap(8),
              GestureDetector(
                // onTap: () async {
                //   if (messageController.text.isNotEmpty) {
                //     await _sendMessage();
                //     messageController.clear();
                //   }
                // },
                onTap: () async {
                  // Unfocus the TextField to ensure the button tap registers
                  FocusScope.of(context).unfocus();

                  HelperFunctions.larosaLogger('Send button pressed');

                  if (messageController.text.isNotEmpty ||
                      pickedFile != null ||
                      audioData != null) {
                    HelperFunctions.larosaLogger(
                        'Message content: "${messageController.text}"');

                    // Send the message asynchronously
                    await _sendMessage();

                    // Clear the input field after appending the message
                    messageController.clear();

                    HelperFunctions.larosaLogger(
                        'Message, media file, or audio data sent');
                  } else {
                    HelperFunctions.larosaLogger(
                        'Nothing to send: message, media file, and audio data are all empty');
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
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

Widget _previewMedia() {
  if (pickedFile == null) return Container();

  if (_videoController != null && pickedFile!.path.endsWith('.mp4')) {
    if (!_videoController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7, // Adjust height as needed
      child: AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: VideoPlayer(_videoController!),
      ),
    );
  }

  return SizedBox(
    height: MediaQuery.of(context).size.height * 0.7,
    child: Image.file(
      pickedFile!,
      fit: BoxFit.cover,
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchChatMessages,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          leading: IconButton(
            onPressed: () {
              context.pop();
            },
            icon: const Icon(CupertinoIcons.back),
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
                Row(
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
                            style: const TextStyle(fontSize: 16),
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
                child: ListView.builder(
                  reverse: true,
                  itemCount: messageWidgets.length,
                  itemBuilder: (context, index) {
                    return messageWidgets[index];
                  },
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
