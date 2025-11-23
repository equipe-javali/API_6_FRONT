import 'package:flutter/material.dart';
import 'package:app/app/theme.dart';
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
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _usuarioAdministrador = false;
  bool _receberRelatorio = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _adicionarUsuario() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final response = await http.post(
          Uri.parse('http://127.0.0.1:8000/users/usuario'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': _emailController.text.trim(),
            'senha': _senhaController.text,
            'recebe_boletim': _receberRelatorio,
            'admin': _usuarioAdministrador,
          }),
        );

        final data = json.decode(response.body);

        if (!mounted) return;
        if (response.statusCode == 200 && data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                data['message'] ?? 'Usuário cadastrado com sucesso!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.neutralWhite,
                    ),
              ),
              backgroundColor: AppTheme.successColor,
            ),
          );

          _emailController.clear();
          _senhaController.clear();
          setState(() {
            _receberRelatorio = false;
            _usuarioAdministrador = false;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                data['message'] ??
                    data['detail'] ??
                    'Erro ao cadastrar usuário',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.neutralWhite,
                    ),
              ),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro de conexão!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.neutralWhite,
                  ),
            ),
            backgroundColor: AppTheme.errorColor,
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

  Widget _buildSwitch({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        Switch(
          value: value,
          activeColor: theme.colorScheme.primary,
          onChanged: _isLoading ? null : onChanged,
        ),
      ],
    );
  }

  bool _isMobile(BoxConstraints constraints) => constraints.maxWidth < 600;

  Widget _buildEmailSenhaFields(bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            validator: _validateEmail,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _senhaController,
            label: 'Senha',
            obscureText: true,
            validator: _validatePassword,
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
                controller: _emailController,
                label: 'Email',
                validator: _validateEmail,
              ),
            ),
            SizedBox(
              width: 300,
              child: _buildTextField(
                controller: _senhaController,
                label: 'Senha',
                obscureText: true,
                validator: _validatePassword,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildTipoUsuarioRelatorioFields(bool isMobile) {
    if (isMobile) {
      return Column(children: [
        _buildSwitch(
          label: 'Usuário Administrador',
          value: _usuarioAdministrador,
          onChanged: (v) => setState(() => _usuarioAdministrador = v),
        ),
        const SizedBox(height: 16),
        _buildSwitch(
          label: 'Receber relatório',
          value: _receberRelatorio,
          onChanged: (v) => setState(() => _receberRelatorio = v),
        ),
      ]);
    } else {
      return SizedBox(
        width: double.infinity,
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.spaceAround,
          children: [
            SizedBox(
              width: 260,
              child: _buildSwitch(
                label: 'Usuário Administrador',
                value: _usuarioAdministrador,
                onChanged: (v) => setState(() => _usuarioAdministrador = v),
              ),
            ),
            SizedBox(
                width: 260,
                child: _buildSwitch(
                  label: 'Receber relatório',
                  value: _receberRelatorio,
                  onChanged: (v) => setState(() => _receberRelatorio = v),
                )),
          ],
        ),
      );
    }
  }

  Widget _buildSubmitButton(bool isMobile) {
    final theme = Theme.of(context);

    return SizedBox(
      width: isMobile ? double.infinity : 220,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _adicionarUsuario,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Processando...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ],
              )
            : Text(
                'Adicionar',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                ),
              ),
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
                    _buildEmailSenhaFields(isMobile),
                    const SizedBox(height: 16),
                    _buildTipoUsuarioRelatorioFields(isMobile),
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
