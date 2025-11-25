import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:app/app/theme.dart';
import 'package:app/widgets/app_scaffold.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/services/auth_service.dart';


class Usuario {
  final int id;
  final String email;
  final bool recebe;
  final bool admin;

  Usuario(
      {required this.id,
      required this.email,
      required this.recebe,
      required this.admin});

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
        id: json['id'],
        email: json['email'],
        recebe: json['recebe_boletim'],
        admin: json['admin']);
  }
}

final AuthService _authService = AuthService();

class ListarUsuariosPage extends StatefulWidget {
  const ListarUsuariosPage({super.key});

  @override
  State<ListarUsuariosPage> createState() => _ListarUsuariosPageState();
}

class _ListarUsuariosPageState extends State<ListarUsuariosPage> {
  late Future<List<Usuario>> _usuariosFuture;
  List<Usuario> _usuarios = [];
  bool isSendingReport = false;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadAdmin();
    _usuariosFuture = listarUsuarios();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<void> _loadAdmin() async {
  final prefs = await SharedPreferences.getInstance();
  setState(() {
    _isAdmin = prefs.getBool('is_admin') ?? false;
  });
}

  Future<List<Usuario>> listarUsuarios({int skip = 0, int limit = 20}) async {
    final url =
        Uri.parse('${_authService.baseUrl}/users/?skip=$skip&limit=$limit');

    final token = await _getToken();

    final response = await http.get(
      url,
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
       
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> lista = data;
      return lista.map((json) => Usuario.fromJson(json)).toList();
    } else {
      throw Exception('Erro ao carregar usuários: ${response.statusCode}');
    }
  }

  Future<void> _excluirUsuario(int userId) async {
    final token = await _getToken();
    if (!mounted) return;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Token não encontrado. Faça login novamente.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.neutralWhite,
                ),
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final url = Uri.parse('${_authService.baseUrl}/users/$userId');
    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (!mounted) return;
    if (response.statusCode == 200) {
      setState(() {
        _usuarios.removeWhere((usuario) => usuario.id == userId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Usuário excluído com sucesso',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.neutralWhite,
                ),
          ),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erro ao excluir usuário: ${response.statusCode}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.neutralWhite,
                ),
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }


  Future<void> _enviarRelatorio() async {
    setState(() => isSendingReport = true);

    try {
      final token = await _getToken();
      if (!mounted) return;
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Token não encontrado. Faça login novamente.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.neutralWhite,
                  ),
            ),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }

      final url = Uri.parse('${_authService.baseUrl}/enviar-relatorio');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          
        },
      );


      if (!mounted) return;
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Relatório enviado com sucesso!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.neutralWhite,
                  ),
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro ao enviar relatório: ${response.statusCode}',
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
            'Erro: $e',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.neutralWhite,
                ),
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setState(() => isSendingReport = false);
    }
  }

  void _onExcluir(int userId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: const Text('Tem certeza que deseja excluir este usuário?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _excluirUsuario(userId);
              },
              child: const Text(
                'Excluir',
                style: TextStyle(color: AppTheme.errorColor),
              ),
            ),
          ],
        );
      },
    );
  }

  void _onAdicionar() {
    context.go('/cadastrar/usuario');
  }

  Future<void> _atualizarStatusBoletim(int userId, bool novoStatus) async {
    final token = await _getToken();
    if (!mounted) return;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Token não encontrado. Faça login novamente.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.neutralWhite,
                ),
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final url = Uri.parse('${_authService.baseUrl}/users/$userId/status');
    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'recebe_boletim': novoStatus}),
    );
    if (!mounted) return;
    if (response.statusCode == 200) {
      setState(() {
        final index = _usuarios.indexWhere((u) => u.id == userId);
        if (index != -1) {
          _usuarios[index] = Usuario(
              id: _usuarios[index].id,
              email: _usuarios[index].email,
              recebe: novoStatus,
              admin: _usuarios[index].admin);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Boletim ${novoStatus ? "ativado" : "desativado"} para o usuário.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.neutralWhite,
                ),
          ),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erro ao atualizar status: ${response.statusCode}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.neutralWhite,
                ),
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _atualizarTipoUsuario(int userId, bool novoTipo) async {
    final token = await _getToken();
    if (!mounted) return;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Token não encontrado. Faça login novamente.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.neutralWhite,
                ),
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final url = Uri.parse('${_authService.baseUrl}/users/$userId/admin');
    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'admin': novoTipo}),
    );

    if (!mounted) return;
    if (response.statusCode == 200) {
      setState(() {
        final index = _usuarios.indexWhere((u) => u.id == userId);
        if (index != -1) {
          _usuarios[index] = Usuario(
            id: _usuarios[index].id,
            email: _usuarios[index].email,
            recebe: _usuarios[index].recebe,
            admin: novoTipo,
          );
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tipo de usuário ${novoTipo ? "Administrador" : "Padrão"} atualizado.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.neutralWhite,
                ),
          ),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erro ao atualizar tipo: ${response.statusCode}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.neutralWhite,
                ),
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _onBoletim(Usuario usuario) {
    final novoStatus = !usuario.recebe;
    _atualizarStatusBoletim(usuario.id, novoStatus);
  }

  Widget _buildBoletimButton(ThemeData theme, Usuario usuario) {
    return OutlinedButton(
      onPressed: () => _onBoletim(usuario),
      style: OutlinedButton.styleFrom(
        backgroundColor: theme.colorScheme.surface,
        side: BorderSide(
          color: usuario.recebe
              ? AppTheme.successColor
              : theme.colorScheme.secondary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        foregroundColor: usuario.recebe
            ? AppTheme.successColor
            : theme.colorScheme.secondary,
        minimumSize: const Size(48, 48),
        padding: EdgeInsets.zero,
      ),
      child: Icon(
        Icons.email,
        color: usuario.recebe
            ? AppTheme.successColor
            : theme.colorScheme.secondary,
        size: 20,
      ),
    );
  }

  Widget _buildAdminButton(ThemeData theme, Usuario usuario) {
    return OutlinedButton(
      onPressed: () => _atualizarTipoUsuario(usuario.id, !usuario.admin),
      style: OutlinedButton.styleFrom(
        backgroundColor: theme.colorScheme.surface,
        side: BorderSide(
          color: usuario.admin
              ? AppTheme.successColor
              : theme.colorScheme.secondary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        foregroundColor:
            usuario.admin ? AppTheme.successColor : theme.colorScheme.secondary,
        minimumSize: const Size(48, 48),
        padding: EdgeInsets.zero,
      ),
      child: Icon(
        Icons.security,
        color:
            usuario.admin ? AppTheme.successColor : theme.colorScheme.secondary,
        size: 20,
      ),
    );
  }

  Widget _buildExcluirButton(ThemeData theme, Usuario usuario) {
    return OutlinedButton(
      onPressed: () => _onExcluir(usuario.id),
      style: OutlinedButton.styleFrom(
        backgroundColor: theme.colorScheme.surface,
        side: const BorderSide(color: AppTheme.errorColor),
        foregroundColor: AppTheme.errorColor,
        minimumSize: const Size(48, 48),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: const Icon(Icons.delete, size: 20),
    );
  }

  Widget _buildHeaderActions(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: [
          Text(
            'Usuários',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          Wrap(
            spacing: 10,
            children: [
              OutlinedButton(
                onPressed: isSendingReport ? null : _enviarRelatorio,
                style: OutlinedButton.styleFrom(
                  backgroundColor: theme.colorScheme.surface,
                  side: BorderSide(color: theme.colorScheme.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  foregroundColor: theme.colorScheme.primary,
                  padding: const EdgeInsets.all(16),
                ),
                child: isSendingReport
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.primary,
                        ),
                      )
                    : Text(
                        'Enviar relatório',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
              ),
              OutlinedButton(
                onPressed: _onAdicionar,
                style: OutlinedButton.styleFrom(
                  backgroundColor: theme.colorScheme.surface,
                  side: BorderSide(color: theme.colorScheme.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  foregroundColor: theme.colorScheme.primary,
                  padding: const EdgeInsets.all(16),
                ),
                child: Text(
                  'Adicionar',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsuarioItem(BuildContext context, Usuario usuario) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        if (isMobile) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border.all(color: theme.colorScheme.primary),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  usuario.email,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _buildBoletimButton(theme, usuario),
                    const SizedBox(width: 8),
                    _buildAdminButton(theme, usuario),
                    const SizedBox(width: 8),
                    _buildExcluirButton(theme, usuario),
                  ],
                ),
              ],
            ),
          );
        } else {
          return Row(
            children: [
              Flexible(
                flex: 5,
                child: Container(
                  alignment: Alignment.centerLeft,
                  height: 75,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border.all(color: theme.colorScheme.primary),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    usuario.email,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                flex: 2,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 150),
                  child: Container(
                    alignment: Alignment.center,
                    height: 75,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      border: Border.all(color: theme.colorScheme.primary),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildBoletimButton(theme, usuario),
                        _buildAdminButton(theme, usuario),
                        _buildExcluirButton(theme, usuario),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildUsuarioList(BuildContext context) {
    return Expanded(
      child: NotificationListener<ScrollNotification>(
        onNotification: (scrollInfo) {
          if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
            _carregarMaisUsuarios();
          }
          return false;
        },
        child: ListView.separated(
          itemBuilder: (context, index) =>
              _buildUsuarioItem(context, _usuarios[index]),
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemCount: _usuarios.length,
        ),
      ),
    );
  }
    
  Future<void> _carregarMaisUsuarios() async {
    final novosUsuarios = await listarUsuarios(
      skip: _usuarios.length,
      limit: 20,
    );
    setState(() {
      // Adiciona apenas usuários que ainda não estão na lista
      for (final usuario in novosUsuarios) {
        if (!_usuarios.any((u) => u.id == usuario.id)) {
          _usuarios.add(usuario);
        }
      }
    });
  }
  // ...existing code...
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: '',
      child: FutureBuilder<List<Usuario>>(
        future: _usuariosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildHeaderActions(context),
                  const SizedBox(height: 20),
                  Text(
                    'Erro: ${snapshot.error}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.errorColor,
                    ),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasData) {
            _usuarios = snapshot.data!;
          }

          return Container(
            color: theme.colorScheme.surface,
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            height: double.infinity,
            child: Column(
              children: [
                _buildHeaderActions(context),
                const SizedBox(height: 20),
                _buildUsuarioList(context),
              ],
            ),
          );
        },
      ),
    );
  }
}
