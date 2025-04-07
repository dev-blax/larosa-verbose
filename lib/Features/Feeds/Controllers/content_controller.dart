import 'package:flutter/material.dart';
import 'package:dio/dio.dart' as Dio;
import 'package:http_parser/http_parser.dart' as parser;
import 'package:larosa_block/Services/auth_service.dart';
import 'package:larosa_block/Services/log_service.dart';
import 'package:larosa_block/Services/dio_service.dart';
import 'package:larosa_block/Utils/helpers.dart';
import 'package:larosa_block/Utils/links.dart';

class ContentController extends ChangeNotifier {
  final DioService _dioService = DioService();
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
      "caption": HelperFunctions.encodeEmoji(caption),
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

    try {
      LogService.logInfo('Files: ${formData.files.length} ');
      Dio.Response response = await _dioService.dio.post(
        '${LarosaLinks.baseurl}/api/v1/post/create',
        data: formData,
      );

      LogService.logInfo('response code ${response.statusCode}');

      if (response.statusCode == 201) {
        return true;
      } else {
        LogService.logError('non 200 ${response.data}');
        return false;
      }
    } on Dio.DioException catch (e) {
      String errorMessage = 'Failed to upload post';
      
      switch (e.type) {
        case Dio.DioExceptionType.connectionTimeout:
        case Dio.DioExceptionType.sendTimeout:
        case Dio.DioExceptionType.receiveTimeout:
          errorMessage = 'Connection timeout. Please check your internet connection';
          break;
        case Dio.DioExceptionType.badResponse:
          if (e.response?.statusCode == 413) {
            errorMessage = 'File size too large';
          } else if (e.response?.data != null) {
            errorMessage = e.response?.data['message'] ?? 'Server error occurred';
          }
          break;
        case Dio.DioExceptionType.cancel:
          errorMessage = 'Upload was cancelled';
          break;
        case Dio.DioExceptionType.connectionError:
          errorMessage = 'No internet connection';
          break;
        default:
          errorMessage = 'Something went wrong';
      }
      
      LogService.logError('DioError: ${e.message}');
      return false;
    } catch (e) {
      LogService.logError('Error: $e');
      return false;
    }
  }

  Future<bool> postBusiness(String caption, double price, double height, int unitId) async {
    Dio.FormData formData = Dio.FormData.fromMap({
      "caption": HelperFunctions.encodeEmoji(caption),
      "countryId": 1,
      "price": price,
      'height': height,
      'unitId': unitId,
      'size': 1,
      'weight': 1,
    });

    LogService.logInfo('token: ${AuthService.getToken()}');
    LogService.logInfo('unitId: $unitId');

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

    try {
      LogService.logInfo('Files: ${formData.files.length} ');
      LogService.logFatal('sending request');
      
      Dio.Response response = await _dioService.dio.post(
        '${LarosaLinks.baseurl}/api/v1/business-post/create',
        data: formData,
      );

      LogService.logInfo('response code ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        LogService.logInfo('success');
        return true;
      } else {
        LogService.logError('non 200 ${response.data}');
        return false;
      }
    } on Dio.DioException catch (e) {
      String errorMessage = 'Failed to create business post';
      
      switch (e.type) {
        case Dio.DioExceptionType.connectionTimeout:
        case Dio.DioExceptionType.sendTimeout:
        case Dio.DioExceptionType.receiveTimeout:
          errorMessage = 'Connection timeout. Please check your internet connection';
          break;
        case Dio.DioExceptionType.badResponse:
          if (e.response?.statusCode == 413) {
            errorMessage = 'File size too large';
          } else {
            errorMessage = e.response?.data ?? 'Server error occurred';
            LogService.logError('message: ${e.response?.data}');
          }
          break;
        case Dio.DioExceptionType.cancel:
          errorMessage = 'Upload was cancelled';
          break;
        case Dio.DioExceptionType.connectionError:
          errorMessage = 'No internet connection';
          break;
        default:
          errorMessage = 'Something went wrong';
      }
      
      LogService.logError('DioError: ${e.message}');
      return false;
    } catch (e) {
      LogService.logError('Error: $e');
      return false;
    }
  }
}
