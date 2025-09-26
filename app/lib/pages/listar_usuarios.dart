import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:app/widgets/app_scaffold.dart';
import 'package:go_router/go_router.dart';

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

  Future<List<Usuario>> listarUsuarios() async {
    final url = Uri.parse('http://localhost:8000/users');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> lista = data;
      return lista.map((json) => Usuario.fromJson(json)).toList();
    } else {
      throw Exception('Erro ao carregar usuários: ${response.statusCode}');
    }
  }

  void _onAdicionar() {
    context.push('/cadastrar/usuario');
  }

  void _onExcluir() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ação "Excluir" ainda não implementada')),
    );
  }

  final color1 = const Color(0xFF23232C);
  final color2 = const Color(0xFF7968D8);
  final colorError = const Color(0xFFFF5252);
  final fontSize = 20.0;

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
                        flex: 6,
                        child: Text(
                          'Usuários',
                          style: TextStyle(
                            color: color2,
                            fontSize: fontSize,
                          ),
                        ),
                      ),
                      Flexible(
                        flex: 4,
                        child: OutlinedButton(
                          onPressed: _onAdicionar,
                          child: Text('Adicionar',
                              style: TextStyle(
                                color: color2,
                                fontSize: fontSize,
                              )),
                        ),
                      ),
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
                Flex(
                  direction: Axis.horizontal,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      flex: 6,
                      child: Text(
                        'Usuários',
                        style: TextStyle(
                          color: color2,
                          fontSize: fontSize,
                        ),
                      ),
                    ),
                    Flexible(
                      flex: 4,
                      child: OutlinedButton(
                        onPressed: _onAdicionar,
                        child: Text('Adicionar',
                            style: TextStyle(
                              color: color2,
                              fontSize: fontSize,
                            )),
                      ),
                    ),
                  ],
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
                                color: color1,
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
                                  color: color1,
                                  border: Border.all(color: color2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.email,
                                          color: color2,
                                          size: 20,
                                        ),
                                        Checkbox(
                                          value: _usuarios[index].recebe,
                                          onChanged: null,
                                          fillColor:
                                              WidgetStateProperty.all(color2),
                                        ),
                                      ],
                                    ),
                                    OutlinedButton(
                                      onPressed: _onExcluir,
                                      style: OutlinedButton.styleFrom(
                                        backgroundColor: color1,
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
