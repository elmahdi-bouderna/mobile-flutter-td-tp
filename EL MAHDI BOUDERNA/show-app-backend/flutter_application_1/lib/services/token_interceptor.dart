// Create a HTTP interceptor to add token to all requests
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class TokenInterceptor {
  static Future<http.Response> get(Uri url) async {
    final headers = await AuthService.getAuthHeaders();
    return http.get(url, headers: headers);
  }
  
  static Future<http.Response> delete(Uri url) async {
    final headers = await AuthService.getAuthHeaders();
    return http.delete(url, headers: headers);
  }
  
  static Future<http.Response> post(Uri url, {required Map<String, dynamic> body}) async {
    final headers = await AuthService.getAuthHeaders();
    return http.post(url, headers: headers, body: body);
  }
  
  static Future<http.Response> put(Uri url, {required Map<String, dynamic> body}) async {
    final headers = await AuthService.getAuthHeaders();
    return http.put(url, headers: headers, body: body);
  }
}