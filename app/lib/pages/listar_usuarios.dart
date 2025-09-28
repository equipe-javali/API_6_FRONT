import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:app/widgets/app_scaffold.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Usuario {
  final int id;
  final String email;
  final bool recebe;

  Usuario({required this.id, required this.email, required this.recebe});

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'],
      email: json['email'],
      recebe: json['recebe_boletim'],
    );
  }
}

class ListarUsuariosPage extends StatefulWidget {
  const ListarUsuariosPage({super.key});

  @override
  State<ListarUsuariosPage> createState() => _ListarUsuariosPageState();
}

class _ListarUsuariosPageState extends State<ListarUsuariosPage> {
  late Future<List<Usuario>> _usuariosFuture;
  List<Usuario> _usuarios = [];

  @override
  void initState() {
    super.initState();
    _usuariosFuture = listarUsuarios();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<List<Usuario>> listarUsuarios() async {
    final url = Uri.parse('http://127.0.0.1:8000/users');
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
        const SnackBar(
            content: Text('Token não encontrado. Faça login novamente.')),
      );
      return;
    }

    final url = Uri.parse('http://127.0.0.1:8000/users/$userId');
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
        const SnackBar(content: Text('Usuário excluído com sucesso')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erro ao excluir usuário: ${response.statusCode}')),
      );
    }
  }

  bool isSendingReport = false;

  Future<void> _enviarRelatorio() async {
    setState(() {
      isSendingReport = true;
    });

    try {
      final token = await _getToken();
      if (!mounted) return;
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Token não encontrado. Faça login novamente.')),
        );
        return;
      }

      final url = Uri.parse('http://127.0.0.1:8000/enviar-relatorio');
      final response = await http.post(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Relatório enviado com sucesso!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Erro ao enviar relatório: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    } finally {
      setState(() {
        isSendingReport = false;
      });
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
              child: Text('Excluir', style: TextStyle(color: colorError)),
            ),
          ],
        );
      },
    );
  }

  void _onAdicionar() {
    context.push('/cadastrar/usuario');
  }

  Future<void> _atualizarStatusBoletim(int userId, bool novoStatus) async {
    final token = await _getToken();
    if (!mounted) return;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Token não encontrado. Faça login novamente.')),
      );
      return;
    }

    final url = Uri.parse('http://127.0.0.1:8000/users/$userId/status');
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
          );
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Boletim ${novoStatus ? "ativado" : "desativado"} para o usuário.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erro ao atualizar status: ${response.statusCode}')),
      );
    }
  }

  void _onBoletim(Usuario usuario) {
    final novoStatus = !usuario.recebe;
    _atualizarStatusBoletim(usuario.id, novoStatus);
  }

  final color1 = const Color(0xFF23232C);
  final color2 = const Color(0xFF7968D8);
  final color3 = const Color(0xFF1F1E23);
  final color4 = const Color(0xFF5c5769);
  final color5 = const Color(0xF52FFF52);
  final colorError = const Color(0xFFFF5252);
  final fontSize = 20.00;
  @override
  Widget build(BuildContext context) {
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
                  Flex(
                    direction: Axis.horizontal,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        flex: 4,
                        child: Text(
                          'Usuários',
                          style: TextStyle(
                            color: color2,
                            fontSize: fontSize,
                          ),
                        ),
                      ),
                      Flexible(
                          flex: 6,
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton(
                                  onPressed:
                                      isSendingReport ? null : _enviarRelatorio,
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: color3,
                                    side: BorderSide(color: color2),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    foregroundColor: color2,
                                    padding: const EdgeInsets.all(16),
                                  ),
                                  child: isSendingReport
                                      ? SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: color2,
                                          ),
                                        )
                                      : Text(
                                          'Enviar relatório',
                                          style: TextStyle(
                                            color: color2,
                                            fontSize: fontSize,
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 10),
                                OutlinedButton(
                                  onPressed: _onAdicionar,
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: color3,
                                    side: BorderSide(color: color2),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    foregroundColor: color2,
                                    padding: const EdgeInsets.all(16),
                                  ),
                                  child: Text('Adicionar',
                                      style: TextStyle(
                                        color: color2,
                                        fontSize: fontSize,
                                      )),
                                ),
                              ])),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Erro: ${snapshot.error}',
                    style: TextStyle(color: colorError),
                  ),
                ],
              ),
            );
          }
          if (snapshot.hasData) {
            _usuarios = snapshot.data!;
          }

          return Container(
            color: color1,
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            height: double.infinity,
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      Text(
                        'Usuários',
                        style: TextStyle(color: color2, fontSize: fontSize),
                      ),
                      Wrap(
                        spacing: 10,
                        children: [
                          OutlinedButton(
                            onPressed:
                                isSendingReport ? null : _enviarRelatorio,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: color3,
                              side: BorderSide(color: color2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              foregroundColor: color2,
                              padding: const EdgeInsets.all(16),
                            ),
                            child: isSendingReport
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: color2,
                                    ),
                                  )
                                : Text(
                                    'Enviar relatório',
                                    style: TextStyle(
                                        color: color2, fontSize: fontSize),
                                  ),
                          ),
                          OutlinedButton(
                            onPressed: _onAdicionar,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: color3,
                              side: BorderSide(color: color2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              foregroundColor: color2,
                              padding: const EdgeInsets.all(16),
                            ),
                            child: Text(
                              'Adicionar',
                              style:
                                  TextStyle(color: color2, fontSize: fontSize),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.separated(
                    itemBuilder: (context, index) {
                      return Row(
                        children: [
                          Flexible(
                            flex: 5,
                            child: Container(
                              alignment: Alignment.centerLeft,
                              height: 75,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: color3,
                                border: Border.all(color: color2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _usuarios[index].email,
                                style: TextStyle(
                                  color: color2,
                                  fontSize: fontSize,
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
                                alignment: Alignment.centerLeft,
                                height: 75,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: color3,
                                  border: Border.all(color: color2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    OutlinedButton(
                                      onPressed: () =>
                                          _onBoletim(_usuarios[index]),
                                      style: OutlinedButton.styleFrom(
                                        backgroundColor: color3,
                                        side: BorderSide(
                                            color: _usuarios[index].recebe
                                                ? color5
                                                : color4),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        foregroundColor: _usuarios[index].recebe
                                            ? color5
                                            : color4,
                                        minimumSize: const Size(48, 48),
                                        padding: EdgeInsets.zero,
                                      ),
                                      child: Icon(
                                        Icons.email,
                                        color: _usuarios[index].recebe
                                            ? color5
                                            : color4,
                                        size: 20,
                                      ),
                                    ),
                                    OutlinedButton(
                                      onPressed: () =>
                                          _onExcluir(_usuarios[index].id),
                                      style: OutlinedButton.styleFrom(
                                        backgroundColor: color3,
                                        side: BorderSide(color: color2),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        foregroundColor: color2,
                                        minimumSize: const Size(48, 48),
                                        padding: EdgeInsets.zero,
                                      ),
                                      child: Icon(
                                        Icons.delete,
                                        color: color2,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemCount: _usuarios.length,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
