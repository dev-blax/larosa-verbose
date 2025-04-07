import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:larosa_block/Features/Stories/providers/story_provider.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  final List<File> _selectedFiles = [];
  final List<TextEditingController> _captionControllers = [];
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _pickMedia(ImageSource source) async {
    try {
      final List<XFile> files = await _picker.pickMultiImage();
      
      if (files.isEmpty) return;

      // Limit to 6 files as per API
      final filesToAdd = files.take(6 - _selectedFiles.length).toList();

      setState(() {
        for (var file in filesToAdd) {
          _selectedFiles.add(File(file.path));
          _captionControllers.add(TextEditingController());
        }
      });

      HapticFeedback.mediumImpact();
    } catch (e) {
      _showError('Failed to pick media');
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
      _captionControllers[index].dispose();
      _captionControllers.removeAt(index);
    });
    HapticFeedback.lightImpact();
  }

  Future<void> _uploadStory() async {
    if (_selectedFiles.isEmpty) {
      _showError('Please select at least one image');
      return;
    }

    setState(() => _isUploading = true);

    try {
      final filePaths = _selectedFiles.map((file) => file.path).toList();
      final captions = _captionControllers
          .map((controller) => controller.text.trim())
          .toList();

      final success = 
      await context
          .read<StoryProvider>()
          .uploadStory(filePaths, captions);


      if (success) {
        if (mounted) {
          context.pop();
        }
      }
    } catch (e) {
      _showError('Failed to upload story: $e');
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _captionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Story'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.pop(),
          child: const Icon(CupertinoIcons.xmark),
        ),
        actions: _selectedFiles.isEmpty
            ? null
            : [
                CupertinoButton(
                  onPressed: _isUploading ? null : _uploadStory,
                  child: _isUploading
                      ? const CupertinoActivityIndicator()
                      : const Text('Share'),
                ),
              ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _selectedFiles.isEmpty
                  ? _EmptyState(onPickMedia: () => _pickMedia(ImageSource.gallery))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _selectedFiles.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemBackground,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: CupertinoColors.systemGrey.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(12),
                                    ),
                                    child: AspectRatio(
                                      aspectRatio: 16 / 9,
                                      child: Image.file(
                                        _selectedFiles[index],
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () => _removeFile(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: CupertinoColors.black.withOpacity(0.5),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Icon(
                                          CupertinoIcons.xmark,
                                          color: CupertinoColors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: CupertinoTextField(
                                  controller: _captionControllers[index],
                                  placeholder: 'Add a caption...',
                                  maxLines: null,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            if (_selectedFiles.length < 6)
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: CupertinoButton.filled(
                          onPressed: () => _pickMedia(ImageSource.gallery),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(CupertinoIcons.photo_on_rectangle),
                              SizedBox(width: 8),
                              Text('Add Photos'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onPickMedia;

  const _EmptyState({required this.onPickMedia});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.photo_on_rectangle,
            size: 64,
            color: CupertinoColors.systemGrey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Share your moments',
            style: TextStyle(
              fontSize: 16,
              color: CupertinoColors.systemGrey,
            ),
          ),
          const SizedBox(height: 24),
          CupertinoButton.filled(
            onPressed: onPickMedia,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(CupertinoIcons.photo),
                SizedBox(width: 8),
                Text('Choose from Gallery'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
