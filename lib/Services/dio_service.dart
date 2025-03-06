import 'package:dio/dio.dart';
import 'package:larosa_block/Services/auth_service.dart';
import 'package:larosa_block/Services/log_service.dart';
import 'package:larosa_block/Services/navigation_service.dart';

class DioService {
  static final DioService _instance = DioService._internal();
  late final Dio dio;
  bool _hasConnectionError = false;

  factory DioService() {
    return _instance;
  }

  DioService._internal() {
    dio = Dio();
    _setupInterceptors();
  }

  void _setupInterceptors() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Add auth token to all requests
          final token = AuthService.getToken();
          if (token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // If we get a successful response and previously had a connection error,
          // hide the error snackbar as connection is restored
          if (_hasConnectionError) {
            _hasConnectionError = false;
            NavigationService.hideErrorSnackBar();
          }
          return handler.next(response);
        },
        onError: (DioException error, handler) async {
          String message = '';
          bool isConnectionError = false;

          switch (error.type) {
            case DioExceptionType.connectionTimeout:
            case DioExceptionType.sendTimeout:
            case DioExceptionType.receiveTimeout:
              message = 'Connection timeout. Please check your internet connection.';
              isConnectionError = true;
              break;
            case DioExceptionType.connectionError:
              message = 'No internet connection.';
              isConnectionError = true;
              break;
            case DioExceptionType.badResponse:
              switch (error.response?.statusCode) {
                case 401:
                  // Try to refresh token
                  if (await _handleTokenRefresh(error.requestOptions)) {
                    return handler.resolve(await _retry(error.requestOptions));
                  }
                  message = 'Auth attempt failed. Please login again.';
                  break;
                case 403:
                  message = 'Access denied.';
                  break;
                case 404:
                  message = 'Resource not found.';
                  break;
                case 500:
                  message = 'Server error. Please try again later.';
                  break;
                default:
                  message = 'Something went wrong. Please try again.';
              }
              break;
            default:
              message = 'Unexpected error occurred.';
          }

          _hasConnectionError = isConnectionError;
          LogService.logError('Dio Error: $error');
          NavigationService.showErrorSnackBar(message);
          
          return handler.next(error);
        },
      ),
    );
  }

  Future<bool> _handleTokenRefresh(RequestOptions requestOptions) async {
    try {
      bool refreshed = await AuthService.booleanRefreshToken();
      if (refreshed) {
        final token = AuthService.getToken();
        requestOptions.headers['Authorization'] = 'Bearer $token';
        return true;
      }
    } catch (e) {
      LogService.logError('Token refresh failed: $e');
    }
    return false;
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions) async {
    final options = Options(
      method: requestOptions.method,
      headers: requestOptions.headers,
    );
    return dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }
}
