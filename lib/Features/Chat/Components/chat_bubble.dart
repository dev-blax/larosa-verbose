import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart' as just_audio;
import 'package:shimmer/shimmer.dart';
import 'package:video_player/video_player.dart';

import '../../../Utils/colors.dart';
import 'full_screen_media_viewer.dart';

enum MessageType {
  text,
  audio,
  image,
  video,
}

enum MessageStatus {
  sent,
  failed,
  pending,
  read,
  delivered,
}

class ChatBubbleComponent extends HookWidget {
  final String message;
  final bool isSentByMe;
  final MessageType messageType;
  final dynamic comment;
  final bool isSending;
  final bool hasFailed;
  final VoidCallback? onRetry;
  final MessageStatus status;

  const ChatBubbleComponent({
    super.key,
    required this.message,
    required this.isSentByMe,
    required this.messageType,
    required this.comment,
    this.isSending = false,
    this.hasFailed = false,
    this.onRetry,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final audioPlayer = useMemoized(() => just_audio.AudioPlayer());
    final isPlaying = useState(false);
    final duration = useState<Duration>(Duration.zero);
    final position = useState<Duration>(Duration.zero);

    final videoController = useMemoized(
      () => messageType == MessageType.image && message.endsWith('.mp4')
          ? VideoPlayerController.networkUrl(Uri.parse(message))
          : null,
      [message],
    );

    useEffect(() {
      if (videoController != null) {
        videoController.initialize().then((_) {
          videoController.setLooping(false);
          videoController.addListener(() {
            position.value = videoController.value.position;
            duration.value = videoController.value.duration;
            isPlaying.value = videoController.value.isPlaying;
          });
        });
      }
      return videoController?.dispose;
    }, [videoController]);

    final now = DateTime.now();
    DateTime messageTime =
        now.subtract(Duration(seconds: comment['timestamp']));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Align(
        alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
              isSentByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (messageType == MessageType.text)
              _buildTextBubble(context)
            else if (messageType == MessageType.audio)
              _buildAudioBubble(
                  context, audioPlayer, isPlaying, duration, position)
            else if (messageType == MessageType.image)
              _buildMediaBubble(context, videoController),
            Row(
              mainAxisAlignment:
                  isSentByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                Text(
                  DateFormat.jm().format(messageTime),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (isSentByMe) ...[
                  const Gap(5),
                  if (status == MessageStatus.pending)
                    SvgPicture.asset(
                      'assets/svg_icons/HugeiconsTick01.svg',
                      color: status == MessageStatus.pending
                          ? Colors.grey
                          : Colors.grey,
                      width: 16,
                      height: 16,
                    ),
                  if (status == MessageStatus.failed)
                    SvgPicture.asset(
                      'assets/svg_icons/HugeiconsClose01.svg',
                      color: status == MessageStatus.failed
                          ? Colors.red
                          : Colors.grey,
                      width: 16,
                      height: 16,
                    ),
                  if (status == MessageStatus.sent)
                    SvgPicture.asset(
                      'assets/svg_icons/HugeiconsTick01.svg',
                      color: Colors.grey,
                      width: 16,
                      height: 16,
                    ),
                  if (status == MessageStatus.delivered)
                    SvgPicture.asset(
                      'assets/svg_icons/HugeiconsTickDouble01.svg',
                      color: Colors.grey,
                      width: 16,
                      height: 16,
                    ),
                  if (status == MessageStatus.read)
                    SvgPicture.asset(
                      'assets/svg_icons/HugeiconsTickDouble01.svg',
                      color: LarosaColors.primary,
                      width: 16,
                      height: 16,
                    ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextBubble(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasFailed)
          IconButton(
            icon: const Icon(
              Icons.refresh,
              color: Colors.red,
              size: 16,
            ),
            onPressed: () {
              if (onRetry != null) {
                onRetry!();
              }
            },
          ),
        // Message bubble with optional loading indicator
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * .7,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    isSentByMe
                        ? const Color(0xffb91d73)
                        : CupertinoColors.activeGreen,
                    LarosaColors.primary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                message,
                style: TextStyle(
                  color: isSentByMe ? Colors.white : LarosaColors.light,
                ),
              ),
            ),
            // Loading indicator positioned below the bubble if message is sending
            if (isSending)
              const Padding(
                padding: EdgeInsets.only(left: 4, top: 4),
                child: SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildAudioBubble(
      context,
      just_audio.AudioPlayer audioPlayer,
      ValueNotifier<bool> isPlaying,
      ValueNotifier<Duration> duration,
      ValueNotifier<Duration> position) {
    useEffect(() {
      // Only set the source if it's an audio file
      if (message.endsWith('.mp3') ||
          message.endsWith('.wav') ||
          message.endsWith('.aac')) {
        audioPlayer.setUrl(message).then((_) {
          duration.value = audioPlayer.duration ?? Duration.zero;
        });
      }

      final positionSubscription = audioPlayer.positionStream.listen((pos) {
        position.value = pos;
      });

      final playerStateSubscription =
          audioPlayer.playerStateStream.listen((state) {
        isPlaying.value = state.playing;

        if (state.processingState == just_audio.ProcessingState.completed) {
          isPlaying.value = false;
          position.value = Duration.zero;
          audioPlayer.stop();
          audioPlayer.seek(Duration.zero);
        }
      });

      return () {
        positionSubscription.cancel();
        playerStateSubscription.cancel();
        audioPlayer.dispose();
      };
    }, []);

    return Stack(
      children: [
        Container(
          width: MediaQuery.of(context).size.width * .7,
          decoration: BoxDecoration(
            gradient: LarosaColors.blueGradient,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 3, right: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: isSentByMe
                              ? LarosaColors.secondary
                              : LarosaColors.secondary, // Active track color
                          inactiveTrackColor:
                              Colors.grey[300], // Inactive track color
                          thumbColor: Colors.white,
                          overlayColor: Colors.white.withOpacity(0.2),
                          trackHeight: 4.0,
                        ),
                        child: Slider(
                          min: 0,
                          max: duration.value.inMilliseconds.toDouble(),
                          value: position.value.inMilliseconds
                              .clamp(
                                  0, duration.value.inMilliseconds.toDouble())
                              .toDouble(),
                          onChanged: (value) {
                            // final newPosition =
                            //     Duration(milliseconds: value.toInt());
                            final newPosition = Duration(milliseconds: 1000);
                            audioPlayer.seek(newPosition);
                          },
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        if (isPlaying.value) {
                          await audioPlayer.pause();
                        } else {
                          await audioPlayer.play();
                        }
                      },
                      icon: Icon(
                        isPlaying.value
                            ? CupertinoIcons.pause
                            : CupertinoIcons.play_fill,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Text(
                  "${position.value.inMinutes}:${(position.value.inSeconds % 60).toString().padLeft(2, '0')} / ${duration.value.inMinutes}:${(duration.value.inSeconds % 60).toString().padLeft(2, '0')}",
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isSending) // Show sending indicator if still sending
          const Positioned(
            bottom: 4,
            right: 4,
            child: SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            ),
          ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes);
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Widget _iconButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.all(4.0),
      padding: const EdgeInsets.all(0.0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.0),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: Colors.white,
        ),
        onPressed: onPressed,
        splashRadius: 8,
      ),
    );
  }

  Widget _buildMediaBubble(
      BuildContext context, VideoPlayerController? videoController) {
    if (videoController != null && message.endsWith('.mp4')) {
      // Display video with enhanced UI and controls
      // is darkt mode
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FullScreenMediaViewer(mediaUrl: message),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              // gradient: LarosaColors.blueGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            child: Column(
              children: [
                AspectRatio(
                  aspectRatio: videoController.value.aspectRatio,
                  child: VideoPlayer(videoController),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4.0, vertical: 0.0),
                  child: Column(
                    children: [
                      // Timeline slider with labels
                      Row(
                        children: [
                          Text(
                            _formatDuration(videoController.value.position),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: LarosaColors.secondary,
                                inactiveTrackColor: Colors.grey[300],
                                thumbColor: Colors.white,
                                overlayColor: Colors.white.withOpacity(0.2),
                                trackHeight: 4.0,
                              ),
                              child: Slider(
                                min: 0,
                                max: videoController
                                    .value.duration.inMilliseconds
                                    .toDouble(),
                                value: videoController
                                    .value.position.inMilliseconds
                                    .toDouble(),
                                onChanged: (value) {
                                  videoController.seekTo(
                                    Duration(milliseconds: value.toInt()),
                                  );
                                },
                              ),
                            ),
                          ),
                          Text(
                            _formatDuration(videoController.value.duration),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Volume Control
                          _iconButton(
                            context: context,
                            icon: videoController.value.volume > 0
                                ? Icons.volume_up
                                : Icons.volume_off,
                            onPressed: () {
                              videoController.setVolume(
                                  videoController.value.volume > 0 ? 0 : 1);
                            },
                          ),
                          // Play/Pause Control
                          _iconButton(
                            context: context,
                            icon: videoController.value.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                            onPressed: () {
                              videoController.value.isPlaying
                                  ? videoController.pause()
                                  : videoController.play();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isSending)
                  const Positioned(
                    bottom: 4,
                    right: 4,
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    } else if (message.endsWith('.jpg') ||
        message.endsWith('.jpeg') ||
        message.endsWith('.png') ||
        message.endsWith('.webp')) {
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;
      // Display image with error handling, loading, and sending indicator
      return Stack(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FullScreenMediaViewer(mediaUrl: message),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * .7,
                ),
                child: Image.network(
                  message,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint("Error loading image: $error, URL: $message");
                    return const Column(
                      children: [
                        Icon(Icons.error, color: Colors.red),
                        Text("Image failed to load")
                      ],
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Shimmer.fromColors(
                      baseColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                      highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
                      child: Container(
                        width: MediaQuery.of(context).size.width * .7,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          if (isSending) // Show sending indicator if still sending
            const Positioned(
              bottom: 4,
              right: 4,
              child: SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 1.5),
              ),
            ),
        ],
      );
    }

    // Fallback in case no conditions match
    return Container();
  }
}
