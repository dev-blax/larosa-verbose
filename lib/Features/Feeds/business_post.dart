import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:ionicons/ionicons.dart';
import 'package:larosa_block/Features/Feeds/Controllers/content_controller.dart';
import 'package:larosa_block/Utils/colors.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import '../../Services/auth_service.dart';
import '../../Services/log_service.dart';
import '../../Utils/helpers.dart';
import 'Controllers/business_post_controller.dart';

class BusinessPostScreen extends StatefulWidget {
  const BusinessPostScreen({super.key});

  @override
  State<BusinessPostScreen> createState() => _BusinessPostScreenState();
}

class _BusinessPostScreenState extends State<BusinessPostScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _adultsController = TextEditingController();
  final TextEditingController _childrenController = TextEditingController();

  bool _breakfastIncluded = false;
  int? _selectedReservationTypeId;

  // Separate form keys for each tab to prevent duplication
  final _businessFormKey = GlobalKey<FormState>();
  final _personalFormKey = GlobalKey<FormState>();

  final ImagePicker _picker = ImagePicker();
  bool isCreatingPost = false;
  XFile? _selectedImage;
  late TabController _tabController;

  bool _isBusinessAccount = false;
  int? unitId;

  final String token = AuthService.getToken();

  List<Map<String, dynamic>> reservationTypesList =
      []; // Holds the reservation types data
  bool isLoading = false; // Tracks loading state

  @override
  void initState() {
    super.initState();

    _loadReservationTypes();
    _isBusinessAccount = AuthService.isBusinessAccount();
    _tabController = TabController(
      length: _isBusinessAccount ? 2 : 1,
      vsync: this,
    );
  }

  final List<Map<String, dynamic>> _mediaControllers =
      []; // List to store media info and controllers

  Future<void> _pickMedia() async {
    bool hasImage = _mediaControllers.any((media) =>
        media['filePath'].endsWith(".png") ||
        media['filePath'].endsWith(".jpg") ||
        media['filePath'].endsWith(".jpeg"));

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              LarosaColors.purple.withOpacity(0.8),
              LarosaColors.secondary.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image, color: Colors.white),
              title: const Text(
                'Pick Image',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () async {
                Navigator.pop(context); // Close the bottom sheet
                final XFile? pickedFile = await _picker.pickImage(
                  source: ImageSource.gallery,
                );
                if (pickedFile != null) {
                  final imageData = pickedFile;
                  setState(() {
                    _selectedImage = imageData;
                  });
                  _showCropper();
                }
              },
            ),
            if (!hasImage)
              ListTile(
                leading: const Icon(Icons.videocam, color: Colors.white),
                title: const Text(
                  'Pick Video',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  Navigator.pop(context); // Close the bottom sheet
                  final XFile? pickedFile = await _picker.pickVideo(
                    source: ImageSource.gallery,
                  );
                  if (pickedFile != null) {
                    File videoFile = File(pickedFile.path);
                    final VideoPlayerController controller = VideoPlayerController.file(videoFile);
                    await controller.initialize();

                    final Duration videoDuration = controller.value.duration;

                    if(videoDuration.inMinutes > 5){
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Video duration should not exceed 5 minutes'),
                        ),
                      );
                      return;
                    }
                    _addVideo(pickedFile.path);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

// Method to handle video addition to the post with preview setup
  void _addVideo(String filePath) {
    // Declare and initialize the video controller without using cascade notation initially
    final videoController = VideoPlayerController.file(File(filePath));

    // Initialize the controller and set up looping and autoplay once initialized
    videoController.initialize().then((_) {
      setState(() {}); // Refresh the UI after the video is loaded
      videoController.setLooping(true);
      videoController.play();
    });

    // Add the controller and file path to the media list
    setState(() {
      _mediaControllers.add({
        'filePath': filePath,
        'controller': videoController,
      });
    });

    // Add media path to ContentController
    Provider.of<ContentController>(context, listen: false)
        .addToNewContentMediaStrings(filePath);
  }

  Future<void> _loadReservationTypes() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    const String url =
        'https://burnished-core-439210-f6.uc.r.appspot.com/api/v1/reservation-types';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer $token', // Replace with actual token if needed
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> reservationTypes = jsonDecode(response.body);
        HelperFunctions.larosaLogger(response.body);
        setState(() {
          reservationTypesList = reservationTypes
              .map((type) => type as Map<String, dynamic>)
              .toList();
        });
      } else {
        LogService.logError(
            'Failed to fetch reservation types: ${response.statusCode}');
      }
    } catch (e) {
      LogService.logError('Error fetching reservation types: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    for (var media in _mediaControllers) {
      media['controller']?.dispose();
    }
    _tabController.dispose();
    super.dispose();
  }

  void _removeMedia(String mediaPath) {
    // Find the media in the list
    final mediaIndex =
        _mediaControllers.indexWhere((media) => media['filePath'] == mediaPath);
    if (mediaIndex != -1) {
      // Dispose the associated video controller if it exists
      _mediaControllers[mediaIndex]['controller']?.dispose();

      // Remove the media from the list
      setState(() {
        _mediaControllers.removeAt(mediaIndex);
      });

      // Update the ContentController
      Provider.of<ContentController>(context, listen: false)
          .removeFromNewContentMediaStrings(mediaPath);
    }
  }

  Future<void> _showCropper() async {
    if (_selectedImage == null) return;
    
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: _selectedImage!.path,
      aspectRatio: const CropAspectRatio(ratioX: 3, ratioY: 4),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image - Explore Larosa',
          toolbarColor: LarosaColors.primary,
          toolbarWidgetColor: Colors.white,

          initAspectRatio: CropAspectRatioPreset.ratio3x2,
          lockAspectRatio: false,
          showCropGrid: true,
          dimmedLayerColor: Colors.black54,
          
          activeControlsWidgetColor: LarosaColors.secondary,
        ),
        IOSUiSettings(
          title: 'Crop Image - Explore Larosa',
          aspectRatioLockEnabled: false,
          resetAspectRatioEnabled: false,
        ),
      ],
    );

    if (croppedFile != null) {
      final bytes = await croppedFile.readAsBytes();
      _addCroppedImage(bytes);
    }
  }

  void _addCroppedImage(Uint8List croppedData) {
    final String tempPath =
        '${Directory.systemTemp.path}/${DateTime.now().millisecondsSinceEpoch}.png';
    final File imageFile = File(tempPath)..writeAsBytesSync(croppedData);

    setState(() {
      _mediaControllers.add({
        'filePath': imageFile.path,
        'isVideo': false,
      });
    });

    Provider.of<ContentController>(context, listen: false)
        .addToNewContentMediaStrings(imageFile.path);
  }

  Widget _buildTabContent(bool isBusinessPost) {
    return Consumer<ContentController>(
      builder: (context, contentController, child) {
        return SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
            ),
            child: Form(
              key: isBusinessPost ? _businessFormKey : _personalFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Gap(5),
                  _buildMediaList(contentController),
                  
                  if (isBusinessPost && _isBusinessAccount) ...[
                    // const Gap(20),
                    // _buildCategorySelector(),
                    // const Gap(5),
                    _buildUnitSelector(),
                    const Gap(10),
                    _buildReservationTypeSelector(),
                    const Gap(10),
                    _buildPriceInputField(),
                    const Gap(10),
                    _buildDiscountInputField(),
                    const Gap(10),
                    _buildAdultsInputField(),
                    const Gap(10),
                    _buildChildrenInputField(),
                    const Gap(10),
                    _buildBreakfastToggle(),
                    const Gap(10),
                  ],

                  if (!isBusinessPost)
                  Gap(10),
                   
                  _buildConditionalGap(isBusinessPost),
                  _buildCaptionInputField(isBusinessPost),
                  const Gap(15),
                  _buildGradientPostButton(contentController, isBusinessPost),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildConditionalGap(bool isBusinessPost) {
    return isBusinessPost ? const SizedBox.shrink() : const Gap(15);
  }

  Widget _buildUnitSelector() {
    return Consumer<BusinessCategoryProvider>(
      builder: (context, categoryProvider, child) {
        final units = categoryProvider.units;

        if (units.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Gap(10),
            DropdownButtonFormField<int>(
              decoration: InputDecoration(
                labelText: "Select Unit",
                labelStyle: const TextStyle(color: LarosaColors.mediumGray),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey, width: 3),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: LarosaColors.secondary, width: 3),
                ),
              ),
              value: unitId,
              items: units
                  
                  .map<DropdownMenuItem<int>>((item) {
                return DropdownMenuItem<int>(
                  value: item['id'],
                  child: Text(item['name']),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  //categoryProvider.selectUnit(value);
                  setState(() {
                    unitId = value;
                  });
                }
              },
              isExpanded: true,
              hint: const Text("Choose a Unit"),
              validator: (value) =>
                  value == null ? "Please select a unit" : null,
            ),
          ],
        );
      },
    );
  }

 Widget _buildReservationTypeSelector() {

  if (AuthService.isReservation() == false) {
    return const SizedBox.shrink();
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      DropdownButtonFormField<int>(
        decoration: InputDecoration(
          labelText: "Reservation Type",
          labelStyle: const TextStyle(color: LarosaColors.mediumGray),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: LarosaColors.secondary, width: 2),
          ),
          hintText: 'Choose a Reservation Type',
          hintStyle: TextStyle(
            color: LarosaColors.mediumGray.withOpacity(0.8),
            fontSize: 16,
          ),
        ),
        value: _selectedReservationTypeId,
        items: reservationTypesList.map((type) {
          return DropdownMenuItem<int>(
            value: type['id'],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type['name'] ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: LarosaColors.primary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedReservationTypeId = value;
          });
        },
        validator: (value) =>
            value == null ? 'Please select a reservation type' : null,
        isExpanded: true,
      ),
      if (_selectedReservationTypeId != null)
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Selected Type: ${reservationTypesList.firstWhere((type) => type['id'] == _selectedReservationTypeId)['name']}",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: LarosaColors.primary,
                    ),
                  ),
                  const Gap(5),
                  Text(
                    reservationTypesList
                            .firstWhere((type) =>
                                type['id'] == _selectedReservationTypeId)[
                        'description'] ??
                        '',
                    style: TextStyle(
                      fontSize: 12,
                      color: LarosaColors.mediumGray.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    ],
  );
}

  Widget _buildMediaList(ContentController contentController) {
    bool hasVideo = _mediaControllers.any((media) =>
        media['filePath'].endsWith(".mp4") ||
        media['filePath'].endsWith(".mov") ||
        media['filePath'].endsWith(".avi"));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ..._mediaControllers.map((media) {
            final isVideo = media['filePath'].endsWith(".mp4") ||
                media['filePath'].endsWith(".mov") ||
                media['filePath'].endsWith(".avi");
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0),
              child: Stack(
                children: [
                  isVideo
                      ? FutureBuilder(
                          future: media['controller']?.initialize(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.done) {
                              final aspectRatio =
                                  media['controller'].value.aspectRatio;
                              return SizedBox(
                                width: MediaQuery.of(context).size.width,
                                height: MediaQuery.of(context).size.width /
                                    aspectRatio,
                                child: VideoPlayer(media['controller']),
                              );
                            } else {
                              return Center(
                                  child: CircularProgressIndicator(
                                    color: Theme.of(context).colorScheme.primary,
                                  ));
                            }
                          },
                        )
                      : Image.file(
                          File(media['filePath']),
                          width: MediaQuery.of(context).size.width * 0.7,
                          fit: BoxFit.cover,
                        ),
                  Positioned(
                    top: 8,
                    right: hasVideo ? 25 : 8,
                    child: InkWell(
                      onTap: () => _removeMedia(media['filePath']),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Theme.of(context).colorScheme.background.withOpacity(.7),
                        ),
                        child: Icon(
                          Icons.delete,
                          size: 16,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          if (!hasVideo) // Hide "Add Media" button if a video is selected
            InkWell(
              onTap: _pickMedia,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                height: MediaQuery.of(context).size.width * .7,
                width: MediaQuery.of(context).size.width * .9,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.8),
                      Theme.of(context).colorScheme.secondary.withOpacity(0.5)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Iconsax.gallery_add,
                      size: 28,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                    const Gap(5),
                    Text(
                      'Add Media',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDiscountInputField() {
    return TextFormField(
      controller: _discountController,
      decoration: InputDecoration(
        labelText: 'Discount %',
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        suffixIcon: Icon(CupertinoIcons.percent, color: LarosaColors.primary),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: LarosaColors.secondary, width: 3),
        ),
        hintText: 'Enter Discount Percentage',
        hintStyle: TextStyle(color: LarosaColors.mediumGray.withOpacity(0.8)),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) return "Discount cannot be empty";
        final percentage = double.tryParse(value);
        return (percentage == null || percentage < 0 || percentage > 100)
            ? "Enter a valid percentage (0-100)"
            : null;
      },
    );
  }

  Widget _buildAdultsInputField() {
    if (AuthService.isReservation() == false) {
      return const SizedBox.shrink();
    }
    return TextFormField(
      controller: _adultsController,
      decoration: InputDecoration(
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: LarosaColors.secondary, width: 3),
        ),
        suffixIcon: Icon(CupertinoIcons.person, color: LarosaColors.primary),
        hintText: 'Enter Number of Adults',
        hintStyle: TextStyle(color: LarosaColors.mediumGray.withOpacity(0.8)),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty)
          return "Number of adults is required";
        final adults = int.tryParse(value);
        return (adults == null || adults < 0)
            ? "Enter a valid number of adults"
            : null;
      },
    );
  }

  Widget _buildChildrenInputField() {
    if (AuthService.isReservation() == false) {
      return const SizedBox.shrink();
    }
    return TextFormField(
      controller: _childrenController,
      decoration: InputDecoration(
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: LarosaColors.secondary, width: 3),
        ),
        suffixIcon: Icon(CupertinoIcons.smiley, color: LarosaColors.primary),
        hintText: 'Enter Number of Children',
        hintStyle: TextStyle(color: LarosaColors.mediumGray.withOpacity(0.8)),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty)
          return "Number of children is required";
        final children = int.tryParse(value);
        return (children == null || children < 0)
            ? "Enter a valid number of children"
            : null;
      },
    );
  }

  Widget _buildPriceInputField() {
    return TextFormField(
      controller: _priceController,
      decoration: InputDecoration(
        labelText: 'Price ',
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: LarosaColors.secondary, width: 3),
        ),
        hintText: 'Enter Price',
        hintStyle: TextStyle(color: LarosaColors.mediumGray.withOpacity(0.8)),
        //prefixText: '\$', 
        suffixText: 'Tsh',// Add a currency prefix
        prefixStyle: const TextStyle(
          color: LarosaColors.mediumGray,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      keyboardType: TextInputType.number,
      style: const TextStyle(
        color: LarosaColors.primary,
        fontSize: 16,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Price is required.";
        }
        final parsedPrice = double.tryParse(value.replaceAll(',', ''));
        if (parsedPrice == null || parsedPrice <= 0) {
          return "Please enter a valid price.";
        }
        return null;
      },
    );
  }

  Widget _buildBreakfastToggle() {

    if(AuthService.isReservation() == false){
      return SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Breakfast Included?",
          style: TextStyle(
            color: LarosaColors.mediumGray,
            fontWeight: FontWeight.w500,
          ),
        ),
        Switch(
          value: _breakfastIncluded,
          activeColor: LarosaColors.mediumGray,
          activeTrackColor:
              LarosaColors.mediumGray.withOpacity(0.5),
          inactiveThumbColor: LarosaColors.mediumGray,
          inactiveTrackColor: LarosaColors.mediumGray.withOpacity(0.3),
          onChanged: (value) {
            setState(() {
              _breakfastIncluded = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildCaptionInputField(bool isBusinessPost) {
    return TextFormField(
      controller: _captionController,
      decoration: InputDecoration(
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: LarosaColors.secondary, width: 3),
        ),
        hintText: isBusinessPost
            ? 'Write a Business Caption'
            : 'Write a Personal Caption',
        hintStyle: TextStyle(color: LarosaColors.mediumGray.withOpacity(0.8)),
      ),
      maxLines: 5,
      style: const TextStyle(color: LarosaColors.primary),
      // validator: (value) =>
      //     value == null || value.isEmpty ? "Caption cannot be empty" : null,
    );
  }

  Widget _buildGradientPostButton(
      ContentController contentController, bool isBusinessPost) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: () async {
          final formKey = isBusinessPost ? _businessFormKey : _personalFormKey;
          if (formKey.currentState!.validate()) {
            if (contentController.newContentMediaStrings.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Please add media for your post.')),
              );
              return;
            }

            setState(() {
              isCreatingPost = true;
            });

            double maxHeight = await HelperFunctions.getMaxImageHeight(
              contentController.newContentMediaStrings,
            );

            bool success;

            if (isBusinessPost) {
              success = await contentController.postBusiness(
                _captionController.text,
                double.tryParse(_priceController.text.replaceAll(',', '')) ?? 0,
                maxHeight,
                unitId!,
              );
            } else {
              // Use uploadPost for personal accounts
              LogService.logInfo('uploading post');
              success = await contentController.uploadPost(
                _captionController.text,
                double.tryParse(_priceController.text.replaceAll(',', '')) ?? 0,
              );
            }

            setState(() {
              isCreatingPost = false;
            });

            if (success && context.mounted) {
              context.go('/');
            }
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [LarosaColors.secondary, LarosaColors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.all(Radius.circular(15)),
          ),
          child: Center(
            child: isCreatingPost
                ? CupertinoActivityIndicator(
                    color: Colors.white,
                    radius: 16,
                    animating: true,
                  )
                : const Text(
                    'CONFIRM POST',
                    style: TextStyle(
                      color: LarosaColors.mediumGray,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _isBusinessAccount ? 2 : 1,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              title: Text(
                "Create Post",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              centerTitle: true,
              floating: true,
              pinned: true,
              leading: IconButton(
                icon: const Icon(CupertinoIcons.back),
                color: LarosaColors.mediumGray,
                onPressed: () {
                  context.pop();
                },
              ),
              bottom: TabBar(
                controller: _tabController,
                tabs: _isBusinessAccount
                    ? const [
                        Tab(
                            icon: Icon(Ionicons.briefcase_outline),
                            text: "Business"),
                        Tab(
                            icon: Icon(Ionicons.person_outline),
                            text: "Personal"),
                      ]
                    : const [
                        Tab(
                            icon: Icon(Ionicons.person_outline),
                            text: "Personal"),
                      ],
                labelColor: LarosaColors.primary,
                unselectedLabelColor: Colors.purple.withOpacity(0.8),
                indicatorColor: LarosaColors.primary,
              ),
            ),
            SliverFillRemaining(
              child: TabBarView(
                controller: _tabController,
                children: _isBusinessAccount
                    ? [
                        _buildTabContent(true), // Business Tab
                        _buildTabContent(false), // Personal Tab
                      ]
                    : [
                        _buildTabContent(false), // Personal Tab only
                      ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  
}
