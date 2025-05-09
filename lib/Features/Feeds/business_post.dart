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
import 'package:larosa_block/Features/Feeds/Controllers/second_business_category_provider.dart';
import 'package:larosa_block/Services/dio_service.dart';
import 'package:larosa_block/Types/reservation_types.dart';
import 'package:larosa_block/Utils/colors.dart';
import 'package:larosa_block/Utils/links.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import '../../Services/auth_service.dart';
import '../../Services/log_service.dart';
import '../../Utils/helpers.dart';
import 'Controllers/business_post_controller.dart';
import 'widgets/business_post_shimmer.dart';

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
  final TextEditingController _quantityController = TextEditingController();

  bool _breakfastIncluded = false;
  int? _selectedReservationTypeId;
  bool _pageReady = false;

  final _businessFormKey = GlobalKey<FormState>();
  final _personalFormKey = GlobalKey<FormState>();

  final ImagePicker _picker = ImagePicker();
  bool isCreatingPost = false;
  XFile? _selectedImage;
  late TabController _tabController;

  bool _isBusinessAccount = false;
  int? unitId;

  final String token = AuthService.getToken();

  List<Map<String, dynamic>> reservationTypesList = [];
  bool isLoading = false;
  List<dynamic> _reservationCategories = [];
  List<BusinessCategory> _myBusinessCategories = [];
  List<Subcategory> mySubcategories = [];
  List<dynamic> _myBusinessCategoriesIds = [];

  bool hasReservationCategories = false;

  List<ReservationFacility> _reservationFacilities = [];
  final List<ReservationFacility> _selectedFacilities = [];
  final TextEditingController _facilityFilterController = TextEditingController();
  String _facilityFilterText = '';

  void _asyncInit() async {
    _isBusinessAccount = AuthService.isBusinessAccount();
    await _loadReservationTypes();
    _reservationCategories =
        (await BusinessCategoryProvider.fetchReservationCategoriesIds())
            .map<int>((id) => id as int)
            .toList();

    _myBusinessCategories =
        await SecondBusinessCategoryProvider.fetchMyBrandCategories();
    mySubcategories = _myBusinessCategories
        .expand((category) => category.subcategories)
        .toList();
    _myBusinessCategoriesIds =
        _myBusinessCategories.map((category) => category.id).toList();

    _tabController = TabController(
      length: _isBusinessAccount ? (hasReservationCategories ? 3 : 2) : 1,
      vsync: this,
    );

    setState(() {
      hasReservationCategories = _myBusinessCategoriesIds
          .any((id) => _reservationCategories.contains(id));
      _pageReady = true;
    });

    await _loadReservationFacilities();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SecondBusinessCategoryProvider>(context, listen: false)
          .fetchBrandCategories();
    });
    _asyncInit();
  }

  final List<Map<String, dynamic>> _mediaControllers = [];

  Future<void> _pickMedia() async {
    bool hasImage = _mediaControllers.any((media) =>
        media['filePath'].endsWith(".png") ||
        media['filePath'].endsWith(".jpg") ||
        media['filePath'].endsWith(".jpeg"));

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Choose Media'),
        message: const Text('Select the type of media you want to share'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(context);
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
            child: const Text('Select Image'),
          ),
          if (!hasImage)
            CupertinoActionSheetAction(
              onPressed: () async {
                Navigator.pop(context);
                final XFile? pickedFile = await _picker.pickVideo(
                  source: ImageSource.gallery,
                );
                if (pickedFile != null) {
                  File videoFile = File(pickedFile.path);
                  final VideoPlayerController controller =
                      VideoPlayerController.file(videoFile);
                  await controller.initialize();

                  final Duration videoDuration = controller.value.duration;

                  if (videoDuration.inMinutes > 5) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Video duration should not exceed 5 minutes'),
                      ),
                    );
                    return;
                  }
                  _addVideo(pickedFile.path);
                }
              },
              child: const Text('Select Video'),
            ),
        ],
      ),
    );
  }

  void _addVideo(String filePath) {
    final videoController = VideoPlayerController.file(File(filePath));

    videoController.initialize().then((_) {
      setState(() {});
      videoController.setLooping(true);
      videoController.play();
    });

    setState(() {
      _mediaControllers.add({
        'filePath': filePath,
        'controller': videoController,
      });
    });

    Provider.of<ContentController>(context, listen: false)
        .addToNewContentMediaStrings(filePath);
  }

  Future<void> _loadReservationTypes() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    const String url = '${LarosaLinks.baseurl}/api/v1/reservation-types';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": 'Bearer $token',
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

        LogService.logFatal('Reservation types loaded successfully');
        LogService.logFatal(
            'Reservation types: ${reservationTypesList.length}');
      } else {
        LogService.logError(
          'Failed to fetch reservation types: ${response.statusCode}',
        );
      }
    } catch (e) {
      LogService.logError('Error fetching reservation types: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadReservationFacilities() async {
    const String url =
        'https://burnished-core-439210-f6.uc.r.appspot.com/api/v1/reservation-facilities';
    try {
      var response = await DioService().dio.get(url);

      if (response.statusCode == 200) {
        LogService.logFatal('Reservation facilities loaded successfully');
        print(response.data);
        setState(() {
          _reservationFacilities = (response.data as List<dynamic>)
              .map((item) =>
                  ReservationFacility.fromJson(item as Map<dynamic, dynamic>))
              .toList();
        });
      } else {
        LogService.logError(
          'Failed to fetch reservation facilities ${response.statusCode}',
        );
      }
    } catch (e) {
      LogService.logError('Error loading reservation facilities: $e');
    }
  }

  Widget _buildFacilitySearchField() {
    return TextField(
      controller: _facilityFilterController,
      decoration: InputDecoration(
        labelText: "Search Facilities",
        labelStyle: const TextStyle(color: LarosaColors.mediumGray),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: LarosaColors.secondary, width: 2),
        ),
        hintText: 'Type to search facilities...',
        suffixIcon: _facilityFilterText.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _facilityFilterController.clear();
                  setState(() => _facilityFilterText = '');
                },
              )
            : null,
      ),
      onChanged: (value) => setState(() => _facilityFilterText = value),
    );
  }

  Widget _buildSelectedFacilitiesChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _selectedFacilities
          .map((facility) => Chip(
                label: Text(facility.name),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () =>
                    setState(() => _selectedFacilities.remove(facility)),
              ))
          .toList(),
    );
  }

  Widget _buildFacilitiesList(List<ReservationFacility> filteredFacilities) {
    if (filteredFacilities.isEmpty || _facilityFilterText.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: filteredFacilities.length,
        itemBuilder: (context, index) {
          final facility = filteredFacilities[index];
          return ListTile(
            title: Text(facility.name),
            subtitle: facility.category != null
                ? Text(facility.category!.name)
                : null,
            onTap: () => setState(() {
              _selectedFacilities.add(facility);
              _facilityFilterController.clear();
              _facilityFilterText = '';
            }),
          );
        },
      ),
    );
  }

  Widget _buildReservationFacilities() {
    final filteredFacilities = _reservationFacilities
        .where((facility) =>
            !_selectedFacilities.contains(facility) &&
            facility.name
                .toLowerCase()
                .contains(_facilityFilterText.toLowerCase()))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSelectedFacilitiesChips(),
        const SizedBox(height: 8),
        _buildFacilitiesList(filteredFacilities),
        const SizedBox(height: 8),
        _buildFacilitySearchField(),
        
      ],
    );
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
    final mediaIndex =
        _mediaControllers.indexWhere((media) => media['filePath'] == mediaPath);
    if (mediaIndex != -1) {
      _mediaControllers[mediaIndex]['controller']?.dispose();

      setState(() {
        _mediaControllers.removeAt(mediaIndex);
      });

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

  Widget _buildTabContent(bool isBusinessPost, bool hasReservationCategories) {
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
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: _buildUnitSelector(),
                    ),
                    if(!hasReservationCategories)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: _buildSizeInputField(),
                    ),
                    if(!hasReservationCategories)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: _buildWeightInputField(),
                    ),
                    
                    if (hasReservationCategories)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: _buildReservationTypeSelector(),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: _buildPriceInputField(),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: _buildQuantityField(),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: _buildDiscountInputField(),
                    ),
                    if (hasReservationCategories)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: _buildAdultsInputField(),
                      ),
                    if (hasReservationCategories)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: _buildChildrenInputField(),
                      ),
                    if (hasReservationCategories)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: _buildBreakfastToggle(),
                      ),
                    

                      if (hasReservationCategories)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: _buildParkingToggle(),
                        ),

                        if(hasReservationCategories)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: _buildGymToggle(),
                        ),
                        // pools
                        //   
                      if (hasReservationCategories)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: _buildPoolToggle(),
                        ),
                        // wifi
                        if (hasReservationCategories)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: _buildWifiToggle(),
                        ),

                        if (hasReservationCategories)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: _buildReservationFacilities(),
                      ),
                  ],
                  if (!isBusinessPost) Gap(10),
                  _buildConditionalGap(isBusinessPost),
                  _buildCaptionInputField(isBusinessPost),
                  const Gap(15),
                  _buildGradientPostButton(contentController, isBusinessPost,
                      hasReservationCategories),
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


  // size input
  final TextEditingController _sizeController = TextEditingController();
  Widget _buildSizeInputField() {
    return TextFormField(
      keyboardType: TextInputType.number,
      controller: _sizeController,
      decoration: InputDecoration(
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: LarosaColors.secondary, width: 3),
        ),
        labelText: 'Size',
        labelStyle: TextStyle(color: LarosaColors.mediumGray.withValues(alpha: 0.8)),
      ),
      maxLines: 1,
      style: const TextStyle(color: LarosaColors.primary),
    );
  }

  // weight input
  final TextEditingController _weightController = TextEditingController();
  Widget _buildWeightInputField() {
    return TextFormField(
      keyboardType: TextInputType.number,
      controller: _weightController,
      decoration: InputDecoration(
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: LarosaColors.secondary, width: 3),
        ),
        labelText: 'Weight',
        labelStyle: TextStyle(color: LarosaColors.mediumGray.withValues(alpha: 0.8)),
      ),
      maxLines: 1,
      style: const TextStyle(color: LarosaColors.primary),
    );
  }

  // aspect ratio input
  final TextEditingController _aspectRatioController = TextEditingController();
  Widget _buildAspectRatioInputField() {
    return TextFormField(
      keyboardType: TextInputType.number,
      controller: _aspectRatioController,
      decoration: InputDecoration(
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: LarosaColors.secondary, width: 3),
        ),
        labelText: 'Aspect Ratio',
        labelStyle: TextStyle(color: LarosaColors.mediumGray.withValues(alpha: 0.8)),
      ),
      maxLines: 1,
      style: const TextStyle(color: LarosaColors.primary),
    );
  }

  Widget _buildUnitSelector() {
    return Consumer<SecondBusinessCategoryProvider>(
      builder: (context, secondBusinessCategoryProvider, child) {
        if (secondBusinessCategoryProvider.isLoading) {
          return const Center(child: CupertinoActivityIndicator());
        }

        if (secondBusinessCategoryProvider.error != null) {
          return Center(child: Text(secondBusinessCategoryProvider.error!));
        }

        final categories = secondBusinessCategoryProvider.categories;

        if (categories.isEmpty) {
          return Text('No categories');
        }

        LogService.logDebug(
          'User Category ids: ${categories.map((c) => c.id)}',
        );
        _myBusinessCategoriesIds = categories.map((c) => c.id).toList();

        final allSubcategories =
            categories.expand((category) => category.subcategories).toList();

        // Create a map of subcategories by ID to check for duplicates
        final subcategoriesById = <int, List<Subcategory>>{};
        for (var sub in allSubcategories) {
          subcategoriesById.putIfAbsent(sub.id, () => []).add(sub);
        }

        // Log any duplicates found
        subcategoriesById.forEach((id, subs) {
          if (subs.length > 1) {
            LogService.logWarning(
              'Found duplicate subcategory ID $id: ${subs.map((s) => s.name).join(', ')}',
            );
          }
        });

        // If there's a selected value that doesn't exist in the items, reset it
        if (secondBusinessCategoryProvider.selectedSubcategory != null &&
            !allSubcategories.any((sub) =>
                sub.id ==
                secondBusinessCategoryProvider.selectedSubcategory!.id)) {
          secondBusinessCategoryProvider.selectSubcategory(null);
        }

        // Create unique items for the dropdown
        final dropdownItems = allSubcategories
            .asMap()
            .entries
            .map<DropdownMenuItem<int>>((entry) {
          final subcategory = entry.value;
          final hasDuplicate = subcategoriesById[subcategory.id]!.length > 1;

          // If there are duplicates, include the category name for clarity
          final categoryName = categories
              .firstWhere((cat) => cat.subcategories.contains(subcategory))
              .name;

          return DropdownMenuItem<int>(
            value: subcategory.id,
            child: Text(hasDuplicate
                ? '${subcategory.name} ($categoryName)'
                : subcategory.name),
          );
        }).toList();

        // log unit ids from subcategories

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Gap(10),
            DropdownButtonFormField<int>(
              decoration: InputDecoration(
                labelText: "Select Subcategory",
                labelStyle: const TextStyle(color: LarosaColors.mediumGray),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey, width: 3),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: LarosaColors.secondary,
                    width: 3,
                  ),
                ),
              ),
              value: secondBusinessCategoryProvider.selectedSubcategory?.id,
              items: dropdownItems,
              onChanged: (value) {
                if (value != null) {
                  final selectedSubcategory =
                      allSubcategories.firstWhere((sub) => sub.id == value);
                  secondBusinessCategoryProvider
                      .selectSubcategory(selectedSubcategory);
                  setState(() {
                    unitId = null;
                  });
                }
              },
              isExpanded: true,
              hint: const Text("Choose a Subcategory"),
              validator: (value) =>
                  value == null ? "Please select a subcategory" : null,
            ),
            const Gap(10),
            // Unit Type Dropdown
            if (secondBusinessCategoryProvider.selectedSubcategory != null) ...[
              if (secondBusinessCategoryProvider
                  .selectedSubcategory!.unitTypes.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "This subcategory doesn't have any units available yet",
                    style: TextStyle(color: Colors.red),
                  ),
                )
              else
                DropdownButtonFormField<int>(
                  decoration: InputDecoration(
                    labelText: "Select Unit",
                    labelStyle: const TextStyle(color: LarosaColors.mediumGray),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Colors.grey, width: 3),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: LarosaColors.secondary,
                        width: 3,
                      ),
                    ),
                  ),
                  value: unitId,
                  items: secondBusinessCategoryProvider
                      .selectedSubcategory!.unitTypes
                      .map<DropdownMenuItem<int>>((unit) {
                    return DropdownMenuItem<int>(
                      value: unit.id,
                      child: Text(unit.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
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
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
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
                      reservationTypesList.firstWhere((type) =>
                              type['id'] ==
                              _selectedReservationTypeId)['description'] ??
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
                          color: Theme.of(context)
                              .colorScheme
                              .background
                              .withOpacity(.7),
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
        labelText: 'Adults',
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
        if (value == null || value.isEmpty) {
          return "Number of adults is required";
        }
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
        labelText: 'Children',
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
        if (value == null || value.isEmpty) {
          return "Number of children is required";
        }
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
        suffixText: 'Tsh', // Add a currency prefix
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

  Widget _buildQuantityField() {
    return TextFormField(
      controller: _quantityController,
      decoration: InputDecoration(
        labelText: 'Quantity',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: LarosaColors.secondary, width: 3),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: LarosaColors.secondary, width: 3),
        ),
        hintText: 'Enter Quantity',
        hintStyle: TextStyle(color: LarosaColors.mediumGray.withOpacity(0.8)),
      ),
      keyboardType: TextInputType.number,
      style: const TextStyle(
        color: LarosaColors.primary,
        fontSize: 16,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Quantity is required.";
        }
        final parsedQuantity = int.tryParse(value);
        if (parsedQuantity == null || parsedQuantity <= 0) {
          return "Please enter a valid quantity.";
        }
        return null;
      },
    );
  }

  Widget _buildBreakfastToggle() {
    if (AuthService.isReservation() == false) {
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
          activeColor: CupertinoColors.activeGreen,
          activeTrackColor: CupertinoColors.activeGreen.withValues(alpha: 0.5),
          inactiveThumbColor: LarosaColors.mediumGray,
          inactiveTrackColor: LarosaColors.mediumGray.withValues(alpha: 0.3),
          onChanged: (value) {
            setState(() {
              _breakfastIncluded = value;
            });
          },
        ),
      ],
    );
  }


  bool _wifiIncluded = false;
  Widget _buildWifiToggle(){
    if (AuthService.isReservation() == false) {
      return SizedBox.shrink();
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Wifi Included?",
          style: TextStyle(
            color: LarosaColors.mediumGray,
            fontWeight: FontWeight.w500,
          ),
        ),
        Switch(
          value: _wifiIncluded,
          activeColor: CupertinoColors.activeGreen,
          activeTrackColor: CupertinoColors.activeGreen.withValues(alpha: 0.5),
          inactiveThumbColor: LarosaColors.mediumGray,
          inactiveTrackColor: LarosaColors.mediumGray.withValues(alpha: 0.3),
          onChanged: (value) {
            setState(() {
              _wifiIncluded = value;
            });
          },
        ),
      ],
    );
  }

  bool _gymIncluded = false;
  Widget _buildGymToggle(){
    if (AuthService.isReservation() == false) {
      return SizedBox.shrink();
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Gym Included?",
          style: TextStyle(
            color: LarosaColors.mediumGray,
            fontWeight: FontWeight.w500,
          ),
        ),
        Switch(
          value: _gymIncluded,
          activeColor: CupertinoColors.activeBlue,
          activeTrackColor: CupertinoColors.activeGreen.withValues(alpha: 0.5),
          inactiveThumbColor: LarosaColors.mediumGray,
          inactiveTrackColor: LarosaColors.mediumGray.withValues(alpha: 0.3),
          onChanged: (value) {
            setState(() {
              _gymIncluded = value;
            });
          },
        ),
      ],
    );
  }


  bool _poolIncluded = false;
  Widget _buildPoolToggle(){
    if (AuthService.isReservation() == false) {
      return SizedBox.shrink();
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Swimming Pool Included?",
          style: TextStyle(
            color: LarosaColors.mediumGray,
            fontWeight: FontWeight.w500,
          ),
        ),
        Switch(
          value: _poolIncluded,
          activeColor: CupertinoColors.activeGreen,
          activeTrackColor: CupertinoColors.activeGreen.withValues(alpha: 0.5),
          inactiveThumbColor: LarosaColors.mediumGray,
          inactiveTrackColor: LarosaColors.mediumGray.withValues(alpha: 0.3),
          onChanged: (value) {
            setState(() {
              _poolIncluded = value;
            });
          },
        ),
      ],
    );
  }


  bool _parkingIncluded = false;
  Widget _buildParkingToggle(){
    if (AuthService.isReservation() == false) {
      return SizedBox.shrink();
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Parking Included?",
          style: TextStyle(
            color: LarosaColors.mediumGray,
            fontWeight: FontWeight.w500,
          ),
        ),
        Switch(
          value: _parkingIncluded,
          activeColor: CupertinoColors.systemGreen,
          activeTrackColor: CupertinoColors.systemGreen.withValues(alpha: 0.5),
          inactiveThumbColor: CupertinoColors.systemGrey,
          inactiveTrackColor: CupertinoColors.systemGrey.withValues(alpha: 0.3),
          onChanged: (value) {
            setState(() {
              _parkingIncluded = value;
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
    );
  }

  Widget _buildGradientPostButton(ContentController contentController,
      bool isBusinessPost, bool isReservation) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: () async {
          final formKey = isBusinessPost ? _businessFormKey : _personalFormKey;
          if (formKey.currentState!.validate()) {
            if (contentController.newContentMediaStrings.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Please add media for your post.',
                  ),
                ),
              );
              return;
            }

            setState(() {
              isCreatingPost = true;
            });

            double maxHeight = await HelperFunctions.getMaxImageHeight(
              contentController.newContentMediaStrings,
            );

            bool success = false;

            try {
              if (isBusinessPost && !isReservation) {
                success = await contentController.postBusiness(
                  _captionController.text,
                  double.tryParse(
                        _priceController.text.replaceAll(',', ''),
                      ) ??
                      0,
                  maxHeight,
                  unitId!,
                );
              } else if (isBusinessPost && isReservation) {
                success = await contentController.postReservation(
                  ReservatioPost(
                    caption: _captionController.text,
                    price: double.tryParse(
                          _priceController.text.replaceAll(',', ''),
                        ) ??
                        0,
                    height: maxHeight,
                    unitId: unitId!,
                    reservationTypeId: _selectedReservationTypeId!,
                    adultsCount: int.tryParse(_adultsController.text) ?? 0,
                    childrenCount: int.tryParse(_childrenController.text) ?? 0,
                    breakfastIncluded: _breakfastIncluded,
                    quantity: int.tryParse(_quantityController.text) ?? 0,
                    swingPool: _poolIncluded,
                    parking: _parkingIncluded,
                    wifi: _wifiIncluded,
                    gym: _gymIncluded,
                    cctv: false,
                  ),
                );
              } else {
                success = await contentController.uploadPost(
                  _captionController.text,
                  double.tryParse(_priceController.text.replaceAll(',', '')) ??
                      0,
                );
              }

              setState(() {
                isCreatingPost = false;
              });

              if (success && context.mounted) {
                context.go('/');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Post created successfully'),
                  ),
                );
              }
            } catch (e) {
              LogService.logError('Error creating post: $e');
              setState(() {
                isCreatingPost = false;
              });
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
        body: !_pageReady
            ? const BusinessPostShimmer()
            : CustomScrollView(
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
                          ? [
                              Tab(
                                icon: Icon(Ionicons.briefcase_outline),
                                text: "Business",
                              ),
                              if (hasReservationCategories)
                                Tab(
                                  icon: Icon(CupertinoIcons.bed_double),
                                  text: "Reservation",
                                ),
                              Tab(
                                icon: Icon(Ionicons.person_outline),
                                text: "Personal",
                              ),
                            ]
                          : [
                              Tab(
                                icon: Icon(Ionicons.person_outline),
                                text: "Personal",
                              ),
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
                              _buildTabContent(true, false),
                              if (hasReservationCategories)
                                _buildTabContent(true, true),
                              _buildTabContent(false, false),
                            ]
                          : [
                              _buildTabContent(false, false),
                            ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
