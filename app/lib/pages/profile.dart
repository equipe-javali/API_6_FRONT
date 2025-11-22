import 'package:flutter/material.dart';
import 'package:app/widgets/app_scaffold.dart';
import 'package:app/services/auth_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _receberRelatorio = false;

  bool _isLoading = false;
  bool _isLoadingUser = true;

  final AuthService _authService = AuthService();
  int? _userId;

  @override
  void initState() {
    super.initState();
    _carregarDadosUsuario();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _carregarDadosUsuario() async {
    try {
      final token = await _authService.getToken();
      if (token == null) return;

      final url = Uri.parse("${_authService.baseUrl}/users/me/");
      final resp = await http.get(url, headers: {
        "Authorization": "Bearer $token",
      });

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);

        setState(() {
          _userId = data["id"];  // ✔ sempre o usuário autenticado
          _nomeController.text = data["nome"] ?? "";
          _emailController.text = data["email"] ?? "";
          _receberRelatorio = data["recebe_boletim"] ?? false;
          _isLoadingUser = false;
        });
      } else {
        setState(() => _isLoadingUser = false);
      }
    } catch (e) {
      setState(() => _isLoadingUser = false);
    }
  }

  Future<void> _editarUsuario() async {
    if (!_formKey.currentState!.validate()) return;
    if (_userId == null) return;

    setState(() => _isLoading = true);

    try {
      final token = await _authService.getToken();
      if (token == null) return;

      final url =
          Uri.parse("${_authService.baseUrl}/users/$_userId/profile");

      final Map<String, dynamic> body = {
        "email": _emailController.text.trim(),
        "recebe_boletim": _receberRelatorio,
      };

      if (_senhaController.text.isNotEmpty) {
        body["senha"] = _senhaController.text;
      }

      final resp = await http.put(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );

      if (!mounted) return;

      if (resp.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Perfil atualizado com sucesso!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final data = jsonDecode(resp.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data["detail"] ?? "Erro ao atualizar"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro de conexão: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return "Informe o email";
    if (!value.contains('@') || !value.contains('.')) {
      return "Email inválido";
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    const roxo = Color(0xFF9B8DF7);

    if (_isLoadingUser) {
      return const AppScaffold(
        title: "Perfil",
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return AppScaffold(
      title: "Perfil",
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nomeController,
                readOnly: true,
                decoration: const InputDecoration(labelText: "Nome"),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email"),
                validator: _validateEmail,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _senhaController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Nova senha (opcional)",
                ),
              ),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Receber boletim",
                      style: TextStyle(color: roxo)),
                  const SizedBox(width: 12),
                  Switch(
                    value: _receberRelatorio,
                    activeColor: roxo,
                    onChanged: (v) {
                      setState(() => _receberRelatorio = v);
                    },
                  )
                ],
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: 220,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _editarUsuario,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7968D8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text("Salvar alterações"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
