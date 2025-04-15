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
          final token = AuthService.getToken();
          // LogService.logInfo('Token: $token');
          if (token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (_hasConnectionError) {
            _hasConnectionError = false;
            NavigationService.hideErrorSnackBar();
          }
          return handler.next(response);
        },
        onError: (DioException error, handler) async {
          String message = '';
          bool isConnectionError = false;

          LogService.logError('Dio Error: $error');

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
                  if (await handleTokenRefresh(error.requestOptions)) {
                    return handler.resolve(await retry(error.requestOptions));
                  }
                  LogService.logInfo('error ${error.response}');

                  message = error.response?.data ?? 'Auth attempt failed. Please login again.';
                  break;
                case 400:
                  message = error.response?.data ?? 'Wrong credentials.';
                  break;
                case 403:
                  message = error.response?.data ?? 'Access denied.';
                  break;
                case 404:
                  message = error.response?.data ?? 'Resource not found.';
                  break;
                case 500:
                  message = error.response?.data ?? 'Server error. Please try again later.';
                  break;
                default:
                  message = error.response?.data ?? 'Something went wrong. Please try again.';
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

  Future<bool> handleTokenRefresh(RequestOptions requestOptions) async {
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

  Future<Response<dynamic>> retry(RequestOptions requestOptions) async {
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
