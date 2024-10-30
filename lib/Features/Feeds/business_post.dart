// import 'dart:io';
// import 'dart:typed_data';
// import 'package:crop_your_image/crop_your_image.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_spinkit/flutter_spinkit.dart';
// import 'package:gap/gap.dart';
// import 'package:go_router/go_router.dart';
// import 'package:iconsax/iconsax.dart';
// import 'package:ionicons/ionicons.dart';
// import 'package:larosa_block/Features/Feeds/Controllers/content_controller.dart';
// import 'package:larosa_block/Utils/colors.dart';
// import 'package:larosa_block/Utils/helpers.dart';
// import 'package:provider/provider.dart';
// import 'package:image_picker/image_picker.dart';

// class BusinessPostScreen extends StatefulWidget {
//   const BusinessPostScreen({super.key});

//   @override
//   State<BusinessPostScreen> createState() => _BusinessPostScreenState();
// }

// class _BusinessPostScreenState extends State<BusinessPostScreen> {
//   final TextEditingController _captionController = TextEditingController();
//   final TextEditingController _priceController = TextEditingController();
//   final _formKey = GlobalKey<FormState>();
//   final CropController _cropController = CropController();
//   final ImagePicker _picker = ImagePicker();
//   bool isCreatingPost = false;
//   Uint8List? _selectedImage;

//   Future<void> _pickImage() async {
//     final XFile? pickedFile = await _picker.pickImage(
//       source: ImageSource.gallery,
//     );

//     if (pickedFile != null) {
//       final imageData = await pickedFile.readAsBytes();
//       setState(() {
//         _selectedImage = imageData;
//       });
//       _showCropper();
//     }
//   }

//   void _showCropper() {
//     if (_selectedImage == null) return;

//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           contentPadding: EdgeInsets.zero,
//           content: SizedBox(
//             height: 400,
//             width: 300,
//             child: Crop(
//               image: _selectedImage!,
//               controller: _cropController,
//               aspectRatio: 3 / 4,
//               onCropped: (croppedData) {
//                 Navigator.pop(context);
//                 _addCroppedImage(croppedData);
//               },
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 // Call crop method here
//                 _cropController.crop();
//               },
//               child: const Text('Crop'),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(context);
//               },
//               child: const Text('Cancel'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   void _addCroppedImage(Uint8List croppedData) {
//     final String tempPath =
//         '${Directory.systemTemp.path}/${DateTime.now().millisecondsSinceEpoch}.png';
//     final File imageFile = File(tempPath)..writeAsBytesSync(croppedData);

//     Provider.of<ContentController>(context, listen: false)
//         .addToNewContentMediaStrings(imageFile.path);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final contentController = Provider.of<ContentController>(context);
//     return Scaffold(
//       appBar: AppBar(
//         leading: IconButton(
//           onPressed: () => context.pop(),
//           icon: const Icon(Iconsax.arrow_left_2),
//         ),
//         title: const Text("Business Post"),
//         centerTitle: true,
//         actions: [
//           FilledButton.icon(
//             icon: const Icon(Ionicons.sunny, size: 20,),
//           onPressed: () => context.push('/main-post'),
//           label: const Text('Personal Post'),)
//            ,
//         ],
//       ),
//       body: ListView(
//         children: [
//           Consumer<ContentController>(
//             builder: (context, controller, child) {
//               return SingleChildScrollView(
//                 scrollDirection: Axis.horizontal,
//                 child: Row(
//                   children: [
//                     ...controller.newContentMediaStrings.map((mediaPath) {
//                       return Padding(
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 16.0, vertical: 10),
//                         child: Stack(
//                           children: [
//                             Image.file(
//                               File(mediaPath),
//                               width: MediaQuery.of(context).size.width * .8,
//                               fit: BoxFit.cover,
//                             ),
//                             Positioned(
//                               top: 10,
//                               right: 10,
//                               child: InkWell(
//                                 onTap: () {
//                                   controller.removeFromNewContentMediaStrings(
//                                       mediaPath);
//                                 },
//                                 child: Container(
//                                   padding: const EdgeInsets.all(8),
//                                   decoration: BoxDecoration(
//                                     borderRadius: BorderRadius.circular(20),
//                                     color: Colors.black.withOpacity(.5),
//                                   ),
//                                   child: const Icon(Icons.delete),
//                                 ),
//                               ),
//                             )
//                           ],
//                         ),
//                       );
//                     }),
//                     InkWell(
//                       onTap: _pickImage,
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 16, vertical: 10),
//                         height: MediaQuery.of(context).size.width * .8,
//                         width: MediaQuery.of(context).size.width * .8,
//                         decoration: BoxDecoration(
//                           color: Colors.grey.withOpacity(.7),
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                         child: const Column(
//                           mainAxisSize: MainAxisSize.min,
//                           crossAxisAlignment: CrossAxisAlignment.center,
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Icon(Iconsax.gallery_add),
//                             Gap(10),
//                             Text('Add Media')
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               );
//             },
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 children: [
//                   const Gap(20),
//                   TextFormField(
//                     minLines: 1,
//                     maxLines: 10,
//                     controller: _priceController,
//                     decoration: const InputDecoration(
//                       prefix: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Text(
//                             'Tsh',
//                             style: TextStyle(color: LarosaColors.mediumGray),
//                           ),
//                           Gap(10),
//                         ],
//                       ),
//                       fillColor: Colors.green,
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.all(Radius.circular(20)),
//                       ),
//                       hintText: 'Price',
//                     ),
//                     keyboardType: TextInputType.number,
//                   ),
//                   const Gap(20),
//                   TextFormField(
//                     minLines: 3,
//                     maxLines: 10,
//                     controller: _captionController,
//                     decoration: const InputDecoration(
//                       fillColor: Colors.green,
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.all(Radius.circular(20)),
//                       ),
//                       hintText: 'Caption',
//                     ),
//                   ),
//                   const Gap(20),
//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton.icon(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: LarosaColors.primary,
//                         shape: const ContinuousRectangleBorder(
//                           borderRadius: BorderRadius.all(Radius.circular(40)),
//                         ),
//                       ),
//                       onPressed: () async {
//                         if (contentController.newContentMediaStrings.isEmpty) {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             const SnackBar(
//                                 content: Text('Cannot post empty images')),
//                           );
//                           return;
//                         }

//                         if (_formKey.currentState!.validate()) {
//                           setState(() {
//                             isCreatingPost = true;
//                           });

//                           // Get the maximum height of the images
//                           double maxHeight = await HelperFunctions.getMaxImageHeight(
//                             contentController.newContentMediaStrings,
//                           );

//                           bool success = await contentController.postBusiness(
//                             _captionController.text,
//                             double.parse(_priceController.text),
//                             maxHeight,
//                           );

//                           setState(() {
//                             isCreatingPost = false;
//                           });

//                           if (success && context.mounted){
//                             context.go('/');
//                           }
//                         }
//                       },
//                       icon: isCreatingPost
//                           ? const SpinKitCircle(size: 24, color: Colors.white)
//                           : const Icon(Iconsax.document_upload,
//                               color: Colors.white),
//                       label: Padding(
//                         padding: const EdgeInsets.symmetric(vertical: 16.0),
//                         child: Text(
//                           isCreatingPost ? '' : 'CREATE BUSINESS POST',
//                           style: const TextStyle(color: Colors.white),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

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
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final imageData = await pickedFile.readAsBytes();
      setState(() {
        _selectedImage = imageData;
      });
      _showCropper();
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
                  if (isBusinessPost) ...[
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
    return Consumer<ContentController>(
      builder: (context, controller, child) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...controller.newContentMediaStrings.map((mediaPath) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
                  child: Stack(
                    children: [
                      Image.file(
                        File(mediaPath),
                        width: MediaQuery.of(context).size.width * .7,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: InkWell(
                          onTap: () => controller
                              .removeFromNewContentMediaStrings(mediaPath),
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
              InkWell(
                onTap: _pickImage,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  height: MediaQuery.of(context).size.width * .7,
                  width: MediaQuery.of(context).size.width * .7,
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
      },
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

            bool success = await contentController.postBusiness(
              _captionController.text,
              double.tryParse(_priceController.text.replaceAll(',', '')) ?? 0,
              maxHeight,
            );

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
      length: 2,
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
                tabs: const [
                  Tab(icon: Icon(Ionicons.briefcase_outline), text: "Business"),
                  Tab(icon: Icon(Ionicons.person_outline), text: "Personal"),
                ],
                labelColor: LarosaColors.primary, // Active tab color
                unselectedLabelColor:
                    Colors.purple.withOpacity(0.8), // Inactive tab color
                indicatorColor: LarosaColors
                    .primary, // Indicator color to match active tab color
              ),
            ),
            SliverFillRemaining(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTabContent(true),
                  _buildTabContent(false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
