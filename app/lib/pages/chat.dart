import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:app/widgets/app_scaffold.dart';
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

  // 🎨 Paleta e estilo base
  final color1 = const Color(0xFF23232C);
  final color2 = const Color(0xFF7968D8);
  final color3 = const Color(0xFF1F1E23);
  final color4 = const Color(0xFF5C5769);
  final fontSize = 18.0;

  /// Envia a mensagem para o backend e gerencia a resposta
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

      // Mostra "digitando..."
      _isTyping = true;
      _messages.add({
        'text': 'Digitando...',
        'isUser': false,
        'time': DateTime.now(),
        'temporary': true,
      });
    });

    _controller.clear();

    try {
      final token = await _authService.getToken();
      if (token == null) {
        setState(() {
          _isTyping = false;
          _removeTemporaryTyping();
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

      setState(() {
        _isTyping = false;
        _removeTemporaryTyping(); // remove "Digitando..."
      });

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
        _removeTemporaryTyping();
        _messages.add({
          'text': 'Exceção: $e',
          'isUser': false,
          'time': DateTime.now(),
        });
      });
    }
  }

  /// Remove a mensagem temporária "Digitando..."
  void _removeTemporaryTyping() {
    _messages.removeWhere((m) => m['temporary'] == true);
  }

  /// Obtém o usuário atual
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

            // 💬 Lista de mensagens
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg['isUser'] as bool;
                  final isTemporary = msg['temporary'] == true;
                  final time = DateFormat('HH:mm').format(msg['time']);

                  // Se for a mensagem "digitando..."
                  if (isTemporary) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: TypingBubble(
                        color2: color2,
                        color4: color4,
                      ),
                    );
                  }

                  // Mensagens normais
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
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

            // ✍️ Campo de envio
            SafeArea(
              child: Container(
                width: double.infinity,
                color: color3,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                            borderSide: BorderSide(color: color2, width: 1.5),
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

/// 💫 Widget da bolha "Digitando..."
class TypingBubble extends StatefulWidget {
  final Color color2;
  final Color color4;

  const TypingBubble({super.key, required this.color2, required this.color4});

  @override
  State<TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<TypingBubble>
    with SingleTickerProviderStateMixin {
  int dotCount = 1;
  late final Timer _timer;
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    // Animação dos "..."
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      setState(() => dotCount = (dotCount % 3) + 1);
    });

    // Efeito "respirando" (fade in/out)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dots = '.' * dotCount;

    return FadeTransition(
      opacity: Tween(begin: 0.6, end: 1.0).animate(_controller),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: widget.color2.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: widget.color2.withOpacity(0.3)),
        ),
        constraints: const BoxConstraints(maxWidth: 200),
        child: Text(
          'Digitando$dots',
          style: TextStyle(
            color: widget.color4.withOpacity(0.8),
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}
