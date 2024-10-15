import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:larosa_block/Utils/colors.dart';
import 'package:larosa_block/Utils/svg_paths.dart';

enum MessageType {
  text,
  audio,
  image,
}

class ChatBubbleComponent extends HookWidget {
  final String message;
  final bool isSentByMe;
  final MessageType messageType;
  final dynamic comment;

  const ChatBubbleComponent({
    super.key,
    required this.message,
    required this.isSentByMe,
    required this.messageType,
    required this.comment,
  });

  @override
  Widget build(BuildContext context) {
    final audioPlayer = useMemoized(() => AudioPlayer());
    final isPlaying = useState(false);
    final duration = useState<Duration>(Duration.zero);
    final position = useState<Duration>(Duration.zero);

    DateTime messageTime = DateTime.now().subtract(
      Duration(
        seconds: comment['duration'],
      ),
    );

    // useEffect(() {
    //   audioPlayer.setFilePath(message).then((value) {
    //     duration.value = audioPlayer.duration ?? Duration.zero;
    //   });

    //   final positionSubscription = audioPlayer.positionStream.listen((pos) {
    //     position.value = pos;
    //   });

    //   final playerStateSubscription =
    //       audioPlayer.playerStateStream.listen((state) {
    //     if (state.playing != isPlaying.value) {
    //       isPlaying.value = state.playing;
    //     }

    //     if (state.processingState == ProcessingState.completed) {
    //       isPlaying.value = false;
    //       position.value = Duration.zero;
    //       audioPlayer.seek(Duration.zero);
    //     }
    //   });

    //   return () {
    //     positionSubscription.cancel();
    //     playerStateSubscription.cancel();
    //     audioPlayer.dispose();
    //   };
    // }, []);

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
                audioPlayer,
                isPlaying,
                duration,
                position,
              )
            else if (messageType == MessageType.image)
              _buildImageBubble(context),
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
                  Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      SvgPicture.asset(
                        SvgIconsPaths.checkOutlines,
                        colorFilter: const ColorFilter.mode(
                          Colors.grey,
                          BlendMode.srcIn,
                        ),
                        height: 16,
                      ),
                      // Row(
                      //   children: [
                      //     const Gap(5),
                      //     SvgPicture.asset(
                      //       SvgIconsPaths.checkCircle,
                      //       colorFilter: const ColorFilter.mode(
                      //         Colors.blue,
                      //         BlendMode.srcIn,
                      //       ),
                      //       height: 16,
                      //     ),
                      //   ],
                      // ),
                    ],
                  )
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextBubble(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * .7,
      ),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isSentByMe ? const Color(0xffb91d73) : LarosaColors.secondary,
            LarosaColors.primary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: isSentByMe ? Colors.white : LarosaColors.light,
        ),
      ),
    );
  }

  Widget _buildAudioBubble(
      AudioPlayer audioPlayer,
      ValueNotifier<bool> isPlaying,
      ValueNotifier<Duration> duration,
      ValueNotifier<Duration> position) {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 200,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isSentByMe ? const Color(0xffb91d73) : LarosaColors.secondary,
            LarosaColors.primary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                        ? Icons.pause_circle_rounded
                        : Icons.play_circle_rounded,
                  ),
                ),
                Expanded(
                  child: Slider(
                    min: 0,
                    max: duration.value.inMilliseconds.toDouble(),
                    value: position.value.inMilliseconds
                        .clamp(0, duration.value.inMilliseconds.toDouble())
                        .toDouble(),
                    onChanged: (value) {
                      final newPosition = Duration(milliseconds: value.toInt());
                      audioPlayer.seek(newPosition);
                    },
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
    );
  }

  Widget _buildImageBubble(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft:
            isSentByMe ? const Radius.circular(10) : const Radius.circular(0),
        topRight:
            isSentByMe ? const Radius.circular(0) : const Radius.circular(10),
        bottomLeft: const Radius.circular(10),
        bottomRight: const Radius.circular(10),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * .7,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              isSentByMe
                  ? const Color.fromARGB(255, 20, 117, 191)
                  : LarosaColors.secondary,
              LarosaColors.primary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isSentByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Image.asset(
              message,
              fit: BoxFit.cover,
            ),
            if (message.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Sharing a moment with my friend',
                  style: TextStyle(
                    color: isSentByMe ? Colors.white : Colors.black,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
