import 'package:flutter/material.dart';
import 'package:app/widgets/app_scaffold.dart';

class ListarUsuariosPage extends StatelessWidget {
  const ListarUsuariosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Usuários',
      child: Center(
        child: Text(
          'Listar Usuários Page',
          style: TextStyle(fontSize: 24, color: Colors.white),
        ),
      ),
    );
  }
}