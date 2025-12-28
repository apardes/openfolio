// lib/config/api_config.dart
import 'package:openfolio/config/secrets.dart';

class ApiConfig {
  // Base URL
  static const String apiBaseUrl = baseUrl;
  
  // API Endpoints
  static const String tokenSearch = '/api/search/';
  static const String portfolio = '/api/portfolio/';
  static const String wallets = '/api/wallets/';
  
  // Request headers
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Token $authToken',
  };
}