import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/svg.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:larosa_block/Features/Feeds/Components/content_type.dart';
import 'package:larosa_block/Features/Feeds/Controllers/content_controller.dart';
import 'package:larosa_block/Features/Feeds/image_post_screen.dart';
import 'package:larosa_block/Utils/colors.dart';
import 'package:provider/provider.dart';

class CameraContent extends StatefulWidget {
  const CameraContent({super.key});

  @override
  State<CameraContent> createState() => _CameraContentState();
}

class _CameraContentState extends State<CameraContent> {
  bool isRecording = false;
  bool isFrontCamera = true;
  bool isVideoMode = false;
  double progress = 0.0;
  CameraController? cameraController;
  List<CameraDescription> cameras = [];
  Future<void>? _initializeControllerFuture;
  final ImagePicker _picker = ImagePicker();
  double aspectRatio = 1.0;

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  @override
  void dispose() {
    cameraController?.dispose();
    super.dispose();
  }

  Future<void> pickImageFromGallery() async {
    final contentController = Provider.of<ContentController>(context, listen: false);
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        contentController.addToNewContentMediaStrings(image.path);
         Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ImagePostScreen(),
            settings: RouteSettings(arguments: image.path),
          ),
        );
      }
    } catch (e) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('No image picked')),
      // );
    }
  }

  Future<void> initializeCamera() async {
    try {
      cameras = await availableCameras();
      cameraController = CameraController(
        cameras[0],
        ResolutionPreset.low,
        enableAudio: isVideoMode,
      );
      _initializeControllerFuture = cameraController?.initialize();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print("Error initializing camera: $e");
    }
  }

  Future<void> takePicture() async {
    final contentController = Provider.of<ContentController>(context, listen: false);
    try {
      if (!isRecording && cameraController!.value.isInitialized) {
        final XFile? picture = await cameraController?.takePicture();
        if (picture != null) {
          contentController.addToNewContentMediaStrings(picture.path);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ImagePostScreen(),
              settings: RouteSettings(arguments: picture.path),
            ),
          );
        }
      } else {
        print("Cannot take picture while recording");
      }
    } catch (e) {
      print("Error taking picture: $e");
    }
  }

  Widget buildCameraPreview() {
    return CameraPreview(cameraController!);
  }

  Widget buildToggleCameraButton() {
    return ClipOval(
      child: Container(
        decoration: const BoxDecoration(color: Colors.black45),
        child: IconButton(
          onPressed: () {
            setState(() {
              isFrontCamera = !isFrontCamera;
            });
            initializeCamera();
          },
          icon: SvgPicture.asset(
            'assets/svg_icons/GravityUiArrowsRotateRight.svg',
            colorFilter: const ColorFilter.mode(
              Colors.white,
              BlendMode.srcIn,
            ),
            height: 20,
          ),
        ),
      ),
    );
  }

  Widget buildCaptureButton() {
    return GestureDetector(
      onTap: () async {
        await takePicture();
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 5,
                ),
              ],
            ),
          ),
          if (isRecording)
            CircularProgressIndicator(
              value: progress,
              strokeWidth: 8,
              backgroundColor: Colors.white,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
            ),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isRecording ? Colors.red : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPickImageButton() {
    return ClipOval(
      child: Container(
        decoration: const BoxDecoration(color: Colors.black45),
        child: IconButton(
          onPressed: pickImageFromGallery,
          icon: const Icon(
            Iconsax.gallery,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget buildControlBar() {
    return Positioned(
      bottom: 20,
      left: 0,
      right: 0,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              buildToggleCameraButton(),
              buildCaptureButton(),
              buildPickImageButton(),
            ],
          ),
          const ContentTypeComponent(
            contentType: ContentType.string,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                buildCameraPreview(),
                buildControlBar(),
              ],
            );
          } else {
            return const Center(
              child: SpinKitCircle(
                color: LarosaColors.primary,
              ),
            );
          }
        },
      ),
    );
  }
}
