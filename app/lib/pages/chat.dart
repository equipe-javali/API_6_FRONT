import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:app/widgets/app_scaffold.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:app/services/auth_service.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;
  final AuthService _authService = AuthService();
  int? _userId;

  final color1 = const Color(0xFF23232C);
  final color2 = const Color(0xFF7968D8);
  final color3 = const Color(0xFF1F1E23);
  final color4 = const Color(0xFF5c5769);
  final fontSize = 18.0;

  void _sendMessage() {
    _sendMessageToBackend();
  }

  Future<void> _sendMessageToBackend() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({
        'text': text,
        'isUser': true,
        'time': DateTime.now(),
      });
      _isTyping = true;
    });
    _controller.clear();

    try {
      final token = await _authService.getToken();
      if (token == null) {
        setState(() {
          _isTyping = false;
          _messages.add({
            'text': 'Erro: usuário não autenticado',
            'isUser': false,
            'time': DateTime.now(),
          });
        });
        return;
      }

      if (_userId == null) {
        await _loadCurrentUser(token);
        if (_userId == null) throw Exception('Não foi possível determinar id do usuário');
      }

      final url = Uri.parse('${_authService.baseUrl}/users/enviar-pergunta');
      final body = jsonEncode({
        'id_usuario': _userId,
        'mensagem': text,
        'ia': false,
      });

      final resp = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      setState(() => _isTyping = false);

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final reply = data['mensagem'] ?? 'Pergunta enviada';
        setState(() {
          _messages.add({
            'text': reply,
            'isUser': false,
            'time': DateTime.now(),
          });
        });
      } else {
        setState(() {
          _messages.add({
            'text': 'Erro ${resp.statusCode}: ${resp.body}',
            'isUser': false,
            'time': DateTime.now(),
          });
        });
      }
    } catch (e) {
      setState(() {
        _isTyping = false;
        _messages.add({
          'text': 'Exceção: $e',
          'isUser': false,
          'time': DateTime.now(),
        });
      });
    }
  }

  Future<void> _loadCurrentUser(String token) async {
    try {
      final url = Uri.parse('${_authService.baseUrl}/users/me/');
      final resp = await http.get(url, headers: {'Authorization': 'Bearer $token'});
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        setState(() {
          _userId = data['id'];
        });
      } else {
        print('Falha ao obter usuário: ${resp.statusCode} ${resp.body}');
      }
    } catch (e) {
      print('Erro ao carregar usuário: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: '',
      child: Container(
        color: color1,
        width: double.infinity,
        height: double.infinity,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 10),
              child: Center(
                child: Text(
                  'Chat',
                  style: TextStyle(
                    color: color2,
                    fontSize: fontSize + 2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg['isUser'] as bool;
                  final time = DateFormat('HH:mm').format(msg['time']);

                  return Align(
                    alignment:
                        isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 14),
                      decoration: BoxDecoration(
                        color: isUser ? color3 : const Color(0xFF2A2A35),
                        border: Border.all(color: color2.withOpacity(0.4)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      constraints: const BoxConstraints(maxWidth: 300),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            msg['text'],
                            style: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              time,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            if (_isTyping)
              Padding(
                padding:
                    const EdgeInsets.only(left: 16, right: 16, bottom: 6, top: 2),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: color3,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Digitando...',
                      style: TextStyle(
                        color: color4.withOpacity(0.8),
                        fontStyle: FontStyle.italic,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),

            SafeArea(
              child: Container(
                width: double.infinity,
                color: color3,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Perguntar...',
                          hintStyle: TextStyle(
                            color: color2.withOpacity(0.6),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: color2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: color2, width: 1.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.send, color: color2, size: fontSize * 1.2),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
