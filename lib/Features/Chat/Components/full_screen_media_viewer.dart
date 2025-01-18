import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../Utils/colors.dart';

class FullScreenMediaViewer extends StatefulWidget {
  final String mediaUrl;

  const FullScreenMediaViewer({
    Key? key,
    required this.mediaUrl,
  }) : super(key: key);

  @override
  _FullScreenMediaViewerState createState() => _FullScreenMediaViewerState();
}

class _FullScreenMediaViewerState extends State<FullScreenMediaViewer> {
  late VideoPlayerController? _videoController;
  bool isVideo = false;
  double _volume = 1.0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    // Determine if media is video based on file extension
    isVideo = widget.mediaUrl.endsWith('.mp4') || widget.mediaUrl.endsWith('.mov');

    if (isVideo) {
      _videoController = VideoPlayerController.network(widget.mediaUrl)
        ..initialize().then((_) {
          setState(() {});
          _videoController?.play();
          _startProgressTimer();
        });
    } else {
      _videoController = null;
    }
  }

  void _startProgressTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted && _videoController != null && _videoController!.value.isInitialized) {
        setState(() {}); // Update the slider position every 500ms
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _videoController?.dispose();
    super.dispose();
  }

  Widget _buildVideoControls() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(
                _videoController!.value.volume > 0 ? Icons.volume_up : Icons.volume_off,
                // color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _volume = _volume > 0 ? 0 : 1;
                  _videoController!.setVolume(_volume);
                });
              },
            ),
            
            Expanded(
  child: SliderTheme(
    data: SliderTheme.of(context).copyWith(
      activeTrackColor: LarosaColors.primary, // Color for the filled part of the slider
      inactiveTrackColor: LarosaColors.secondary, // Color for the unfilled part
      thumbColor: LarosaColors.primary, // Color for the slider thumb (circular control)
      overlayColor: LarosaColors.primary.withOpacity(0.2), // Color when the thumb is pressed
    ),
    child: Slider(
      value: _videoController!.value.position.inSeconds.toDouble(),
      max: _videoController!.value.duration.inSeconds.toDouble(),
      onChanged: (value) {
        _videoController!.seekTo(Duration(seconds: value.toInt()));
      },
    ),
  ),
),


            IconButton(
              icon: Icon(
                _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                // color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _videoController!.value.isPlaying ? _videoController!.pause() : _videoController!.play();
                });
              },
            ),
            
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            '${_formatDuration(_videoController!.value.position)} / ${_formatDuration(_videoController!.value.duration)}',
            // style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration position) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(position.inMinutes.remainder(60));
    final seconds = twoDigits(position.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 1.0,
          maxScale: 5.0,
          child: AspectRatio(
            aspectRatio: isVideo && _videoController?.value.isInitialized == true
                ? _videoController!.value.aspectRatio
                : 1.0, // Use 1.0 for images to keep original aspect ratio
            child: isVideo
                ? _videoController?.value.isInitialized == true
                    ? Column(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _videoController!.value.isPlaying
                                      ? _videoController!.pause()
                                      : _videoController!.play();
                                });
                              },
                              child: VideoPlayer(_videoController!),
                            ),
                          ),
                          _buildVideoControls(),
                        ],
                      )
                    : const Center(child: CircularProgressIndicator())
                : Image.network(
                    widget.mediaUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(child: Icon(Icons.broken_image));
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
