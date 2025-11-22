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
  List<String> _tipos = ["Administrador", "Padrão"];
  String? _tipoUsuario = "Padrão";

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
            _tipos = tipos.isNotEmpty ? tipos : ['Não encontrado'];
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
      setState(() {
        _tipos = ['Não encontrado'];
        _tipoUsuario = _tipos.first;
      });
    }
  }

  Future<void> _adicionarUsuario() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final response = await http.post(
          Uri.parse('http://127.0.0.1:8000/users/usuario'),
          headers: {'Content-Type': 'application/json'},
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
        setState(() => _isLoading = false);
      }
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Informe o email';
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!regex.hasMatch(value)) return 'Email inválido';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Informe a senha';
    if (value.length < 6) return 'A senha deve ter pelo menos 6 caracteres';
    return null;
  }

  static const branco = Color(0xFFFFFFFF);
  static const roxo = Color(0xFF9B8DF7);
  static const roxo2 = Color(0xFF7968D8);

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(labelText: label),
      validator: validator,
    );
  }

  bool _isMobile(BoxConstraints constraints) => constraints.maxWidth < 600;

  Widget _buildNomeEmailFields(bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          _buildTextField(
            controller: _nomeController,
            label: 'Nome',
            validator: (value) =>
                value == null || value.isEmpty ? 'Informe o nome' : null,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            validator: _validateEmail,
          ),
        ],
      );
    } else {
      return SizedBox(
        width: double.infinity,
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.spaceAround,
          children: [
            SizedBox(
              width: 300,
              child: _buildTextField(
                controller: _nomeController,
                label: 'Nome',
                validator: (value) =>
                    value == null || value.isEmpty ? 'Informe o nome' : null,
              ),
            ),
            SizedBox(
              width: 300,
              child: _buildTextField(
                controller: _emailController,
                label: 'Email',
                validator: _validateEmail,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildTipoDropdown() {
    return DropdownButtonFormField<String>(
      value: _tipoUsuario,
      decoration: const InputDecoration(labelText: 'Tipo de Usuário'),
      items: _tipos
          .map((tipo) => DropdownMenuItem(value: tipo, child: Text(tipo)))
          .toList(),
      onChanged: (value) {
        setState(() {
          _tipoUsuario = value;
        });
      },
    );
  }

  Widget _buildSenhaTipoRelatorioFields(bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          _buildTextField(
            controller: _senhaController,
            label: 'Senha',
            obscureText: true,
            validator: _validatePassword,
          ),
          const SizedBox(height: 16),
          _buildTipoDropdown(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Receber relatório', style: TextStyle(color: roxo)),
              Switch(
                value: _receberRelatorio,
                activeColor: roxo,
                onChanged: _isLoading
                    ? null
                    : (value) => setState(() => _receberRelatorio = value),
              ),
            ],
          ),
        ],
      );
    } else {
      return SizedBox(
        width: double.infinity,
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.spaceAround,
          children: [
            SizedBox(
              width: 300,
              child: _buildTextField(
                controller: _senhaController,
                label: 'Senha',
                obscureText: true,
                validator: _validatePassword,
              ),
            ),
            SizedBox(
              width: 300,
              child: _buildTipoDropdown(),
            ),
            SizedBox(
              width: 260,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Receber relatório',
                      style: TextStyle(color: roxo)),
                  Switch(
                    value: _receberRelatorio,
                    activeColor: roxo,
                    onChanged: _isLoading
                        ? null
                        : (value) => setState(() => _receberRelatorio = value),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildSubmitButton(bool isMobile) {
    return SizedBox(
      width: isMobile ? double.infinity : 220,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _adicionarUsuario,
        style: ElevatedButton.styleFrom(
          backgroundColor: roxo2,
          foregroundColor: branco,
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        child: _isLoading
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: branco,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Processando...'),
                ],
              )
            : const Text('Adicionar'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = _isMobile(constraints);
        final adaptivePadding =
            isMobile ? const EdgeInsets.all(12) : const EdgeInsets.all(24.0);

        return AppScaffold(
          title: 'Criar Usuário',
          child: Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              padding: adaptivePadding,
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildNomeEmailFields(isMobile),
                    const SizedBox(height: 16),
                    _buildSenhaTipoRelatorioFields(isMobile),
                    const SizedBox(height: 28),
                    _buildSubmitButton(isMobile),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
