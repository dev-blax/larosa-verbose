import 'dart:convert';
import 'dart:io';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http_parser/http_parser.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:larosa_block/Services/encryption_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../Services/auth_service.dart';
import '../../Services/dio_service.dart';
import '../../Services/log_service.dart';
import '../../Utils/colors.dart';
import '../../Utils/helpers.dart';
import '../../Utils/links.dart';
import 'Components/chat_bubble.dart';
import 'Components/time_bubble.dart';
import 'providers/conversation_controller.dart';

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
  final DioService _dioService = DioService();
  final TextEditingController messageController = TextEditingController();
  String currentUserUid = '';
  final String socketChannel = '${LarosaLinks.baseurl}/ws';
  late StompClient _stompClient;
  Map<String, dynamic>? profile;
  String fullname = '';
  bool isVerified = false;
  String profilePicture = '';
  bool isLoadingProfile = true;
  List<Map<String, dynamic>> messages = [];
  List<Widget> messageWidgets = [];
  List<String> timeBubbleTexts = [];
  String profileType = 'PERSONAL';
  final FlutterSoundPlayer _soundPlayer = FlutterSoundPlayer();
  late StompClient stompClient;
  bool connectedToSocket = false;
  bool _isPlaying = false;

  Future<void> _socketConnection() async {
    LogService.logFatal('connecting to socket');
    const String wsUrl = '${LarosaLinks.baseurl}/ws';
    final token = AuthService.getToken();

    stompClient = StompClient(
      config: StompConfig.sockJS(
        url: wsUrl,
        stompConnectHeaders: {
          'Authorization': 'Bearer $token'
        },
        onConnect: _onConnect,
        onWebSocketError: (dynamic error) =>
            LogService.logError('WebSocket error: $error'),
        onStompError: (StompFrame frame) =>
            LogService.logWarning('Stomp error: ${frame.headers}'),
        onDisconnect: (StompFrame frame) {
          LogService.logWarning('Disconnected from WebSocket');
          setState(() => connectedToSocket = false);
        },
      ),
    );

    stompClient.activate();
  }

  void _onConnect(StompFrame frame) {
    if (!mounted) return;

    setState(() => connectedToSocket = true);
    LogService.logInfo(
      'Connected to WebSocket server',
    );

    stompClient.subscribe(
      destination: '/user/${AuthService.getProfileId()}/queue/messages',
      callback: (StompFrame message) {
        if (!mounted) return;

        if (message.body != null) {
          try {
            final data = json.decode(message.body!) as Map<String, dynamic>;

            _playMagicTone();

            // Add the new message to the list
            _addNewMessage({
              'id': data['id'] ?? 0,
              'senderId': data['senderId'] ?? 0,
              'recipientId': data['recipientId'] ?? 0,
              'content': data['content'] ?? '',
              'mediaUrl': data['mediaUrl'],
              'messageType': data['messageType'] ?? 'TEXT',
              'status': data['status'] ?? 'SENT',
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            });

          } catch (e) {
            LogService.logError('Error parsing message: $e');
          }
        }
      },
    );
  }

  // Generate a unique ID for each message
  String generateMessageId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  Future<void> asyncInit() async {
    await _fetchChatMessages();
    await _fetchUserDetails();
    await _socketConnection();
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
    LogService.logFatal('Fetching user details...');
    String personalLink = '${LarosaLinks.baseurl}/personal/visit';
    String brandLink = '${LarosaLinks.baseurl}/brand/visit';

    try {
      final String url = profileType == 'PERSONAL' ? personalLink : brandLink;


      final response = await _dioService.dio.post(
        url,
        data: jsonEncode({
          'ownerId': widget.profileId,
        }),
      );

      if (response.statusCode != 200) {
        LogService.logError('Non 200: ${response.data}');
        return;
      }

      final Map<String, dynamic> data = response.data;

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
    try {
      LogService.logFatal('Fetching chat messages...');
      final response = await _dioService.dio.get(
        '${LarosaLinks.baseurl}/messages/${AuthService.getProfileId()}/${widget.profileId}',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['messages'];
        final encryptionService = EncryptionService();
        final conversationController = ConversationController();

        // get my private key and password
        // final privateKey = await encryptionService.getEncryptedPrivateKey();
        // final password = await encryptionService.getE2EPassword();

        // Only proceed with E2E decryption if we have both private key and password
        Uint8List? decryptedPrivateKey;
        // if (privateKey != null && password != null) {
        //   try {
        //     decryptedPrivateKey = await encryptionService.decryptPrivateKey(privateKey, password);
        //     LogService.logInfo('Private key decrypted successfully');
        //   } catch (e) {
        //     LogService.logError('Failed to decrypt private key: $e');
        //   }
        // }
        
        final List<Map<String, dynamic>> messagesList = await Future.wait(
          data.map((message) async {
            LogService.logFatal('Processing message: $message');
            String content = message['content'] ?? '';
            final symmetricKey = message['symmetricKey'];
            final status = message['status'] ?? '';
            final messageId = message['id'] ?? 0;
              
            // Queue message for status update if not read
            if (status != 'READ' && messageId > 0 && message['senderId'] == widget.profileId) {
              LogService.logFatal('Queueing message for status update: $messageId');
              conversationController.queueMessageForStatusUpdate(messageId);
            }
            
            if (content.isNotEmpty && symmetricKey != null && symmetricKey.isNotEmpty) {
              try {
                // Convert base64 key to Uint8List
                final keyBytes = base64Decode(symmetricKey);
                // Decrypt the content
                content = await encryptionService.decrypt(content, keyBytes);
                LogService.logInfo('Message decrypted successfully');
              } catch (e) {
                LogService.logError('Failed to decrypt message: $e');
                // Keep original content if decryption fails
              }
            }

            // if e2e is true
            if (message['endToEndEncrypted'] && decryptedPrivateKey != null) {
              try {
                content = await encryptionService.decrypt(content, decryptedPrivateKey);
                LogService.logInfo('E2E message decrypted successfully');
              } catch (e) {
                LogService.logError('Failed to decrypt E2E message: $e');
              }
            }

            return {
              'id': messageId,
              'senderId': message['senderId'] ?? 0,
              'recipientId': message['recipientId'] ?? 0,
              'content': content,
              'mediaUrl': message['mediaUrl'],
              'messageType': message['messageType'] ?? 'TEXT',
              'status': status,
              'timestamp': message['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
              'symmetricKey': symmetricKey ?? '',
              'endToEndEncrypted': message['endToEndEncrypted'] ?? false,
            };
          }),
        );

        // Handle encryption key generation outside setState
        if (messagesList.isEmpty) {
          await encryptionService.generateAndStoreKey();
          LogService.logFatal('Generated symmetric key');
          final key = await encryptionService.getStoredKey();
          LogService.logTrace('Key: $key');
        }

        setState(() {
          messages = messagesList;
          profileType = response.data['profileType'] ?? 'PERSONAL';
          _buildMessageWidgets();
        });
      }
    } catch (e) {
      LogService.logError('Error fetching chat messages: $e');
    }
  }

  void _addNewMessage(Map<String, dynamic> messageData) {
    LogService.logFatal('Adding new message: $messageData');
    setState(() {
      // insert at the end of the list
      messages.add(messageData);
      _buildMessageWidgets();
    });
  }

  void _buildMessageWidgets() {
    LogService.logFatal('Building message widgets with ${messages.length} messages');
    List<Widget> bubbles = [];
    List<String> timeBubbleTexts = [];

    for (var chat in messages) {
      bool isSentByMe = chat['senderId'] == AuthService.getProfileId();

      MessageType messageType;
      if (chat['mediaUrl'] != null && chat['mediaUrl'] != '') {
        if (chat['mediaUrl'].endsWith('.mp4')) {
          messageType = MessageType.video;
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

      String timeBubbleText = formatTime(chat['duration'] ?? 0);
      if (!timeBubbleTexts.contains(timeBubbleText)) {
        timeBubbleTexts.add(timeBubbleText);
        bubbles.add(
          TimeBubble(
            duration: timeBubbleText,
          ),
        );
      }

      LogService.logTrace('chat: ${chat}');

      bubbles.add(
        ChatBubbleComponent(
          message: chat['mediaUrl'] ?? chat['content'],
          isSentByMe: isSentByMe,
          messageType: messageType,
          comment: chat,
          status: chat['status'] == 'SENT'
              ? MessageStatus.sent
              : chat['status'] == 'DELIVERED'
                  ? MessageStatus.delivered
                  : chat['status'] == 'READ'
                      ? MessageStatus.read
                      : MessageStatus.pending,
        ),
      );
    }

    setState(() {
      messageWidgets = bubbles;
      messageWidgets = messageWidgets.reversed.toList();
    });
  }

  Future<void> _playMagicTone() async {
    try {
      if (!_soundPlayer.isOpen()) {
        await _soundPlayer.openPlayer();
      }

      // Load the .wav file from assets
      final ByteData data = await rootBundle.load('assets/music/magic_tone.mp3');
      final Uint8List bytes = data.buffer.asUint8List();

      // Write to a temporary file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/magic_tone.mp3');
      await tempFile.writeAsBytes(bytes);

      // Play the file
      await _soundPlayer.startPlayer(
        fromURI: tempFile.path,
        codec: Codec.pcm16WAV,
        whenFinished: () {
          setState(() {
            _isPlaying = false;
          });
        },
      );

      setState(() {
        _isPlaying = true;
      });
    } catch (e) {
      LogService.logError('Error playing magic tone: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _initPlayer();
    asyncInit();
    messageController.addListener(_onMessageChanged);
  }

  Future<void> _initPlayer() async {
    await _soundPlayer.openPlayer();
  }

  @override
  void dispose() {
    messageController.removeListener(_onMessageChanged);
    messageController.dispose();
    if (_soundPlayer.isOpen()) {
      _soundPlayer.closePlayer();
    }
    _stompClient.deactivate();
    super.dispose();
  }

  void _onMessageChanged() {
    setState(() {});
  }

  Map<String, Map<String, dynamic>> sendingMessages = {};

  Future<void> _sendMessage(
      {String? retryMessageId, String? messageContent}) async {
    String messageId = retryMessageId ?? generateMessageId();
    String message = messageContent ?? messageController.text;

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
      sendingMessages[messageId] = {
        'isSending': true,
        'hasFailed': false,
        'content': message,
      };

      // chat bubble props
      LogService.logFatal('adding new message');
      LogService.logFatal('message: $message');
      LogService.logFatal('messageType: $messageType');

      messageWidgets.insert(
        0,
        ChatBubbleComponent(
          message: message,
          isSentByMe: true,
          messageType: messageType,
          comment: {'duration': 0, 'timestamp': DateTime.now().millisecondsSinceEpoch},
          isSending: true,
          hasFailed: false,
          onRetry: () => _retryMessage(messageId),
          status: MessageStatus.pending,
        ),
      );
    });

    // Clear input immediately
    messageController.clear();

    LogService.logInfo('my profile Id : ${AuthService.getProfileId()}');
    LogService.logInfo('recipient profile Id : ${widget.profileId}');

    // check if user enable e2e encryption
    final encryptionService = EncryptionService();
    final isE2EEnabled = await encryptionService.isE2EEnabled();
    String? receiversPublicKey;
    String? sendersPublicKey;
    if (isE2EEnabled) {
      LogService.logInfo('E2E enabled');

     // fetch recepient user public key
     final conversationController = ConversationController();
     receiversPublicKey = await conversationController.fetchUserPublicKey(widget.profileId);
     sendersPublicKey = await encryptionService.getPublicKey();
     if (receiversPublicKey == null || sendersPublicKey == null) {
       LogService.logError('Failed to fetch public key');
       return;
     }

     LogService.logInfo('Receivers public key: $receiversPublicKey');
     LogService.logInfo('Senders public key: $sendersPublicKey');

    } else {
      LogService.logInfo('E2E not enabled');
    }

    // Get or generate symmetric key
    String? symmetricKeyBase64 = await EncryptionService().getStoredKeyBase64();
    if (symmetricKeyBase64 == null) {
      await EncryptionService().generateAndStoreKey();
      symmetricKeyBase64 = await EncryptionService().getStoredKeyBase64();
    }

    if (symmetricKeyBase64 == null) {
      LogService.logError('Failed to generate symmetric key');
      return;
    }

    LogService.logTrace('symmetricKeyBase64: $symmetricKeyBase64');

    // Get the key as Uint8List for encryption
    final key = await encryptionService.getStoredKey();
    if (key == null) {
      LogService.logError('Failed to retrieve symmetric key for encryption');
      return;
    }

    LogService.logTrace('key: $key');

    // Encrypt the message
    String encryptedMessage;
    try {
      encryptedMessage = await encryptionService.encrypt(message, key);
      LogService.logInfo('Message encrypted successfully');
    } catch (e) {
      LogService.logError('Failed to encrypt message: $e');
      return;
    }

    LogService.logTrace('encryptedMessage: $encryptedMessage');

    // is e2e enabled encrypt symmetric key with public key
    String? receiversEncryptedSymmetricKey;
    String? sendersEncryptedSymmetricKey;
    if (isE2EEnabled && receiversPublicKey != null && sendersPublicKey != null) {
      try {
        receiversEncryptedSymmetricKey = await encryptionService.encryptWithPublicKey(
          symmetricKeyBase64,
          receiversPublicKey,
        );
        LogService.logInfo('Symmetric key encrypted successfully');
      } catch (e) {
        LogService.logError('Failed to encrypt symmetric key: $e');
        return;
      }

      try {
        sendersEncryptedSymmetricKey = await encryptionService.encryptWithPublicKey(
          symmetricKeyBase64,
          sendersPublicKey,
        );
        LogService.logInfo('Senders symmetric key encrypted successfully');
      } catch (e) {
        LogService.logError('Failed to encrypt senders symmetric key: $e');
        return;
      }
    }

    // Prepare form data with encrypted message
    final formData = FormData.fromMap({
      'recipientId': widget.profileId.toString(),
      'content': encryptedMessage,
      'symmetricKey': receiversEncryptedSymmetricKey ?? symmetricKeyBase64,
      'endToEndEncrypted': isE2EEnabled,
    });

    if (isE2EEnabled && receiversPublicKey != null) {
      formData.fields.add(
        MapEntry(
          'symmetricKeyForSender',
          sendersEncryptedSymmetricKey ?? symmetricKeyBase64,
        ),
      );
    }

    // Add media file if present
    if (audioData != null) {
      formData.files.add(
        MapEntry(
          'mediaFile',
          MultipartFile.fromBytes(
            audioData!,
            filename: 'recording.aac',
            contentType: MediaType('audio', 'aac'),
          ),
        ),
      );
    } else if (pickedFile != null) {
      formData.files.add(
        MapEntry(
          'mediaFile',
          await MultipartFile.fromFile(pickedFile!.path),
        ),
      );
    }

    setState(() {
      pickedFile = null;
      audioData = null;
      _videoController?.dispose();
      _videoController = null;
    });

    _dioService.dio
        .post('${LarosaLinks.baseurl}/message/send', data: formData)
        .then((response) {
      if (response.statusCode == 200) {
        setState(() {
          sendingMessages[messageId] = {'isSending': false, 'hasFailed': false};
          _fetchChatMessages();

          pickedFile = null;
          audioData = null;
          _videoController?.dispose();
          _videoController = null;
        });
      }
    }).catchError((error) {
      LogService.logError('Error sending message: $error');
      setState(() {
        sendingMessages[messageId] = {
          'isSending': false,
          'hasFailed': true,
          'content': message,
        };
        messageWidgets[0] = ChatBubbleComponent(
          message: message,
          isSentByMe: true,
          messageType: messageType,
          comment: {'duration': 0},
          isSending: false,
          hasFailed: true,
          onRetry: () => _retryMessage(messageId),
          status: MessageStatus.delivered,
        );
      });
    });
  }

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

  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool isRecording = false;
  bool isPlaying = false;
  Uint8List? audioData;

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
                              glowRadiusFactor: 1.0,
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
                onTap: () async {
                  FocusScope.of(context).unfocus();

                  HelperFunctions.larosaLogger('Send button pressed');

                  if (messageController.text.isNotEmpty ||
                      pickedFile != null ||
                      audioData != null) {
                    HelperFunctions.larosaLogger(
                      'Message content: "${messageController.text}"',
                    );

                    _sendMessage();

                    messageController.clear();

                    
                  } else {
                    HelperFunctions.larosaLogger(
                      'Nothing to send: message, media file, and audio data are all empty',
                    );
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
        height: MediaQuery.of(context).size.height * 0.7,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          child: AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          ),
        ),
      );
    }

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: AspectRatio(
          aspectRatio: 1,
          child: Image.file(
            pickedFile!,
            fit: BoxFit.cover,
          ),
        ),
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
