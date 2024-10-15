import 'package:flutter/material.dart';
import 'package:dio/dio.dart' as Dio;
import 'package:http_parser/http_parser.dart' as parser;
import 'package:larosa_block/Services/auth_service.dart';
import 'package:larosa_block/Services/log_service.dart';
import 'package:larosa_block/Utils/helpers.dart';
import 'package:larosa_block/Utils/links.dart';

class ContentController extends ChangeNotifier {
  final client = Dio.Dio();
  List<String> newContentMediaStrings = [];
  List<Map<String, dynamic>> posts = [];
  String snippetPath = '';

  void addToNewContentMediaStrings(String mediaPath) {
    newContentMediaStrings.add(mediaPath);
    notifyListeners();
  }

  void removeFromNewContentMediaStrings(String mediaPath) {
    newContentMediaStrings.remove(mediaPath);
    notifyListeners();
  }

  Future<void> uploadPost(String caption) async {
    Dio.FormData formData = Dio.FormData.fromMap({
      "caption": caption,
      "profileId": AuthService.getProfileId(),
      "countryId": 1,
    });

    for (String mediaPath in newContentMediaStrings) {
      formData.files.add(
        MapEntry(
          'file',
          await Dio.MultipartFile.fromFile(
            mediaPath,
            contentType: parser.MediaType("image", "*"),
          ),
        ),
      );
    }

    Dio.Options myOptions = Dio.Options(
      headers: {
        'content-type': 'multipart/form-data',
        'Authorization': 'Bearer ${AuthService.getToken()}',
      },
    );

    LogService.logInfo('token ${AuthService.getToken()}');

    try {
      Dio.Response response = await client.post(
        'https://${LarosaLinks.nakedBaseUrl}/PostEditDelete/upload',
        data: formData,
        options: myOptions,
      );

      LogService.logInfo('response code ${response.statusCode}');

      if (response.statusCode == 403) {
        LogService.logDebug('refreshing');
        await AuthService.refreshToken();
        LogService.logDebug('uploading again');
        await uploadPost(caption);
      } else if (response.statusCode == 201) {
        HelperFunctions.showToast('Success', true);
      } else {
        LogService.logError('non 200 ${response.data}');
      }
    } catch (e) {
      LogService.logError('Error: $e');
    }
  }
}
