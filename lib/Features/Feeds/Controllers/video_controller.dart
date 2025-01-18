import 'package:get/get.dart';
import 'package:cached_video_player_plus/cached_video_player_plus.dart';

class VideoController extends GetxController {
  final RxInt currentlyPlayingIndex = (-1).obs; // No video is playing initially
  final Map<int, CachedVideoPlayerPlusController> videoControllers = {};

  void addVideoController(int index, CachedVideoPlayerPlusController controller) {
    videoControllers[index] = controller;
    print('VideoController: Added controller for video at index $index');
  }

  void playVideo(int index) {
    print('VideoController: Request to play video at index $index');

    // Pause the currently playing video if it's different
    if (currentlyPlayingIndex.value != -1 &&
        currentlyPlayingIndex.value != index &&
        videoControllers[currentlyPlayingIndex.value] != null) {
      print('VideoController: Pausing currently playing video at index ${currentlyPlayingIndex.value}');
      videoControllers[currentlyPlayingIndex.value]?.pause();
    }

    // Play the new video if it exists
    if (videoControllers[index] != null) {
      print('VideoController: Playing video at index $index');
      videoControllers[index]?.play();
      currentlyPlayingIndex.value = index;
    } else {
      print('VideoController: No controller found for video at index $index');
    }
  }

  void pauseVideo(int index) {
    print('VideoController: Request to pause video at index $index');

    if (videoControllers[index] != null) {
      print('VideoController: Pausing video at index $index');
      videoControllers[index]?.pause();

      if (currentlyPlayingIndex.value == index) {
        print('VideoController: Resetting currentlyPlayingIndex');
        currentlyPlayingIndex.value = -1; // Reset if the paused video was playing
      }
    } else {
      print('VideoController: No controller found for video at index $index');
    }
  }

  /// New togglePlayPause function
  void togglePlayPause(int index) {
    print('VideoController: Toggling play/pause for video at index $index');

    final controller = videoControllers[index];
    if (controller != null) {
      if (controller.value.isPlaying) {
        pauseVideo(index);
      } else {
        playVideo(index);
      }
    } else {
      print('VideoController: No controller found for video at index $index');
    }
  }

  void disposeAll() {
    print('VideoController: Disposing all video controllers');
    videoControllers.forEach((key, controller) {
      print('VideoController: Disposing controller for video at index $key');
      controller.dispose();
    });
    videoControllers.clear(); // Optional: clear the map after disposing
    print('VideoController: All controllers disposed');
  }
}
