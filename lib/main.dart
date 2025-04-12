import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // Añade estas configuraciones para mejor compatibilidad
        scaffoldBackgroundColor: Colors.transparent,
        fontFamily: 'Montserrat', // Opcional: usa una fuente bonita
      ),
      home: Scaffold(
        // Scaffold adicional con fondo negro para asegurar visibilidad
        backgroundColor: Colors.black,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0F0520),
                Color(0xFF1A043A),
                Color(0xFF2D0B5A),
              ],
            ),
          ),
          child: const LoginScreen(),
        ),
      ),
    );
  }
}