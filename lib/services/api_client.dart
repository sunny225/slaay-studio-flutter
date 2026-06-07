import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static String? customBaseUrl;

  static String get baseUrl {
    String url;
    if (customBaseUrl != null && customBaseUrl!.isNotEmpty) {
      url = customBaseUrl!;
    } else if (kDebugMode) {
      url = 'https://f6d6-2405-201-c004-6189-b4ec-ad76-6fc1-dc83.ngrok-free.app/api';
    } else {
      url = 'https://vastraa-api.onrender.com/api';
    }

    // Normalize URL: ensure it contains /api (or ends with it)
    if (!url.contains('/api')) {
      if (url.endsWith('/')) {
        url = '${url}api';
      } else {
        url = '$url/api';
      }
    }

    // Strip trailing slash if present
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }

    return url;
  } 
  
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'x-storefront-access-key': 'slaay_sf_sandbox_active_license_key_2026',
      'ngrok-skip-browser-warning': 'true',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> get(String endpoint) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl$endpoint');
      return await http.get(url, headers: headers);
    } catch (e) {
      throw ApiException('Network connection failed. Please check your internet connection.');
    }
  }

  static Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl$endpoint');
      return await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );
    } catch (e) {
      throw ApiException('Network connection failed. Please check your internet connection.');
    }
  }

  static Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl$endpoint');
      return await http.put(
        url,
        headers: headers,
        body: jsonEncode(body),
      );
    } catch (e) {
      throw ApiException('Network connection failed. Please check your internet connection.');
    }
  }

  static Future<http.Response> delete(String endpoint) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl$endpoint');
      return await http.delete(
        url,
        headers: headers,
      );
    } catch (e) {
      throw ApiException('Network connection failed. Please check your internet connection.');
    }
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}
