import 'dart:ui' as ui;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart' as Dio;
import 'package:http_parser/http_parser.dart' as parser;
import 'package:larosa_block/Services/auth_service.dart';
import 'package:larosa_block/Services/log_service.dart';
import 'package:larosa_block/Services/dio_service.dart';
import 'package:larosa_block/Utils/helpers.dart';
import 'package:larosa_block/Utils/links.dart';

class ReservatioPost {
  final String caption;
  final double price;
  final double height;
  final int unitId;
  final int reservationTypeId;
  final int adultsCount;
  final int childrenCount;
  final bool breakfastIncluded;
  final int quantity;
  final bool swingPool;
  final bool parking;
  final bool wifi;
  final bool gym;
  final bool cctv;

  ReservatioPost({
    required this.caption,
    required this.price,
    required this.height,
    required this.unitId,
    required this.reservationTypeId,
    required this.adultsCount,
    required this.childrenCount,
    required this.breakfastIncluded,
    required this.quantity,
    required this.swingPool,
    required this.parking,
    required this.wifi,
    required this.gym,
    required this.cctv,
  });
}

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
        newContentMediaStrings.clear();
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
          errorMessage =
              'Connection timeout. Please check your internet connection';
          break;
        case Dio.DioExceptionType.badResponse:
          if (e.response?.statusCode == 413) {
            errorMessage = 'File size too large';
          } else if (e.response?.data != null) {
            errorMessage =
                e.response?.data['message'] ?? 'Server error occurred';
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

  Future<bool> postBusiness(
      String caption, double price, double height, int unitId) async {
    Dio.FormData formData = Dio.FormData.fromMap({
      "caption": HelperFunctions.encodeEmoji(caption),
      "countryId": 1,
      "price": price,
      'height': height,
      'unitId': unitId,
      'size': 1,
      'weight': 1,
      'aspectRation': 1.2
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
      LogService.logFatal('formdata');
      print(formData.fields);

      Dio.Response response = await _dioService.dio.post(
        '${LarosaLinks.baseurl}/api/v1/business-post/create',
        data: formData,
      );

      LogService.logInfo('response code ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        LogService.logInfo('success');
        newContentMediaStrings.clear();
        return true;
      } else {
        LogService.logError('non 200 ${response.data}');
        return false;
      }
    } on Dio.DioException catch (e) {
      switch (e.type) {
        case Dio.DioExceptionType.connectionTimeout:
        case Dio.DioExceptionType.sendTimeout:
        case Dio.DioExceptionType.receiveTimeout:
          break;
        case Dio.DioExceptionType.badResponse:
          if (e.response?.statusCode == 413) {
          } else {
            LogService.logError('message: ${e.response?.data}');
          }
          break;
        case Dio.DioExceptionType.cancel:
          break;
        case Dio.DioExceptionType.connectionError:
          break;
        default:
      }

      LogService.logError('DioError: ${e.message}');
      return false;
    } catch (e) {
      LogService.logError('Error: $e');
      return false;
    }
  }

  Future<bool> postReservation(ReservatioPost reservationPost) async {
    List<int> facilityIds = [];
    if (reservationPost.swingPool) facilityIds.add(2);
    if (reservationPost.parking) facilityIds.add(4);
    if (reservationPost.wifi) facilityIds.add(1);
    if (reservationPost.gym) facilityIds.add(3);
    if (reservationPost.cctv) facilityIds.add(102);

    List<int> activityIds = [1];

    LogService.logFatal('facilityIds: $facilityIds');
    LogService.logFatal('reservationPost: $reservationPost');
    Dio.FormData formData = Dio.FormData.fromMap({
      "caption": HelperFunctions.encodeEmoji(reservationPost.caption),
      "countryId": 1,
      "price": reservationPost.price,
      'height': reservationPost.height,
      'unitId': reservationPost.unitId,
      'reservationTypeId': reservationPost.reservationTypeId,
      'adults': reservationPost.adultsCount,
      'children': reservationPost.childrenCount,
      'breakfastIncluded': reservationPost.breakfastIncluded,
      'quantity': reservationPost.quantity,
      'facilityIds': facilityIds,
      'activityIds': activityIds,
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

    // get aspect ratio of first image
    double aspectRatio = await getImageAspectRatio(newContentMediaStrings[0]);
    formData.fields.add(MapEntry('aspectRatio', aspectRatio.toString()));

    LogService.logTrace('formData: ${formData.fields}');


    try {
      LogService.logFatal('Files: ${formData.files.length} ');
      Dio.Response response = await _dioService.dio.post(
        '${LarosaLinks.baseurl}/api/v1/reservation-post/create',
        data: formData,
      );

      LogService.logInfo('response code ${response.statusCode}');
      LogService.logInfo('response data ${response.data}');

      if (response.statusCode == 201) {
        newContentMediaStrings.clear();
        return true;
      } else {
        LogService.logError('non 200 ${response.data}');
        return false;
      }
    } on Dio.DioException catch (e) {
      switch (e.type) {
        case Dio.DioExceptionType.connectionTimeout:
        case Dio.DioExceptionType.sendTimeout:
        case Dio.DioExceptionType.receiveTimeout:
          break;
        case Dio.DioExceptionType.badResponse:
          if (e.response?.statusCode == 413) {
          } else {
            LogService.logError('message: ${e.response?.data}');
          }
          break;
        case Dio.DioExceptionType.cancel:
          break;
        case Dio.DioExceptionType.connectionError:
          break;
        default:
      }

      LogService.logError('DioError: ${e.message}');
      return false;
    } catch (e) {
      LogService.logError('Error: $e');
      return false;
    }
  }

  // function to get aspect ratio of image
  Future<double> getImageAspectRatio(String imagePath) async {
    try {
      // Read the file as bytes
      final File imageFile = File(imagePath);
      final Uint8List bytes = await imageFile.readAsBytes();

      // Decode the image
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();

      // Calculate the aspect ratio
      final double width = frameInfo.image.width.toDouble();
      final double height = frameInfo.image.height.toDouble();

      // Handle potential division by zero
      if (height == 0) {
        throw Exception('Invalid image: height is zero');
      }

      final double aspectRatio = width / height;

      // Make sure to dispose of the image to free up memory
      // frameInfo.image.dispose();

      return aspectRatio;
    } catch (e) {
      throw Exception('Failed to get image aspect ratio: $e');
    }
  }
}
