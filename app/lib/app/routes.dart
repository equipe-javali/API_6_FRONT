import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/pages/login.dart';
import 'package:app/pages/chat.dart';
import 'package:app/pages/listar_usuarios.dart';
import 'package:app/pages/cadastrar_usuario.dart';
import 'package:app/pages/recuperar_senha.dart';
import 'package:app/pages/profile.dart';

Future<bool> isLogged() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString("access_token") != null;
}

Future<bool> isAdminUser() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool("is_admin") ?? false;
}

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) async {
  final logged = await isLogged();
  final admin = await isAdminUser();

  final isLoginPage = state.uri.toString() == "/login";
  final isRecoverPage = state.uri.toString() == "/recuperar-senha";

  final isAdminRoute = state.uri.toString().startsWith("/usuarios") ||
      state.uri.toString().startsWith("/cadastrar/usuario");

  // 🔹 se não está logado → vai para login, exceto recuperar senha
  if (!logged && !isLoginPage && !isRecoverPage) {
    return '/login';
  }

  // 🔹 logado tentando acessar /login → manda para /chat
  if (logged && isLoginPage) {
    return '/chat';
  }

  // 🔹 rota admin → bloquear caso não seja admin
  if (isAdminRoute && !admin) {
    return "/chat";
  }

  return null;
},


  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),

    GoRoute(
      path: '/chat',
      builder: (context, state) => const ChatPage(),
    ),

    GoRoute(
      path: '/usuarios',
      builder: (context, state) => const ListarUsuariosPage(),
    ),

    GoRoute(
      path: '/cadastrar/usuario',
      builder: (context, state) => const CadastrarUsuarioPage(),
    ),

    GoRoute(
      path: '/recuperar-senha',
      builder: (context, state) => const RecuperarSenhaPage(),
    ),

    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfilePage(),
    ),
  ],
);
