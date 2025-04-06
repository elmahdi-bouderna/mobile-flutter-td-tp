import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';

  // Simuler une authentification - normalement, cela devrait être implémenté côté serveur
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    // Simulons une authentification - Pour le PoC, nous accepterons admin@example.com/admin123
    if (email == 'admin@example.com' && password == 'admin123') {
      // Simulons une réponse d'API - dans un cas réel, cela viendrait du backend
      final token =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6MSwiaWF0IjoxNjE3MjgxODIyfQ.example';
      await _storage.write(key: _tokenKey, value: token);

      return {
        'success': true,
        'token': token,
        'user': {'id': 1, 'email': email, 'name': 'Admin User'}
      };
    } else {
      return {'success': false, 'message': 'Identifiants invalides'};
    }
  }

  static Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: _tokenKey);
    return token != null;
  }

  static Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }
}
