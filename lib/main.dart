import 'package:chatt_app/screens/auth.dart';
import 'package:chatt_app/screens/chat.dart';
import 'package:chatt_app/screens/splash.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlutterChat',
      theme: ThemeData().copyWith(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 63, 17, 177)),
      ),
      home: StreamBuilder(
        // A classe StreamBuilder recebe um Stream e um construtor de widgets, e
        // automaticamente reconstrói o widget cada vez que um novo dado é recebido
        // pelo Stream.
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // mostrar a splash screen até a verificação do firebase retornar algo
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Splash();
          }
          // aqui verifico se possui dados de login, se sim, retorno a página de chat
          // Se não, retorno para a página de autenticação
          if (snapshot.hasData) {
            return const Chat();
          }

          return const Auth();
        },
      ),
    );
  }
}
