import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:app/app/theme.dart';


class RecuperarSenhaPage extends StatefulWidget {
  const RecuperarSenhaPage({super.key});

  @override
  State<RecuperarSenhaPage> createState() => _RecuperarSenhaPageState();
}

class _RecuperarSenhaPageState extends State<RecuperarSenhaPage> {
  final emailController = TextEditingController();
  bool isLoading = false;
  String? errorMessage;

  Future<void> _recuperarSenha() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/password/recover'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': emailController.text.trim()}),
      );

      setState(() => isLoading = false);

      if (!mounted) return;

      if (response.statusCode == 200) {
        // Limpar campo após sucesso
        emailController.clear();

        // Opcional: mostrar diálogo de sucesso
        _showSuccessDialog();
      } else {
        final data = jsonDecode(response.body);
        setState(() {
          errorMessage = data['detail'] ?? 'Erro ao recuperar senha';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Erro de conexão. Verifique sua internet.';
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppTheme.primaryColor, width: 1),
        ),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF52FF52)),
            const SizedBox(width: 10),
            Text(
              'Sucesso!',
              style: GoogleFonts.comfortaa(color: Colors.white),
            ),
          ],
        ),
        content: Text(
          'Uma nova senha foi enviada para seu e-mail.\n\nPor favor, verifique sua caixa de entrada e spam.',
          style: GoogleFonts.comfortaa(color: Colors.white70),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop(); // Fecha o diálogo
              context.go('/login'); // Volta para a tela de login
            },
            child: Text(
              'OK',
              style: GoogleFonts.comfortaa(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: AppTheme.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
      ),
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.lock_reset,
          color: AppTheme.primaryColor,
          size: isMobile ? 60 : 72,
        ),
        const SizedBox(height: 20),

        Text(
          'Recuperar Senha',
          textAlign: TextAlign.center,
          style: GoogleFonts.comfortaa(
            color: AppTheme.primaryColor,
            fontSize: isMobile ? 24 : 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),

        Text(
          'Informe seu e-mail cadastrado para receber uma nova senha temporária',
          textAlign: TextAlign.center,
          style: GoogleFonts.comfortaa(
            color: Colors.white70,
            fontSize: isMobile ? 13 : 14,
          ),
        ),
        const SizedBox(height: 40),

        // EMAIL
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration("E-mail", Icons.mail_outline),
        ),
        const SizedBox(height: 30),

        // BOTÃO RECUPERAR
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : _recuperarSenha,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    "Recuperar Senha",
                    style: GoogleFonts.comfortaa(
                      color: Colors.white,
                      fontSize: isMobile ? 15 : 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),

        // MENSAGEM DE ERRO
        if (errorMessage != null) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              border: Border.all(color: Colors.red),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    errorMessage!,
                    style: GoogleFonts.comfortaa(
                      color: Colors.red,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 20),

        // VOLTAR PARA LOGIN
        TextButton(
          onPressed: () => context.go('/login'),
          child: Text(
            'Voltar para o Login',
            style: GoogleFonts.comfortaa(
              color:  AppTheme.primaryColor,
              fontSize: isMobile ? 14 : 15,
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color:  AppTheme.primaryColor),
      labelText: label,
      labelStyle: GoogleFonts.comfortaa(color:  AppTheme.primaryColor),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppTheme.primaryColor),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
