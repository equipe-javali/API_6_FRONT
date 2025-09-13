import 'package:flutter/material.dart';
import 'package:app/widgets/app_scaffold.dart';

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

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  void _adicionarUsuario() {
    if (_formKey.currentState!.validate()) {
      // adicionar a lógica para cadastrar o usuário depois
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário cadastrado!')),
      );
    }
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
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nomeController,
                      decoration: const InputDecoration(
                        labelText: 'Nome',
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Informe o nome' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Informe o email' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              Row(
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
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Informe a senha' : null,
                    ),
                  ),
                  const SizedBox(width: 32),
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Row(
                      children: [
                        Text('Receber relatório', style: TextStyle(color: Color(0xFF9B8DF7))),
                        const SizedBox(width: 8),
                        Switch(
                          value: _receberRelatorio,
                          activeColor: Color(0xFF9B8DF7),
                          onChanged: (value) {
                            setState(() {
                              _receberRelatorio = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              SizedBox(
                width: 210,
                child: ElevatedButton(
                  onPressed: _adicionarUsuario,
                  child: const Text('Adicionar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}