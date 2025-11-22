import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app/app/theme.dart';

// Breakpoint to switch between mobile (inline) and desktop (overlay)
const double kDesktopBreakpoint = 720.0;

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
                  helpText: 'Acesse o chat para fazer perguntas.',
                  showHelp: _showHelp,
                ),
                _MenuItem(
                  icon: Icons.people_outline,
                  title: 'Usuários',
                  route: '/usuarios',
                  helpText: 'Veja a lista de usuários e gerencie permissões.',
                  showHelp: _showHelp,
                ),
                _MenuItem(
                  icon: Icons.person_add_outlined,
                  title: 'Cadastrar Usuário',
                  route: '/cadastrar/usuario',
                  helpText: 'Crie um novo usuário preenchendo os campos necessários.',
                  showHelp: _showHelp,
                ),
                const Divider(color: AppTheme.borderColor),
                _MenuItem(
                  icon: Icons.logout,
                  title: 'Sair',
                  route: '/login',
                  isLogout: true,
                  helpText: 'Saia da aplicação e volte para a tela de login.',
                  showHelp: _showHelp,
                ),
              ],
            ),
          ),

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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        try {
          final isDesktop = MediaQuery.of(context).size.width >= kDesktopBreakpoint;
          if (isDesktop) {
            _insertOverlay();
          } else {
            setState(() {});
          }
        } catch (_) {}
      });
    } else if (!widget.showHelp && oldWidget.showHelp) {
      _removeOverlay();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Se o overlay estiver aberto e a janela mudou, reposiciona
    if (widget.showHelp && _overlayEntry != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _removeOverlay();
        final isDesktop = MediaQuery.of(context).size.width >= kDesktopBreakpoint;
        if (isDesktop) _insertOverlay();
        else setState(() {});
      });
    }
  }

  void _insertOverlay() {
    if (_overlayEntry != null || widget.helpText == null) return;

    final renderBox = _itemKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(builder: (context) {
      double top = offset.dy + (size.height / 2) - 22;
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
    } catch (_) {
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
    final isMobile = MediaQuery.of(context).size.width < kDesktopBreakpoint;

    return Container(
      key: _itemKey,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.primaryColor.withAlpha((0.1 * 255).round())
            : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: Icon(
              widget.icon,
              color: isActive ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
            ),
            title: isMobile && widget.showHelp && widget.helpText != null
                ? _HelpTooltipMobile(text: widget.helpText!)
                : Text(
                    widget.title,
                    style: TextStyle(
                      color: isActive ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
            onTap: () {
              _removeOverlay();
              Navigator.of(context).pop();
              context.go(widget.route);
            },
          ),
        ],
      ),
    );
  }
}

class _HelpTooltipMobile extends StatelessWidget {
  final String text;

  const _HelpTooltipMobile({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: const Size(12, 36),
          painter: _TrianglePainter(color: Colors.white),
        ),
        Flexible(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ),
      ],
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
