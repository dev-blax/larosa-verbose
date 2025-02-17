import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:larosa_block/Services/auth_service.dart';
import 'package:larosa_block/Services/log_service.dart';
import 'package:larosa_block/Utils/links.dart';

class ApiService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: LarosaLinks.baseurl,
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );

  static Dio get dio => _dio;

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static void _handleError(DioException e, BuildContext? context) {
    String errorMessage = 'An error occurred';

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        errorMessage = 'Connection timeout. Please try again.';
        break;
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 401) {
          errorMessage = 'Unauthorized. Please login again.';
        } else if (statusCode == 403) {
          errorMessage = 'You don\'t have permission to perform this action.';
        } else if (statusCode == 404) {
          errorMessage = 'Resource not found.';
        } else {
          errorMessage = e.response?.data?['message'] ?? 'Server error occurred.';
        }
        break;
      case DioExceptionType.cancel:
        errorMessage = 'Request was cancelled.';
        break;
      case DioExceptionType.connectionError:
        errorMessage = 'No internet connection.';
        break;
      default:
        errorMessage = 'Something went wrong. Please try again.';
    }

    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // send google auth token



  static Future<Response?> _makeRequest(
    Future<Response> Function() requestFunction,
    BuildContext? context,
  ) async {
    try {
      final token = AuthService.getToken();
      _dio.options.headers['Authorization'] = 'Bearer $token';
      
      final response = await requestFunction();
      return response;
    } on DioException catch (e) {
      _handleError(e, context);
      return null;
    } catch (e) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An unexpected error occurred'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  // API Methods
  static Future<bool> blockUser(int profileId, BuildContext context) async {
    final response = await _makeRequest(
      () => _dio.post(
        '/api/v1/blocking/block',
        data: {'profileId': profileId},
      ),
      context,
    );

    if(response != null){
      LogService.logFatal(response.data.toString());
    }

    return response != null;
  }

  static Future<bool> unblockUser(int profileId, BuildContext context) async {
    final response = await _makeRequest(
      () => _dio.post(
        '/api/v1/blocking/unblock',
        data: {'profileId': profileId},
      ),
      context,
    );

    if(response != null){
      LogService.logInfo(response.data.toString());
    }

    return response != null;
  }

  static Future<List<Map<String, dynamic>>> getBlockedUsers(BuildContext context) async {
    final response = await _makeRequest(
      () => _dio.get('/api/v1/blocking/blocked-users'),
      context,
    );

    if (response != null) {
      LogService.logInfo(response.data.toString());
      return List<Map<String, dynamic>>.from(response.data);
    }
    return [];
  }
  // Add more API methods here as needed
}
