import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/app/theme.dart';

const double kDesktopBreakpoint = 720.0;

class AppMenu extends StatefulWidget {
  const AppMenu({super.key});

  @override
  State<AppMenu> createState() => _AppMenuState();
}

class _AppMenuState extends State<AppMenu> {
  bool _showHelp = false;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadAdmin();
  }

  Future<void> _loadAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isAdmin = prefs.getBool('is_admin') ?? false;
    });
  }
  
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    context.go('/login');
  }

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
                // CHAT — visível para todos
                _MenuItem(
                  icon: Icons.chat_outlined,
                  title: 'Chat',
                  route: '/chat',
                  helpText: 'Acesse o chat para fazer perguntas.',
                  showHelp: _showHelp,
                ),

                // LISTAR USUÁRIOS — APENAS ADMIN
                if (_isAdmin)
                  _MenuItem(
                    icon: Icons.people_outline,
                    title: 'Usuários',
                    route: '/usuarios',
                    helpText: 'Veja a lista de usuários e gerencie permissões.',
                    showHelp: _showHelp,
                  ),

                // CADASTRAR USUÁRIO — APENAS ADMIN
                if (_isAdmin)
                  _MenuItem(
                    icon: Icons.person_add_outlined,
                    title: 'Cadastrar Usuário',
                    route: '/cadastrar/usuario',
                    helpText:
                        'Crie um novo usuário preenchendo os campos necessários.',
                    showHelp: _showHelp,
                  ),

                // PERFIL — TODOS PODEM
                _MenuItem(
                  icon: Icons.person_outline,
                  title: 'Perfil',
                  route: '/profile',
                  helpText: 'Edite as informações do seu usuário.',
                  showHelp: _showHelp,
                ),

                const Divider(color: AppTheme.borderColor),

                // LOGOUT — TODOS
                _MenuItem(
                  icon: Icons.logout,
                  title: 'Sair',
                  isLogout: true,
                  onLogout: _logout,
                  helpText: 'Saia da aplicação e volte para o login.',
                  showHelp: _showHelp,
                  route: '/login',
                ),
              ],
            ),
          ),

          // BOTÃO DE AJUDA
          SafeArea(
            minimum: const EdgeInsets.all(12),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: IconButton(
                tooltip: 'Ajuda',
                onPressed: () {
                  setState(() => _showHelp = !_showHelp);
                },
                icon: Icon(
                  _showHelp ? Icons.help : Icons.help_outline,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// MENU ITEM
// -----------------------------------------------------------------------------
class _MenuItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final String route;
  final bool isLogout;
  final bool showHelp;
  final String? helpText;
  final VoidCallback? onLogout;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.route,
    this.isLogout = false,
    this.showHelp = false,
    this.helpText,
    this.onLogout,
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
        final isDesktop =
            MediaQuery.of(context).size.width >= kDesktopBreakpoint;

        if (isDesktop) {
          _insertOverlay();
        } else {
          setState(() {});
        }
      });
    } else if (!widget.showHelp && oldWidget.showHelp) {
      _removeOverlay();
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  // INSERE TOOLTIP
  void _insertOverlay() {
    if (_overlayEntry != null || widget.helpText == null) return;

    final renderBox = _itemKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) {
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
      },
    );

    try {
      Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);
    } catch (_) {
      _overlayEntry = null;
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
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
      child: ListTile(
        leading: Icon(
          widget.icon,
          color:
              isActive ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
        ),
        title: isMobile && widget.showHelp && widget.helpText != null
            ? _HelpTooltipMobile(text: widget.helpText!)
            : Text(
                widget.title,
                style: TextStyle(
                  color: isActive
                      ? AppTheme.primaryColor
                      : AppTheme.textPrimaryColor,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
        onTap: () {
          _removeOverlay();
          Navigator.of(context).pop();

          if (widget.isLogout) {
            widget.onLogout?.call();
            return;
          }

          context.go(widget.route);
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TOOLTIP PARA MOBILE
// -----------------------------------------------------------------------------
class _HelpTooltipMobile extends StatelessWidget {
  final String text;

  const _HelpTooltipMobile({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CustomPaint(
          size: const Size(12, 36),
          painter: _TrianglePainter(color: Colors.white),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
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

// -----------------------------------------------------------------------------
// TOOLTIP PARA DESKTOP
// -----------------------------------------------------------------------------
class _HelpTooltip extends StatelessWidget {
  final String text;

  const _HelpTooltip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CustomPaint(
          size: const Size(12, 28),
          painter: _TrianglePainter(color: Colors.white),
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          constraints: const BoxConstraints(maxWidth: 220),
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

// -----------------------------------------------------------------------------
class _TrianglePainter extends CustomPainter {
  final Color color;

  const _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    final path = Path()
      ..moveTo(size.width, size.height / 2 - 6)
      ..lineTo(0, size.height / 2)
      ..lineTo(size.width, size.height / 2 + 6)
      ..close();

    canvas.drawShadow(path, Colors.black.withOpacity(0.15), 4, false);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
