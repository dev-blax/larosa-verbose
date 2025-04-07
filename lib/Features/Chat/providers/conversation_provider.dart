// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'package:hive/hive.dart';
// import 'package:intl/intl.dart';
// import 'package:larosa_block/Utils/links.dart';
// import 'package:timeago/timeago.dart' as timeago;
// import '../../../Services/auth_service.dart';
// import '../../../Services/dio_service.dart';
// import '../../../Services/log_service.dart';
// import '../Components/chat_bubble.dart';
// import '../conversation.dart';

// class ConversationProvider extends ChangeNotifier {
//   String currentUserUid = '';
//   String fullname = '';
//   Map<String, dynamic>? profile;
//   bool isVerified = false;
//   String profilePicture = '';
//   bool isLoadingProfile = true;
//   List<Widget> messageWidgets = [];
//   List<String> timeBubbleTexts = [];
//   final DioService _dioService = DioService();

//   // getters
//   String get getCurrentUserUid => currentUserUid;
//   String get getFullname => fullname;
//   bool get getIsVerified => isVerified;
//   String get getProfilePicture => profilePicture;
//   bool get getIsLoadingProfile => isLoadingProfile;
//   List<Widget> get getMessageWidgets => messageWidgets;
//   List<String> get getTimeBubbleTexts => timeBubbleTexts;

//   String _formatTime(int duration) {
//     final now = DateTime.now();
//     final dateTime = now.subtract(Duration(seconds: duration));

//     final differenceInDays = now.difference(dateTime).inDays;

//     if (differenceInDays == 0) {
//       return timeago.format(dateTime, locale: 'en_short');
//     } else if (differenceInDays == 1) {
//       return 'Yesterday';
//     } else if (differenceInDays < 7) {
//       return timeago.format(dateTime); // '5 days ago'
//     } else {
//       final dateFormat = DateFormat('EEEE, MMMM d');
//       return dateFormat.format(dateTime); // 'Friday, June 7'
//     }
//   }

//   // Generate a unique ID for each message
//   String _generateMessageId() {
//     return DateTime.now().millisecondsSinceEpoch.toString();
//   }

//   String formatTime(int duration) {
//     final now = DateTime.now();
//     final dateTime = now.subtract(Duration(seconds: duration));

//     final differenceInDays = now.difference(dateTime).inDays;

//     if (differenceInDays == 0) {
//       return timeago.format(dateTime, locale: 'en_short');
//     } else if (differenceInDays == 1) {
//       return 'Yesterday';
//     } else if (differenceInDays < 7) {
//       return timeago.format(dateTime); // '5 days ago'
//     } else {
//       final dateFormat = DateFormat('EEEE, MMMM d');
//       return dateFormat.format(dateTime); // 'Friday, June 7'
//     }
//   }

//   // fetch user details
//   Future<void> fetchUserDetails(bool isBusiness, int profileId) async {
//     String personalLink = '${LarosaLinks.baseurl}/personal/visit';
//     String brandLink = '${LarosaLinks.baseurl}/brand/visit';

//     try {
//       final response = await _dioService.dio.post(
//         isBusiness ? brandLink : personalLink,
//         data: jsonEncode({
//           'ownerId': profileId,
//         }),
//       );

//       if (response.statusCode != 200) {
//         LogService.logError('Non 200: ${response.data}');
//         return;
//       }
//       final Map<String, dynamic> data = response.data;
//       LogService.logInfo('profile data: $data');
//       profile = data;
//       isLoadingProfile = false;
//       fullname = profile!['username'];
//       isVerified = profile!['verificationStatus'] == 'VERIFIED';
//       profilePicture = profile!['profilePicture'] ?? '';

//       notifyListeners();
//     } catch (e) {
//       LogService.logError('Error fetching user details: $e');
//     } finally {
//       LogService.logInfo('Finished fetching user details');
//       // notify listeners
//       notifyListeners();
//     }
//   }

//   // fetch chat messages
//   Future<void> fetchChatMessages(int profileId) async {
//     var box = Hive.box('userBox');
//     String chatId = profileId.toString();
//     String localStorageKey = 'chat_$chatId';

//     List<dynamic>? localMessages = box.get(localStorageKey);
//     List<Widget> bubbles = [];
//     List<String> timeBubbleTexts = [];

//     if (localMessages != null) {
//       for (var chat in localMessages) {
//         bool isSentByMe = chat['senderId'] == AuthService.getProfileId();

//         // Determine the message type based on mediaUrl or mediaType
//         MessageType messageType;
//         if (chat['mediaUrl'] != null && chat['mediaUrl'] != '') {
//           if (chat['mediaUrl'].endsWith('.mp4')) {
//             messageType = MessageType.image;
//           } else if (chat['mediaUrl'].endsWith('.webp') ||
//               chat['mediaUrl'].endsWith('.jpg') ||
//               chat['mediaUrl'].endsWith('.png')) {
//             messageType = MessageType.image;
//           } else {
//             messageType = MessageType.audio;
//           }
//         } else {
//           messageType = MessageType.text;
//         }

//         // Format and group messages by time
//         String timeBubbleText = _formatTime(chat['duration']);
//         if (!timeBubbleTexts.contains(timeBubbleText)) {
//           timeBubbleTexts.add(timeBubbleText);
//           bubbles.add(
//             TimeBubble(
//               duration: timeBubbleText,
//             ),
//           );
//         }

//         bubbles.add(
//           ChatBubbleComponent(
//             message: chat['mediaUrl'] ?? chat['content'],
//             isSentByMe: isSentByMe,
//             messageType: messageType,
//             comment: chat,
//           ),
//         );
//       }

//       messageWidgets = bubbles.reversed.toList();
//       timeBubbleTexts = timeBubbleTexts;

//       notifyListeners();
//     }

//     try {
//       LogService.logInfo('Requesting chats...');

//       final response = await _dioService.dio.get(
//         '${LarosaLinks.baseurl}/messages/${AuthService.getProfileId()}/$chatId',
//       );

//       if (response.statusCode != 200) {
//         LogService.logError('Error: ${response.data}');
//         return;
//       }

//       List<dynamic> data = response.data;
//       bubbles = [];
//       timeBubbleTexts.clear();

//       for (var chat in data) {
//         bool isSentByMe = chat['senderId'] == AuthService.getProfileId();

//         // Determine message type based on mediaUrl or mediaType
//         MessageType messageType;
//         if (chat['mediaUrl'] != null && chat['mediaUrl'] != '') {
//           if (chat['mediaUrl'].endsWith('.mp4')) {
//             messageType = MessageType.image;
//           } else if (chat['mediaUrl'].endsWith('.webp') ||
//               chat['mediaUrl'].endsWith('.jpg') ||
//               chat['mediaUrl'].endsWith('.png')) {
//             messageType = MessageType.image;
//           } else {
//             messageType = MessageType.audio;
//           }
//         } else {
//           messageType = MessageType.text;
//         }

//         // Format and group messages by time
//         String timeBubbleText = _formatTime(chat['duration']);
//         if (!timeBubbleTexts.contains(timeBubbleText)) {
//           timeBubbleTexts.add(timeBubbleText);
//           bubbles.add(
//             TimeBubble(
//               duration: timeBubbleText,
//             ),
//           );
//         }

//         bubbles.add(
//           ChatBubbleComponent(
//             message: chat['mediaUrl'] ?? chat['content'],
//             isSentByMe: isSentByMe,
//             messageType: messageType,
//             comment: chat,
//           ),
//         );
//       }

//       // setState(() {
//       //   messageWidgets =
//       //       bubbles.reversed.toList();
//       // });

//       messageWidgets = bubbles.reversed.toList();
//       timeBubbleTexts = timeBubbleTexts;

//       notifyListeners();

//       box.put(localStorageKey, data);
//     } catch (e) {
//       LogService.logError('Error fetching messages: $e');
//     }
//   }

//   Future<void> sendMessage({
//     String? retryMessageId,
//     String? messageContent,
//   }) async {
//     String token = AuthService.getToken();
//     String messageId = retryMessageId ?? _generateMessageId();
//     String message = messageContent ?? messageController.text;

//     // Determine the message type
//     MessageType messageType;
//     if (pickedFile != null) {
//       messageType = MessageType.image;
//     } else if (audioData != null) {
//       messageType = MessageType.audio;
//     } else {
//       messageType = MessageType.text;
//     }

//     // setState(() {
//     //   sendingMessages[messageId] = {
//     //     'isSending': true,
//     //     'hasFailed': false,
//     //     'content': message,
//     //   };
//     //   messageWidgets.insert(
//     //     0,
//     //     ChatBubbleComponent(
//     //       message: message,
//     //       isSentByMe: true,
//     //       messageType: messageType,
//     //       comment: {'duration': 0},
//     //       isSending: sendingMessages[messageId]?['isSending'] ?? false,
//     //       hasFailed: sendingMessages[messageId]?['hasFailed'] ?? false,
//     //       onRetry: () => _retryMessage(messageId),
//     //     ),
//     //   );
//     // });

//     try {
//       messageController.clear();

//       var request = http.MultipartRequest(
//         'POST',
//         Uri.https(LarosaLinks.nakedBaseUrl, '/message/send'),
//       )
//         ..headers.addAll({
//           'Authorization': 'Bearer $token',
//           "Access-Control-Allow-Origin": "*",
//         })
//         ..fields['recipientId'] = widget.profileId.toString()
//         ..fields['content'] = message;

//       if (audioData != null) {
//         request.files.add(http.MultipartFile.fromBytes(
//           'mediaFile',
//           audioData!,
//           filename: 'recording.aac',
//           contentType: MediaType('audio', 'aac'),
//         ));
//       }

//       if (pickedFile != null) {
//         request.files.add(await http.MultipartFile.fromPath(
//           'mediaFile',
//           pickedFile!.path,
//         ));
//       }

//       final response = await request.send();

//       if (response.statusCode == 200) {
//         // Update message status to sent successfully
//         setState(() {
//           sendingMessages[messageId] = {'isSending': false, 'hasFailed': false};
//           _fetchChatMessages(); // Reload chat to fetch the new message state

//           // Clear the input file and reset video controller
//           pickedFile = null;
//           audioData = null;
//           _videoController?.dispose();
//           _videoController = null;
//         });
//       } else {
//         throw Exception('Failed to send message');
//       }
//     } catch (e) {
//       LogService.logError('Error sending message: $e');
//       setState(() {
//         // Set hasFailed to true in case of failure
//         sendingMessages[messageId] = {
//           'isSending': false,
//           'hasFailed': true,
//           'content': message, // Keep content for retries
//         };
//         // Re-render the message with failed state
//         messageWidgets[0] = ChatBubbleComponent(
//           message: message,
//           isSentByMe: true,
//           messageType: messageType,
//           comment: {'duration': 0},
//           isSending: sendingMessages[messageId]?['isSending'] ?? false,
//           hasFailed: sendingMessages[messageId]?['hasFailed'] ?? true,
//           onRetry: () => _retryMessage(messageId), // Retry callback
//         );
//       });
//     }
//   }
// }
