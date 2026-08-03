import 'package:dio/dio.dart';

class AuthApi {
  static final Dio _dio = Dio(
    BaseOptions(
      //서버 (변경: 서버주소 > 10.42.0.1)
      baseUrl: 'http://10.42.0.1:5000',
      connectTimeout: const Duration(seconds: 7),
      receiveTimeout: const Duration(seconds: 7),
    ),
  );

  static Future<Map<String, dynamic>> register({
    required String userId,
    required String password,
    required String name,
    required String phone,
  }) async {
    final response = await _dio.post(
      '/auth/register',
      data: {
        'user_id': userId,
        'password': password,
        'name': name,
        'phone': phone,
      },
    );

    return Map<String, dynamic>.from(response.data);
  }

  static Future<Map<String, dynamic>> findId({
    required String name,
    required String phone,
  }) async {
    final response = await _dio.post(
      '/auth/find_id',
      data: {'name': name, 'phone': phone},
    );

    return Map<String, dynamic>.from(response.data);
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String userId,
    required String name,
    required String phone,
    required String newPassword,
  }) async {
    final response = await _dio.post(
      '/auth/reset_password',
      data: {
        'user_id': userId,
        'name': name,
        'phone': phone,
        'new_password': newPassword,
      },
    );

    return Map<String, dynamic>.from(response.data);
  }
}
