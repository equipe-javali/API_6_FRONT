import 'package:flutter/material.dart';
import 'package:app/widgets/app_scaffold.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Chat',
      child: Center(
        child: Text(
          'Chat Page',
          style: TextStyle(fontSize: 24, color: Colors.white),
        ),
      ),
    );
  }
}

  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Chat Page',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
