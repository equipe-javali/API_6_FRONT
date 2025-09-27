import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final String baseUrl = 'http://127.0.0.1:8000';

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: 'username=$username&password=$password',
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Salvar token
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', data['access_token']);      
      return data;
    } else {
      throw Exception('Falha no login');
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');    
    return token;
  }
}