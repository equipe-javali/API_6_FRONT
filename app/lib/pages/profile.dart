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
          _userId = data["id"]; // ✔ sempre o usuário autenticado
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

      final url = Uri.parse("${_authService.baseUrl}/users/$_userId/profile");

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(builder: (context, constraints) {
                const gap = 12.0;
                final half = (constraints.maxWidth - gap) / 2;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Linha Nome + Email ---
                    Row(
                      children: [
                        SizedBox(
                          width: half,
                          child: TextFormField(
                            controller: _nomeController,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: "Nome",
                              prefixIcon: const Icon(Icons.person),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 12),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: gap),
                        SizedBox(
                          width: half,
                          child: TextFormField(
                            controller: _emailController,
                            validator: _validateEmail,
                            decoration: InputDecoration(
                              labelText: "Email",
                              prefixIcon: const Icon(Icons.email),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 12),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // --- Linha Senha + Switch ---
                    Row(
                      children: [
                        SizedBox(
                          width: half,
                          child: TextFormField(
                            controller: _senhaController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: "Senha",
                              prefixIcon: const Icon(Icons.key),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 12),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: gap),

                        // Mantém exatamente alinhado ao lado
                        SizedBox(
                          width: half,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Text("Receber relatório",
                                  style: TextStyle(color: Color(0xFF9B8DF7))),
                              const SizedBox(width: 8),
                              Switch(
                                value: _receberRelatorio,
                                activeColor: const Color(0xFF9B8DF7),
                                onChanged: (v) =>
                                    setState(() => _receberRelatorio = v),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }),
              const SizedBox(height: 28),
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
