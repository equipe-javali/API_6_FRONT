import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final String baseUrl = "http://127.0.0.1:8000";

  /// LOGIN
  /// Agora retorna o MAP completo contendo dados do usuário
  Future<Map<String, dynamic>?> login(String username, String password) async {
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
        final user = data["user"]; // <-- precisa vir do backend!

        final normalizedUser = {
        "id": user["id"],
        "email": user["email"],
        "username": user["username"],
        "is_admin": user["is_admin"] ?? user["admin"] ?? false,
      };

        if (token == null || user == null) {
          throw Exception("Resposta da API incompleta: falta token ou user");
        }

        final prefs = await SharedPreferences.getInstance();

        // Salva token
        await prefs.setString("access_token", token);

        // Salva usuário completo (admin, id, username, email etc.)
        await prefs.setString("user", jsonEncode(normalizedUser));

        return data; // contém token + user
      } else {
        throw Exception("Erro: ${response.body}");
      }
    } catch (e) {
      throw Exception("Exceção no login: $e");
    }
  }

  /// Recupera o token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("access_token");
  }

  /// Recupera o usuário logado
  Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey("user")) return null;

    return jsonDecode(prefs.getString("user")!);
  }

  /// Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("access_token");
    await prefs.remove("user");
  }

  // ============================================================
  // 🔥 NOVO: Função automática para requisições autenticadas
  // ============================================================
  Future<http.Response> authenticatedGet(String endpoint) async {
    final token = await getToken();

    if (token == null) {
      throw Exception("Token não encontrado. Usuário não está logado.");
    }

    final url = Uri.parse("$baseUrl$endpoint");

    return await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );
  }
}
