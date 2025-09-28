import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app/app/theme.dart';

class AppMenu extends StatelessWidget {
  const AppMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.backgroundColor,
      child: Column(
        children: [
          
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: const [
                // _MenuItem(
                //   icon: Icons.home_outlined,
                //   title: 'Home',
                //   route: '/home',
                // ),
                // _MenuItem(
                //   icon: Icons.chat_outlined,
                //   title: 'Chat',
                //   route: '/chat',
                // ),
                _MenuItem(
                  icon: Icons.people_outline,
                  title: 'Usuários',
                  route: '/usuarios',
                ),
                _MenuItem(
                  icon: Icons.person_add_outlined,
                  title: 'Cadastrar Usuário',
                  route: '/cadastrar/usuario',
                ),
                Divider(color: AppTheme.borderColor),
                _MenuItem(
                  icon: Icons.logout,
                  title: 'Sair',
                  route: '/login',
                  isLogout: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String route;
  final bool isLogout;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.route,
    this.isLogout = false,
  });

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).matchedLocation;
    final isActive = currentRoute == route && !isLogout;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? AppTheme.primaryColor.withAlpha((0.1 * 255).round()) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: () {
          Navigator.of(context).pop(); // Fechar o drawer
          context.go(route);
        },
      ),
    );
  }
}