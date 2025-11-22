import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final String baseUrl = "https://task-41.d2djntt2xh1nls.amplifyapp.com";

  Future<String?> login(String username, String password) async {
    try {
      final url = Uri.parse("$baseUrl/token");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {
          "grant_type": "password",
          "username": username,
          "password": password,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data["access_token"];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("access_token", token);

        return token;
      } else {
        print("Erro: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Exceção no login: $e");
      return null;
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("access_token");
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("access_token");
  }
}
