import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:file_picker/file_picker.dart';
import 'package:larosa_block/Services/auth_service.dart';
import 'package:larosa_block/Services/log_service.dart';
import 'package:larosa_block/Utils/helpers.dart';
import 'package:larosa_block/Utils/links.dart';
import 'package:larosa_block/Utils/svg_paths.dart';
import 'package:dio/dio.dart' as dio;

class BusinessVerificationScreen extends StatefulWidget {
  const BusinessVerificationScreen({super.key});

  @override
  State<BusinessVerificationScreen> createState() =>
      _BusinessVerificationScreenState();
}

class _BusinessVerificationScreenState
    extends State<BusinessVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  List<PlatformFile> attachments = [];
  String fullName = '';
  String otherNames = '';
  int documentTypeId = 0;
  int notableCategoryId = 0;
  int countryId = 1;
  int linkTypeIds = 1;
  String linkValues = "bom.com";

  final String _submitUrl =
      '${LarosaLinks.baseurl}/api/v1/verification-requests/new-request';

  Future<void> _submitRequest() async {
    final String token = AuthService.getToken();
    if (token.isEmpty) {
      LogService.logError('Error: Invalid token.');
      HelperFunctions.logout(context);
      return;
    }
    final int? profileId = AuthService.getProfileId();

    if (profileId == null) {
      LogService.logError(' Invalid profile id');
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (attachments.isEmpty) {
      LogService.logError('Error: No attachments selected.');
      return;
    }

    // using dio
    final client = dio.Dio();
    dio.FormData formData = dio.FormData.fromMap({
      'fulName': fullName,
      'otherNames': otherNames,
      'documentTypeId': documentTypeId.toString(),
      'notableCategoryId': notableCategoryId.toString(),
      'countryId': countryId.toString(),
      'linkTypeIds': [linkTypeIds],
      'linkValues': [linkValues],
    });

    for (var file in attachments) {
      if (file.path != null) {
        formData.files.add(
          MapEntry(
            'attachments',
            await dio.MultipartFile.fromFile(
              file.path!,
            ),
          ),
        );
      } else {
        LogService.logError('Error: One of the files has no path.');
        return;
      }
    }

    dio.Options dioOptions = dio.Options(
      headers: {
        'content-type': 'multipart/form-data',
        'Authorization': 'Bearer ${AuthService.getToken()}',
      },
    );

    try {
      LogService.logTrace('form-data: ${formData.fields}');
      dio.Response dioResponse = await client.post(
        _submitUrl,
        data: formData,
        options: dioOptions,
      );

      if (dioResponse.statusCode == 200 || dioResponse.statusCode == 201) {
        LogService.logInfo('Verification request submitted successfully.');
      } else {
        LogService.logError(
          'Error: Failed to submit verification request. Status code: ${dioResponse.statusCode}, body: ${dioResponse.data}',
        );
      }
    } catch (e) {
      LogService.logError('Error: Failed to submit request: ${e.toString()}');
      return;
    }
  }

  Future<void> _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      allowedExtensions: ['pdf'],
      type: FileType.custom,
    );

    if (result != null) {
      setState(() {
        attachments = result.files;
      });
    } else {
      LogService.logError('User canceled the file picker');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Business verification'),
            const Gap(10),
            SvgPicture.asset(
              SvgIconsPaths.sharpVerified,
              colorFilter: const ColorFilter.mode(Colors.blue, BlendMode.srcIn),
              height: 20,
            ),
          ],
        ),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(
            Iconsax.arrow_left_2,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (value) =>
                    value!.isEmpty ? 'Full name is required' : null,
                onSaved: (value) => fullName = value!,
              ),
              const Gap(10),
              TextFormField(
                decoration:
                    const InputDecoration(labelText: 'Other Names (Optional)'),
                onSaved: (value) => otherNames = value ?? '',
              ),
              const Gap(10),
              ElevatedButton(
                onPressed: _pickFiles,
                child: const Text('Pick Attachments'),
              ),
              const Gap(10),
              Text(
                attachments.isNotEmpty
                    ? '${attachments.length} file(s) selected'
                    : 'No files selected',
              ),
              const Gap(10),
              ElevatedButton(
                onPressed: _submitRequest,
                child: const Text('Submit Request'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
