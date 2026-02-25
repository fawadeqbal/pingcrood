import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/foundation.dart'; // Added for kIsWeb

class ApiClient {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://192.168.1.2:3001';
    } else {
      return 'http://192.168.1.2:3001';
    }
  }
  late Dio dio;

  ApiClient() {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('jwt_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        if (e.response?.statusCode == 401) {
          // Handle token expiry (e.g., redirect to login)
        }
        return handler.next(e);
      },
    ));
  }

  // Auth Endpoints
  Future<Response> login(String email, String password) async {
    return dio.post('/auth/login', data: {'email': email, 'password': password});
  }

  Future<Response> register(String email, String password, String username) async {
    return dio.post('/auth/register', data: {
      'email': email,
      'password': password,
      'username': username,
    });
  }

  // Chat Endpoints
  Future<Response> getRooms() async {
    return dio.get('/chat/rooms');
  }

  Future<Response> getMessages(String roomId, {int limit = 50, int skip = 0}) async {
    return dio.get('/chat/rooms/$roomId/messages', queryParameters: {
      'limit': limit,
      'skip': skip,
    });
  }

  Future<Response> searchUsers(String username) async {
    return dio.get('/users/search/$username');
  }

  Future<Response> createPrivateRoom(String targetUserId) async {
    return dio.post('/chat/rooms/private', data: {'targetUserId': targetUserId});
  }
}
