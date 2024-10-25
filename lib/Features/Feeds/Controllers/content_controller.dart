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

  Future<bool> uploadPost(String caption, double height) async {
    Dio.FormData formData = Dio.FormData.fromMap({
      "caption": caption,
      "profileId": AuthService.getProfileId(),
      "countryId": 1,
      'height': height,
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
        'https://${LarosaLinks.nakedBaseUrl}/api/v1/post/create',
        data: formData,
        options: myOptions,
      );

      LogService.logInfo('response code ${response.statusCode}');

      if (response.statusCode == 403) {
        LogService.logDebug('refreshing');
        await AuthService.refreshToken();
        LogService.logDebug('uploading again');
        return uploadPost(caption, height);
      } else if (response.statusCode == 201) {
        HelperFunctions.showToast('Success', true);
        return true;
      } else {
        LogService.logError('non 200 ${response.data}');
        return false;
      }
    } catch (e) {
      LogService.logError('Error: $e');
      return false;
    }
  }

  Future<bool> postBusiness(String caption, double price, double height) async {
    Dio.FormData formData = Dio.FormData.fromMap({
      "caption": caption,
      "countryId": 1,
      "price": price,
      'height': height,
      'unitId': 1,
      'size': 1,
      'weight': 1,
    });

    LogService.logInfo('token: ${AuthService.getToken()}');

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

    try {
      LogService.logInfo('Files: ${formData.files.length} ');
      LogService.logInfo('form data: ${formData.fields}');

      LogService.logFatal('sending request');
      Dio.Response response = await client.post(
        'https://${LarosaLinks.nakedBaseUrl}/api/v1/business-post/create',
        data: formData,
        options: myOptions,
      );

      LogService.logInfo('response code ${response.statusCode}');

      if (response.statusCode == 403) {
        LogService.logDebug('refreshing');
        await AuthService.refreshToken();
        LogService.logDebug('uploading again');
        return await postBusiness(
          caption,
          price,
          height,
        );
      } else if (response.statusCode == 201 || response.statusCode == 200) {
        HelperFunctions.showToast('Success', true);
        return true;
      } else {
        LogService.logError('non 200 ${response.data}');
        return false;
      }
    } catch (e) {
      LogService.logError('Error: $e');
      HelperFunctions.showToast('An Error Occurred! Pleae try again', false,);
      return false;
    }
  }
}
