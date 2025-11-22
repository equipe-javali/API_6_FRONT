import 'package:flutter/material.dart';
import 'package:app/widgets/app_scaffold.dart';
import 'package:app/services/auth_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CadastrarUsuarioPage extends StatefulWidget {
  const CadastrarUsuarioPage({super.key});

  @override
  State<CadastrarUsuarioPage> createState() => _CadastrarUsuarioPageState();
}

class _CadastrarUsuarioPageState extends State<CadastrarUsuarioPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _receberRelatorio = false;
  bool _isLoading = false;

  final AuthService _authService = AuthService();
  int? _userId;
  List<String> _tipos = [];
  String? _tipoUsuario;

  @override
  void initState() {
    super.initState();
    _carregarTiposUsuario();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _carregarTiposUsuario() async {
    try {
      final token = await _authService.getToken();
      if (token == null) return;

      final urlUser = Uri.parse('${_authService.baseUrl}/users/me/');
      final respUser = await http.get(urlUser, headers: {
        'Authorization': 'Bearer $token',
      });

      if (respUser.statusCode == 200) {
        final dataUser = jsonDecode(respUser.body);
        _userId = dataUser['id'];

        final urlTipo =
            Uri.parse('${_authService.baseUrl}/users/tipo/$_userId');
        final respTipo = await http.get(urlTipo, headers: {
          'Authorization': 'Bearer $token',
        });

        if (respTipo.statusCode == 200) {
          final body = jsonDecode(respTipo.body);
          final tipos = (body is List)
              ? List<String>.from(body)
              : (body is String && body.isNotEmpty)
                  ? [body]
                  : <String>[];

          setState(() {
            _tipos = tipos.isNotEmpty
                ? tipos
                : ['Não encontrado'];
            _tipoUsuario = _tipos.first;
          });
        } else {
          setState(() {
            _tipos = ['Não encontrado'];
            _tipoUsuario = _tipos.first;
          });
        }
      }
    } catch (e) {
      print('Erro ao carregar tipos: $e');
      setState(() {
        _tipos = ['Não encontrado'];
        _tipoUsuario = _tipos.first;
      });
    }
  }

  Future<void> _adicionarUsuario() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await http.post(
          Uri.parse('https://44-208-237-146.nip.io/users/usuario'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'nome': _nomeController.text.trim(),
            'email': _emailController.text.trim(),
            'senha': _senhaController.text,
            'recebe_boletim': _receberRelatorio,
            'tipo': _tipoUsuario,
          }),
        );

        final data = json.decode(response.body);

        if (!mounted) return;
        if (response.statusCode == 200 && data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(data['message'] ?? 'Usuário cadastrado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );

          _nomeController.clear();
          _emailController.clear();
          _senhaController.clear();
          setState(() {
            _receberRelatorio = false;
            _tipoUsuario = _tipos.isNotEmpty
                ? _tipos.first
                : 'Nenhum tipo de usuário encontrado';
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ??
                  data['detail'] ??
                  'Erro ao cadastrar usuário'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro de conexão: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Informe o email';
    }
    if (!value.contains('@') || !value.contains('.')) {
      return 'Informe um email válido';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Informe a senha';
    }
    if (value.length < 6) {
      return 'A senha deve ter pelo menos 6 caracteres';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    const roxo = Color(0xFF9B8DF7);

    return AppScaffold(
      title: 'Criar Usuário',
      child: SingleChildScrollView( // ✅ evita overflow
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  bool isMobile = constraints.maxWidth < 600;

                  if (isMobile) {
                    return Column(
                      children: [
                        TextFormField(
                          controller: _nomeController,
                          decoration: const InputDecoration(
                            labelText: 'Nome',
                          ),
                          validator: (value) =>
                              value == null || value.isEmpty
                                  ? 'Informe o nome'
                                  : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                          ),
                          validator: _validateEmail,
                        ),
                      ],
                    );
                  } else {
                    return Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _nomeController,
                            decoration: const InputDecoration(
                              labelText: 'Nome',
                            ),
                            validator: (value) =>
                                value == null || value.isEmpty
                                    ? 'Informe o nome'
                                    : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                            ),
                            validator: _validateEmail,
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),

              const SizedBox(height: 16),

              LayoutBuilder(
                builder: (context, constraints) {
                  bool isMobile = constraints.maxWidth < 600;

                  final tipoDropdown = DropdownButtonFormField<String>(
                    value: _tipoUsuario,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de Usuário',
                    ),
                    items: _tipos
                        .map((tipo) => DropdownMenuItem(
                              value: tipo,
                              child: Text(tipo),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _tipoUsuario = value!;
                      });
                    },
                  );

                  if (isMobile) {
                    return Column(
                      children: [
                        TextFormField(
                          controller: _senhaController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Senha',
                          ),
                          validator: _validatePassword,
                        ),
                        const SizedBox(height: 16),
                        tipoDropdown,
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Receber relatório',
                              style: TextStyle(color: roxo),
                            ),
                            const SizedBox(width: 8),
                            Switch(
                              value: _receberRelatorio,
                              activeColor: roxo,
                              onChanged: _isLoading
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _receberRelatorio = value;
                                      });
                                    },
                            ),
                          ],
                        ),
                      ],
                    );
                  } else {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 300,
                          child: TextFormField(
                            controller: _senhaController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Senha',
                            ),
                            validator: _validatePassword,
                          ),
                        ),
                        const SizedBox(width: 24),
                        SizedBox(width: 250, child: tipoDropdown),
                        const SizedBox(width: 24),
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Row(
                            children: [
                              const Text(
                                'Receber relatório',
                                style: TextStyle(color: roxo),
                              ),
                              const SizedBox(width: 8),
                              Switch(
                                value: _receberRelatorio,
                                activeColor: roxo,
                                onChanged: _isLoading
                                    ? null
                                    : (value) {
                                        setState(() {
                                          _receberRelatorio = value;
                                        });
                                      },
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: 220,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _adicionarUsuario,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7968D8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
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
                      : const Text('Adicionar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
