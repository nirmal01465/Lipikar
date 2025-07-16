import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final String baseUrl = 'https://lipikar.cse.iitd.ac.in/api/ocr/auth';
  final storage = const FlutterSecureStorage();

  // Login method
  Future<bool> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Store tokens securely
        await storage.write(key: 'access_token', value: data['access']);
        await storage.write(key: 'refresh_token', value: data['refresh']);

        // Store user info (non-sensitive)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', username);

        // If user name was provided, store it too
        if (data.containsKey('name')) {
          await prefs.setString('name', data['name']);
        }

        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  // Logout method
  Future<void> logout() async {
    try {
      // Clear all secure tokens
      await storage.delete(key: 'access_token');
      await storage.delete(key: 'refresh_token');

      // Clear user preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      print('Logout error: $e');
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      final token = await storage.read(key: 'access_token');
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get user token
  Future<String?> getAccessToken() async {
    return await storage.read(key: 'access_token');
  }

  // Get username
  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  // Get user's full name
  Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('name');
  }

  // Token refresh
  Future<bool> refreshToken() async {
    try {
      final refreshToken = await storage.read(key: 'refresh_token');

      if (refreshToken == null) {
        return false;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/token/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refresh': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await storage.write(key: 'access_token', value: data['access']);
        return true;
      }
      return false;
    } catch (e) {
      print('Token refresh error: $e');
      return false;
    }
  }
}