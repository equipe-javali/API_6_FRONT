import 'package:go_router/go_router.dart';
import 'package:app/pages/login.dart';
// import 'package:app/pages/home.dart';
// import 'package:app/pages/chat.dart';
import 'package:app/pages/listar_usuarios.dart';
import 'package:app/pages/cadastrar_usuario.dart';
import 'package:app/pages/chat.dart';
import 'package:app/pages/recuperar_senha.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    // GoRoute(
    //   path: '/home',
    //   builder: (context, state) => const HomePage(),
    // ),
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
  ],
);
