// lib/data/services/api_service.dart

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../config/api_config.dart';

class ApiService {
  late final Dio _dio;
  
  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.apiBaseUrl,
        headers: ApiConfig.headers,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
    
    // Only add logging interceptor in debug mode
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          error: true,
          requestHeader: false,
          responseHeader: false,
          request: true,
          logPrint: (log) {
            // Custom log formatting to reduce noise
            debugPrint('🌐 $log');
          },
        ),
      );
    }
    
    // Add a custom interceptor for cleaner error handling
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (kDebugMode) {
            debugPrint('🚀 API Request: ${options.method} ${options.path}');
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            debugPrint('✅ API Response: ${response.statusCode} ${response.requestOptions.path}');
          }
          handler.next(response);
        },
        onError: (error, handler) {
          if (kDebugMode) {
            debugPrint('❌ API Error: ${error.message}');
            if (error.response != null) {
              debugPrint('   Status: ${error.response?.statusCode}');
              debugPrint('   Data: ${error.response?.data}');
            }
          }
          handler.next(error);
        },
      ),
    );
  }
  
  Future<List<Map<String, dynamic>>> searchTokens(String query) async {
    try {
      final response = await _dio.get(
        ApiConfig.tokenSearch,
        queryParameters: {'query': query},
      );
      
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<List<Map<String, dynamic>>> getPortfolioData(List<Map<String, dynamic>> tokenList) async {
    try {
      final response = await _dio.post(
        ApiConfig.portfolio,
        data: {
          'token_list': jsonEncode(tokenList),
        },
      );
      
      // Handle empty response
      if (response.data is List && (response.data as List).isEmpty) {
        return [];
      }
      
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<Map<String, dynamic>?> getWalletBalance(String address, String chain) async {
    try {
      final response = await _dio.post(
        ApiConfig.wallets,
        data: {
          'address': address,
          'chain': chain,
        },
      );
      
      if (response.data is Map<String, dynamic>) {
        return response.data;
      }
      
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw _handleError(e);
    }
  }
  
  Exception _handleError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout) {
      return Exception('Connection timeout');
    } else if (error.type == DioExceptionType.receiveTimeout) {
      return Exception('Receive timeout');
    } else if (error.type == DioExceptionType.badResponse) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 401) {
        return Exception('Unauthorized - Please check your auth token');
      } else if (statusCode == 404) {
        return Exception('Token not found');
      } else if (statusCode == 400) {
        return Exception('Bad request');
      }
      return Exception('Server error: $statusCode');
    } else if (error.type == DioExceptionType.cancel) {
      return Exception('Request cancelled');
    } else {
      return Exception('Network error: ${error.message}');
    }
  }
}