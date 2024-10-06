import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:gap/gap.dart';
import 'package:larosa_block/Features/Feeds/Controllers/content_controller.dart';
import 'package:larosa_block/Features/Feeds/camera_content.dart';
import 'package:larosa_block/Utils/colors.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';

class ImagePostScreen extends StatefulWidget {
  const ImagePostScreen({super.key});

  @override
  State<ImagePostScreen> createState() => _ImagePostScreenState();
}

class _ImagePostScreenState extends State<ImagePostScreen> {
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _businessController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isCreatingPost = false;

  @override
  Widget build(BuildContext context) {
    final contentController = Provider.of<ContentController>(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'New Post',
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Iconsax.arrow_left_2,
            color: LarosaColors.primary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
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
                            horizontal: 16.0,
                            vertical: 10,
                          ),
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
                                    child: const Icon(
                                      Icons.delete,
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                        );
                      }),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        height: MediaQuery.of(context).size.width * .8,
                        width: MediaQuery.of(context).size.width * .8,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: InkWell(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const CameraContent()),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Iconsax.gallery_add,
                                ),
                                Gap(10),
                                Text('Add Media')
                              ],
                            ),
                          ),
                        ),
                      )
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
                    TextFormField(
                      minLines: 1,
                      maxLines: 10,
                      controller: _locationController,
                      decoration: const InputDecoration(
                        fillColor: Colors.green,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                        hintText: 'Location',
                        prefixIcon: Icon(Iconsax.location),
                      ),
                    ),
                    const Gap(20),
                    TextFormField(
                      minLines: 1,
                      maxLines: 10,
                      controller: _businessController,
                      decoration: const InputDecoration(
                        fillColor: Colors.green,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                        hintText: 'Related Business',
                        prefixIcon: Icon(Iconsax.shop),
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
                        onPressed: () async {
                          if (contentController
                              .newContentMediaStrings.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Cannot post empty images')),
                            );
                            return;
                          }

                          if (_formKey.currentState!.validate()) {
                            setState(() {
                              isCreatingPost = true;
                            });

                            await contentController.uploadPost(
                              _captionController.text,
                            );

                            setState(() {
                              isCreatingPost = false;
                            });
                          }
                        },
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
            )
          ],
        ),
      ),
    );
  }
}
