import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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

    final token = await authService.login(
      emailController.text,
      passwordController.text,
    );

    setState(() => isLoading = false);

    if (!mounted) return;

    if (token != null) {
      context.go('/usuarios');
    } else {
      setState(() {
        errorMessage = "Usuário ou senha inválidos";
      });
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

        // ✅ LINK "ESQUECI MINHA SENHA"
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
