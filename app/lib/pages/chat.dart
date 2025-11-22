import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:app/widgets/app_scaffold.dart';
import 'package:app/services/auth_service.dart';
import 'package:sticky_headers/sticky_headers.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  final AuthService _authService = AuthService();
  int? _userId;
  
  List<Map<String, dynamic>> _groupedMessages() {
    
    final Map<DateTime, List<Map<String, dynamic>>> groups = {};
    for (var msg in _messages) {
      final time = (msg['time'] as DateTime).toLocal();
      final key = DateTime(time.year, time.month, time.day);
      groups.putIfAbsent(key, () => []).add(msg);
    }

    final sortedKeys = groups.keys.toList()..sort();
    return sortedKeys
        .map((key) => {'date': key, 'messages': groups[key]!})
        .toList();
  }

  final sortedKeys = groups.keys.toList()..sort();
  return sortedKeys
      .map((key) => {'date': key, 'messages': groups[key]!})
      .toList();
}

  // 🎨 Paleta e estilo base
  final color1 = const Color(0xFF23232C);
  final color2 = const Color(0xFF7968D8);
  final color3 = const Color(0xFF1F1E23);
  final color4 = const Color(0xFF5C5769);
  final fontSize = 18.0;

  
  void _sendMessage() {
    _sendMessageToBackend();
  }

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await initializeDateFormatting('pt_BR', null);
      } catch (e) {
        
        print('Falha ao inicializar locale pt_BR: $e');
      }
      final token = await _authService.getToken();
      if (token != null) {
        await _loadCurrentUser(token);
        await _loadMessageHistory();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
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
    _scrollToBottom();

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
        _scrollToBottom();
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

  
  Future<void> _loadMessageHistory() async {
    try {
      final token = await _authService.getToken();
      if (token == null) return;

      if (_userId == null) {
        await _loadCurrentUser(token);
        if (_userId == null) return;
      }

      final url = Uri.parse('${_authService.baseUrl}/users/mensagens/$_userId');
      final resp = await http.get(url, headers: {'Authorization': 'Bearer $token'});
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data is List) {
          
          final List<Map<String, dynamic>> loaded = data.map<Map<String, dynamic>>((m) {
            final isIa = m['ia'] == true || (m['ia'] is int && m['ia'] == 1);
            DateTime time;
            try {
              
              final raw = m['envio'];
              if (raw == null) {
                time = DateTime.now();
              } else if (raw is String) {
                
                final tzRegex = RegExp(r"(Z|[+-]\d{2}:?\d{2})$");
                final hasTz = tzRegex.hasMatch(raw);
                final parsed = hasTz
                    ? DateTime.parse(raw)
                    : DateTime.parse(raw.endsWith('Z') ? raw : '${raw}Z');
                time = parsed.toLocal();
              } else if (raw is num) {
                
                final millis = raw > 1e12 ? raw.toInt() : (raw * 1000).toInt();
                time = DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true).toLocal();
              } else {
                time = DateTime.now();
              }
            } catch (_) {
              time = DateTime.now();
            }

            return {
              'text': m['mensagem'] ?? '',
              'isUser': !isIa, 
              'time': time,
            };
          }).toList();

          
          loaded.sort((a, b) => (a['time'] as DateTime).compareTo(b['time'] as DateTime));

          setState(() {
            _messages.clear();
            _messages.addAll(loaded);
          });

          
          _scrollToBottom();
        }
      } else {
        print('Falha ao carregar mensagens: ${resp.statusCode} ${resp.body}');
      }
    } catch (e) {
      print('Erro ao carregar histórico: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return _isSameDay(date, yesterday);
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    if (_isSameDay(date, now)) return 'Hoje';
    if (_isYesterday(date)) return 'Ontem';
    
    try {
      return DateFormat("d 'de' MMMM 'de' y", 'pt_BR').format(date);
    } catch (_) {
      return DateFormat('yyyy-MM-dd').format(date);
    }
  }

  List<Widget> _buildMessageList() {
    final List<Widget> widgets = [];
    final screenW = MediaQuery.of(context).size.width;
    final isDesktopLocal = screenW >= 720;
    final double bubbleMaxLocal = isDesktopLocal
        ? (screenW * 0.45 > 700 ? 700 : screenW * 0.45)
        : 300;
    DateTime? lastDate;

    for (var i = 0; i < _messages.length; i++) {
      final msg = _messages[i];
      final isUser = msg['isUser'] as bool;
      final isTemporary = msg['temporary'] == true;
      final DateTime time = msg['time'] as DateTime;

      
      if (lastDate == null || !_isSameDay(lastDate, time)) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color2.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _formatDateHeader(time),
                  style: TextStyle(color: color2, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        );
        lastDate = time;
      }

      // typing bubble
      if (isTemporary) {
        widgets.add(
          Align(
            alignment: Alignment.centerLeft,
            child: TypingBubble(color2: color2, color4: color4),
          ),
        );
        continue;
      }

      // normal message bubble
      widgets.add(
        Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
              color: isUser ? color3 : const Color(0xFF2A2A35),
              border: Border.all(color: color2.withOpacity(0.4)),
              borderRadius: BorderRadius.circular(12),
            ),
            constraints: BoxConstraints(maxWidth: bubbleMaxLocal),
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
                    DateFormat('HH:mm').format(time),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  
  void _removeTemporaryTyping() {
    _messages.removeWhere((m) => m['temporary'] == true);
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
    final isDesktop = MediaQuery.of(context).size.width >= 720;
    // On desktop allow the chat area to expand and use more of the screen.
    final maxContentWidth = isDesktop ? double.infinity : 900.0;
    final screenW = MediaQuery.of(context).size.width;
    final double bubbleMaxWidth = isDesktop
        ? (screenW * 0.45 > 700 ? 700 : screenW * 0.45)
        : 300;

    return AppScaffold(
      title: '',
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContentWidth),
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
                        controller: _scrollController,
                        padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 16, vertical: 8),
                        itemCount: _groupedMessages().length,
                        itemBuilder: (context, index) {
                          final group = _groupedMessages()[index];
                          final date = group['date'] as DateTime;
                          final messages = group['messages'] as List<Map<String, dynamic>>;

                          return StickyHeader(
                            header: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              color: color1,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: color2.withOpacity(0.16),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _formatDateHeader(date),
                                    style: TextStyle(
                                      color: color2,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            content: Column(
                              children: messages.map((msg) {
                                final isUser = msg['isUser'] as bool;
                                final isTemporary = msg['temporary'] == true;
                                final time = DateFormat('HH:mm').format((msg['time'] as DateTime).toLocal());

                                if (isTemporary) {
                                  return Align(
                                    alignment: Alignment.centerLeft,
                                    child: TypingBubble(color2: color2, color4: color4),
                                  );
                                }

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
                                    constraints: BoxConstraints(maxWidth: bubbleMaxWidth),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(msg['text'], style: const TextStyle(color: Colors.white)),
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
                              }).toList(),
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
