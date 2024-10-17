import 'dart:io';
import 'dart:typed_data';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:larosa_block/Features/Feeds/Controllers/content_controller.dart';
import 'package:larosa_block/Utils/colors.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

class BusinessPostScreen extends StatefulWidget {
  const BusinessPostScreen({super.key});

  @override
  State<BusinessPostScreen> createState() => _BusinessPostScreenState();
}

class _BusinessPostScreenState extends State<BusinessPostScreen> {
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final CropController _cropController = CropController();
  final ImagePicker _picker = ImagePicker();
  bool isCreatingPost = false;
  Uint8List? _selectedImage;

  Future<void> _pickImage() async {
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
  }

  void _showCropper() {
    if (_selectedImage == null) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding: EdgeInsets.zero,
          content: SizedBox(
            height: 400, 
            width: 300, 
            child: Crop(
              image: _selectedImage!,
              controller: _cropController,
              aspectRatio: 4 / 3,
              onCropped: (croppedData) {
                Navigator.pop(context);
                _addCroppedImage(croppedData);
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Call crop method here
                _cropController.crop();
              },
              child: const Text('Crop'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _addCroppedImage(Uint8List croppedData) {
    final String tempPath =
        '${Directory.systemTemp.path}/${DateTime.now().millisecondsSinceEpoch}.png';
    final File imageFile = File(tempPath)..writeAsBytesSync(croppedData);

    Provider.of<ContentController>(context, listen: false)
        .addToNewContentMediaStrings(imageFile.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Iconsax.arrow_left_2),
        ),
        title: const Text("Business Post"),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          Consumer<ContentController>(
            builder: (context, controller, child) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...controller.newContentMediaStrings.map((mediaPath) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 10),
                        child: Stack(
                          children: [
                            Image.file(
                              File(mediaPath),
                              width: MediaQuery.of(context).size.width * .8,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              top: 10,
                              right: 10,
                              child: InkWell(
                                onTap: () {
                                  controller.removeFromNewContentMediaStrings(
                                      mediaPath);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: Colors.black.withOpacity(.5),
                                  ),
                                  child: const Icon(Icons.delete),
                                ),
                              ),
                            )
                          ],
                        ),
                      );
                    }),
                    InkWell(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        height: MediaQuery.of(context).size.width * .8,
                        width: MediaQuery.of(context).size.width * .8,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Iconsax.gallery_add),
                            Gap(10),
                            Text('Add Media')
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Gap(20),
                  TextFormField(
                    minLines: 1,
                    maxLines: 10,
                    controller: _priceController,
                    decoration: const InputDecoration(
                      fillColor: Colors.green,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      hintText: 'Price',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const Gap(20),
                  TextFormField(
                    minLines: 3,
                    maxLines: 10,
                    controller: _captionController,
                    decoration: const InputDecoration(
                      fillColor: Colors.green,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      hintText: 'Caption',
                    ),
                  ),
                  const Gap(20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LarosaColors.primary,
                        shape: const ContinuousRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(40)),
                        ),
                      ),
                      onPressed: () async {},
                      icon: isCreatingPost
                          ? const SpinKitCircle(size: 14, color: Colors.white)
                          : const Icon(Iconsax.document_upload,
                              color: Colors.white),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          isCreatingPost ? '' : 'CREATE POST',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
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

  // Show action sheet to choose between gallery or camera
}
