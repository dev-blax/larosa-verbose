import 'dart:io';
import 'dart:typed_data';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';
import 'package:larosa_block/Features/Feeds/Controllers/content_controller.dart';
import 'package:larosa_block/Utils/colors.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../../Services/auth_service.dart';
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

  // Separate form keys for each tab to prevent duplication
  final _businessFormKey = GlobalKey<FormState>();
  final _personalFormKey = GlobalKey<FormState>();

  final CropController _cropController = CropController();
  final ImagePicker _picker = ImagePicker();
  bool isCreatingPost = false;
  Uint8List? _selectedImage;
  late TabController _tabController;

  bool _isBusinessAccount = false;

  @override
  void initState() {
    super.initState();

    // Check if the account is a business account
    _isBusinessAccount = AuthService.isBusinessAccount();

    // Set TabController length based on account type
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
              final imageData = await pickedFile.readAsBytes();
              setState(() {
                _selectedImage = imageData;
              });
              _showCropper();
            }
          },
        ),
        if (!hasImage) // Only show "Pick Video" if no image is selected
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

  @override
  void dispose() {
    // Dispose each video controller when the screen is closed
    for (var media in _mediaControllers) {
      media['controller']?.dispose();
    }
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

  void _showCropper() {
    if (_selectedImage == null) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black, // Set modal background to red
        contentPadding: EdgeInsets.zero,
        insetPadding: const EdgeInsets.symmetric(
            horizontal: 24, vertical: 10), // Adjusts dialog padding
        content: Container(
          height: MediaQuery.of(context).size.height * 0.9,
          width: MediaQuery.of(context).size.width * 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                LarosaColors.primary.withOpacity(0.8),
                LarosaColors.secondary.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Crop(
            image: _selectedImage!,
            controller: _cropController,
            aspectRatio: 3 / 4,
            onCropped: (croppedData) {
              Navigator.pop(context);
              _addCroppedImage(croppedData);
            },
          ),
        ),
        actionsPadding:
            const EdgeInsets.only(bottom: 8), // Reduce space below buttons
        actions: [
          TextButton(
            onPressed: () => _cropController.crop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              backgroundColor: Colors.transparent,
            ).copyWith(
              overlayColor: WidgetStateProperty.all(
                  LarosaColors.secondary.withOpacity(0.2)),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [LarosaColors.primary, LarosaColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              child: const Text(
                'Crop',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [LarosaColors.secondary, LarosaColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              child: const Text(
                'Cancel',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
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

  // Add to ContentController for persistence or other usage
  Provider.of<ContentController>(context, listen: false)
      .addToNewContentMediaStrings(imageFile.path);
}


  Widget _buildTabContent(bool isBusinessPost) {
    return Consumer<ContentController>(
      builder: (context, contentController, child) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Form(
              key: isBusinessPost ? _businessFormKey : _personalFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Gap(5),
                  _buildMediaList(contentController),
                  if (isBusinessPost && _isBusinessAccount) ...[
                    const Gap(20),
                    _buildCategorySelector(),
                    const Gap(5),
                    _buildUnitSelector(),
                    _buildPriceInputField(),
                  ],
                  if (!isBusinessPost)
                    SizedBox(
                      height: MediaQuery.of(context).size.height * .13,
                    ),
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

  Widget _buildCategorySelector() {
    return Consumer<BusinessCategoryProvider>(
      builder: (context, categoryProvider, child) {
        return DropdownButtonFormField<int>(
          decoration: InputDecoration(
            labelText: "Select Business Category",
            labelStyle: const TextStyle(color: LarosaColors.mediumGray),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(width: 3),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: LarosaColors.secondary, width: 3),
            ),
          ),
          items: categoryProvider.businessCategories.map((category) {
            return DropdownMenuItem<int>(
              value: category['id'],
              child: Text(category['name']),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              categoryProvider.selectCategory(value);
            }
          },
          isExpanded: true,
          hint: const Text("Search and Select Category"),
          validator: (value) =>
              value == null ? "Please select a business category" : null,
        );
      },
    );
  }

  Widget _buildUnitSelector() {
    return Consumer<BusinessCategoryProvider>(
      builder: (context, categoryProvider, child) {
        final units = categoryProvider.selectedUnits;

        if (units.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Gap(10),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: "Select Unit",
                labelStyle: const TextStyle(color: LarosaColors.mediumGray),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey, width: 3),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: LarosaColors.secondary, width: 3),
                ),
              ),
              value: categoryProvider.selectedUnit,
              items: units
                  .expand((unit) => unit['items'])
                  .map<DropdownMenuItem<String>>((item) {
                return DropdownMenuItem<String>(
                  value: item['name'],
                  child: Text(item['name']),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  categoryProvider.selectUnit(value);
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
                          if (snapshot.connectionState == ConnectionState.done) {
                            final aspectRatio = media['controller'].value.aspectRatio;
                            return SizedBox(
                              width: MediaQuery.of(context).size.width,
                              height: MediaQuery.of(context).size.width / aspectRatio,
                              child: VideoPlayer(media['controller']),
                            );
                          } else {
                            return const Center(child: CircularProgressIndicator());
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
                        color: Colors.black.withOpacity(.5),
                      ),
                      child: const Icon(Icons.delete, size: 16),
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              height: MediaQuery.of(context).size.width * .7,
              width: MediaQuery.of(context).size.width * .9,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    LarosaColors.purple.withOpacity(0.8),
                    LarosaColors.secondary.withOpacity(0.5)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Iconsax.gallery_add,
                    size: 28,
                    color: LarosaColors.mediumGray,
                  ),
                  Gap(5),
                  Text(
                    'Add Media',
                    style: TextStyle(color: LarosaColors.mediumGray),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}


  Widget _buildPriceInputField() {
    _priceController.addListener(() {
      final text = _priceController.text.replaceAll(',', '');
      if (text.isNotEmpty) {
        final parsedPrice = double.tryParse(text);
        if (parsedPrice != null) {
          final formattedText = formatPrice(parsedPrice);
          _priceController.value = _priceController.value.copyWith(
            text: formattedText,
            selection: TextSelection.collapsed(offset: formattedText.length),
          );
        }
      }
    });

    return Center(
      child: Container(
        width: 200,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              LarosaColors.primary.withOpacity(0.1),
              LarosaColors.secondary.withOpacity(0.1)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextFormField(
          controller: _priceController,
          textAlign: TextAlign.center, // Center-aligns the text
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'Set Business Price',
            hintStyle:
                TextStyle(color: LarosaColors.mediumGray.withOpacity(0.6)),
          ),
          keyboardType: TextInputType.number,
          style: const TextStyle(color: LarosaColors.primary, fontSize: 16),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "Please enter a price";
            }
            final parsedPrice = double.tryParse(value.replaceAll(',', ''));
            return parsedPrice == null ? "Invalid price" : null;
          },
        ),
      ),
    );
  }

  static String formatPrice(double price) {
    final formatter =
        NumberFormat.currency(locale: 'en_US', symbol: '', decimalDigits: 0);
    return formatter.format(price); // Adds commas for thousands
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
      validator: (value) =>
          value == null || value.isEmpty ? "Caption cannot be empty" : null,
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

            // bool success = await contentController.postBusiness(
            //   _captionController.text,
            //   double.tryParse(_priceController.text.replaceAll(',', '')) ?? 0,
            //   maxHeight,
            // );
            
            bool success;

            if (isBusinessPost) {
            // Use postBusiness for business accounts
            success = await contentController.postBusiness(
              _captionController.text,
              double.tryParse(_priceController.text.replaceAll(',', '')) ?? 0,
              maxHeight,
            );
          } else {
            // Use uploadPost for personal accounts
            success = await contentController.uploadPost(
              _captionController.text,
              double.tryParse(_priceController.text.replaceAll(',', '')) ?? 0,
            );
          }

            setState(() {
              isCreatingPost = false;
            });

            if (success && context.mounted) {
              // ignore: use_build_context_synchronously
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
                ? const SpinKitCircle(size: 20, color: Colors.white)
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
              backgroundColor: Colors.black,
              title: const Text(
                "Create Post",
                style: TextStyle(color: LarosaColors.mediumGray),
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
                        Tab(icon: Icon(Ionicons.briefcase_outline), text: "Business"),
                        Tab(icon: Icon(Ionicons.person_outline), text: "Personal"),
                      ]
                    : const [
                        Tab(icon: Icon(Ionicons.person_outline), text: "Personal"),
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
