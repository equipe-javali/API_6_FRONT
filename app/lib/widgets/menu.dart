import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app/app/theme.dart';

class AppMenu extends StatefulWidget {
  const AppMenu({super.key});

  @override
  State<AppMenu> createState() => _AppMenuState();
}

class _AppMenuState extends State<AppMenu> {
  bool _showHelp = false;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.backgroundColor,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _MenuItem(
                  icon: Icons.chat_outlined,
                  title: 'Chat',
                  route: '/chat',
                  helpText: 'Abra o chat para conversar com o agente e acompanhar conversas.',
                  showHelp: _showHelp,
                ),
                _MenuItem(
                  icon: Icons.people_outline,
                  title: 'Usuários',
                  route: '/usuarios',
                  helpText: 'Visualize e gerencie a lista de usuários do sistema.',
                  showHelp: _showHelp,
                ),
                _MenuItem(
                  icon: Icons.person_add_outlined,
                  title: 'Cadastrar Usuário',
                  route: '/cadastrar/usuario',
                  helpText: 'Adicione um novo usuário preenchendo os dados necessários.',
                  showHelp: _showHelp,
                ),
                const Divider(color: AppTheme.borderColor),
                _MenuItem(
                  icon: Icons.logout,
                  title: 'Sair',
                  route: '/login',
                  isLogout: true,
                  helpText: 'Encerre a sessão atual e volte para a tela de login.',
                  showHelp: _showHelp,
                ),
              ],
            ),
          ),
          // Rodapé com botão de ajuda no canto esquerdo
          SafeArea(
            minimum: const EdgeInsets.all(12),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Ajuda',
                    onPressed: () {
                      setState(() {
                        _showHelp = !_showHelp;
                      });
                    },
                    icon: Icon(_showHelp ? Icons.help : Icons.help_outline),
                    color: AppTheme.textPrimaryColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpBalloon extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _HelpBalloon({super.key, required this.icon, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Icon(icon, size: 20, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(color: AppTheme.textSecondaryColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final String route;
  final bool isLogout;
  final bool showHelp;
  final String? helpText;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.route,
    this.isLogout = false,
    this.showHelp = false,
    this.helpText,
  });

  @override
  State<_MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends State<_MenuItem> {
  final GlobalKey _itemKey = GlobalKey();
  OverlayEntry? _overlayEntry;

  @override
  void didUpdateWidget(covariant _MenuItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showHelp && !oldWidget.showHelp) {
      // Aguarda o próximo frame para garantir que o RenderBox esteja disponível
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        try {
          _insertOverlay();
        } catch (e) {
          // Falha ao inserir overlay — evita crash da UI
        }
      });
    } else if (!widget.showHelp && oldWidget.showHelp) {
      _removeOverlay();
    }
  }

  void _insertOverlay() {
    if (_overlayEntry != null || widget.helpText == null) return;

    final renderBox = _itemKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(builder: (context) {
      double top = offset.dy + (size.height / 2) - 22; // attempt to center tooltip vertically
      if (top < 8) top = 8;
      return Positioned(
        left: offset.dx + size.width + 8,
        top: top,
        child: Material(
          color: Colors.transparent,
          child: _HelpTooltip(text: widget.helpText!),
        ),
      );
    });

    try {
      final overlay = Overlay.of(context, rootOverlay: true) ?? Overlay.of(context);
      overlay?.insert(_overlayEntry!);
    } catch (e) {
      _overlayEntry = null;
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).matchedLocation;
    final isActive = currentRoute == widget.route && !widget.isLogout;

    return Container(
      key: _itemKey,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? AppTheme.primaryColor.withAlpha((0.1 * 255).round()) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          widget.icon,
          color: isActive ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
        ),
        title: Text(
          widget.title,
          style: TextStyle(
            color: isActive ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: () {
          _removeOverlay();
          Navigator.of(context).pop(); // Fechar o drawer
          context.go(widget.route);
        },
      ),
    );
  }
}

class _HelpTooltip extends StatelessWidget {
  final String text;

  const _HelpTooltip({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // seta triangular apontando para a esquerda
        CustomPaint(
          size: const Size(12, 28),
          painter: _TrianglePainter(color: Colors.white),
        ),
        Container(
          constraints: const BoxConstraints(maxWidth: 220),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    // triangle pointing left, centered vertically
    path.moveTo(size.width, size.height / 2 - 6);
    path.lineTo(0, size.height / 2);
    path.lineTo(size.width, size.height / 2 + 6);
    path.close();
    canvas.drawShadow(path, Colors.black.withOpacity(0.15), 4, false);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}