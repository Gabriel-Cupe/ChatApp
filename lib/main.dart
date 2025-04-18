import 'package:chat_app/notis/message_listener.dart';
import 'package:chat_app/notis/notification_service.dart';
import 'package:chat_app/notis/timer.dart';
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService.initialize(); // Inicializa notificaciones
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _messageListener = MessageListener();

  @override
  void initState() {

    super.initState();
    _messageListener.startListening(); // Escucha mensajes de Firebase
    PeriodicNotifier.start(5); // Inicia notificaciones periódicas (5 minutos por defecto)
    // En algún lugar de tu código de configuración:
//initializeEmojiAndStickerDatabase();
  }

  @override
  void dispose() {
    PeriodicNotifier.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.transparent,
        fontFamily: 'Montserrat',
      ),
      home: Scaffold(
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