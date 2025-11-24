import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final authService = AuthService();

  bool isLoading = false;
  String? errorMessage;

  Future<void> _login() async {
  setState(() {
    isLoading = true;
    errorMessage = null;
  });

  try {
    final loginResult = await authService.login(
      emailController.text.trim(),
      passwordController.text.trim(),
    );

    if (loginResult == null) {
      throw Exception("Usuário ou senha inválidos");
    }

    final token = loginResult["access_token"];

    // Agora usa o método certo
    final response = await authService.authenticatedGet("/users/me");

    if (response.statusCode != 200) {
      throw Exception("Erro ao obter dados do usuário");
    }

    final data = jsonDecode(response.body);
    print("JSON RECEBIDO DO BACK: $data");

    final rawAdmin = data["admin"] ?? data["is_admin"];
    print("VALOR RECEBIDO DO BACK PARA ADMIN: $rawAdmin");

    final isAdmin =
    rawAdmin is bool ? rawAdmin :
    rawAdmin is String ? rawAdmin.toLowerCase() == "true" :
    rawAdmin is int ? rawAdmin == 1 :
    false;

    print("VALOR ISADMIN: $isAdmin");

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("is_admin", isAdmin);

    if (!mounted) return;

    if (isAdmin) {
      context.go("/usuarios");
    } else {
      context.go("/chat");
    }

  } catch (e) {
    setState(() => errorMessage = e.toString());
  } finally {
    if (mounted) {
      setState(() => isLoading = false);
    }
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;

          return Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 24 : 40,
                vertical: isMobile ? 20 : 40,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isMobile ? 360 : 420,
                ),
                child: _buildForm(isMobile),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildForm(bool isMobile) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.auto_awesome,
          color: const Color(0xFF9C7BFF),
          size: isMobile ? 60 : 72,
        ),
        const SizedBox(height: 40),

        // EMAIL
        TextField(
          controller: emailController,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration("Email", Icons.mail_outline),
        ),
        const SizedBox(height: 16),

        // SENHA
        TextField(
          controller: passwordController,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration("Senha", Icons.vpn_key),
        ),
        const SizedBox(height: 10),

        // LINK "ESQUECI MINHA SENHA"
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => context.go('/recuperar-senha'),
            child: Text(
              'Esqueci minha senha',
              style: GoogleFonts.comfortaa(
                color: const Color(0xFF9C7BFF),
                fontSize: isMobile ? 13 : 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // BOTÃO ENTRAR
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : _login,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9C7BFF),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    "Entrar",
                    style: GoogleFonts.comfortaa(
                      color: Colors.white,
                      fontSize: isMobile ? 15 : 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),

        if (errorMessage != null) ...[
          const SizedBox(height: 16),
          Text(
            errorMessage!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: const Color(0xFF9C7BFF)),
      labelText: label,
      labelStyle: GoogleFonts.comfortaa(color: const Color(0xFF9C7BFF)),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFF9C7BFF)),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFF9C7BFF), width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
