import 'package:flutter/material.dart';
import 'package:app/widgets/app_scaffold.dart';
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

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _adicionarUsuario() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await http.post(
          Uri.parse('http://127.0.0.1:8000/users/usuario'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'email': _emailController.text.trim(),
            'senha': _senhaController.text,
            'recebe_boletim': _receberRelatorio,
          }),
        );

        final data = json.decode(response.body);

        if (!mounted) return;
        if (response.statusCode == 200 && data['success'] == true) {
          // Sucesso - mostrar mensagem e limpar campos
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(data['message'] ?? 'Usuário cadastrado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );

          // Limpar os campos
          _nomeController.clear();
          _emailController.clear();
          _senhaController.clear();
          setState(() {
            _receberRelatorio = false;
          });
        } else {
          // Erro - mostrar mensagem de erro
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
    return AppScaffold(
      title: 'Criar Usuário',
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                          validator: (value) => value == null || value.isEmpty
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
                            validator: (value) => value == null || value.isEmpty
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Receber relatório',
                                style: TextStyle(color: Color(0xFF9B8DF7))),
                            const SizedBox(width: 8),
                            Switch(
                              value: _receberRelatorio,
                              activeColor: const Color(0xFF9B8DF7),
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
                          width: 487,
                          child: TextFormField(
                            controller: _senhaController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Senha',
                            ),
                            validator: _validatePassword,
                          ),
                        ),
                        const SizedBox(width: 32),
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Row(
                            children: [
                              const Text('Receber relatório',
                                  style: TextStyle(color: Color(0xFF9B8DF7))),
                              const SizedBox(width: 8),
                              Switch(
                                value: _receberRelatorio,
                                activeColor: const Color(0xFF9B8DF7),
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
              const SizedBox(height: 24),
              SizedBox(
                width: 210,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _adicionarUsuario,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
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
