import 'package:flutter/material.dart';
import 'package:app/widgets/app_scaffold.dart';

class CadastrarUsuarioPage extends StatelessWidget {
  const CadastrarUsuarioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Cadastrar Usuário',
      child: Center(
        child: Text(
          'Cadastrar Usuário Page',
          style: TextStyle(fontSize: 24, color: Colors.white),
        ),
      ),
    );
  }
}