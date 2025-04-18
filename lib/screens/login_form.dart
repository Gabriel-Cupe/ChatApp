// ignore_for_file: unnecessary_const, deprecated_member_use

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/chat_screen.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  void _login() {
    if (_formKey.currentState!.validate()) {
      final username = _usernameController.text;
      final password = _passwordController.text;

      final user = AuthService.authenticate(username, password);

      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(user: user),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Row(
              children: const [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Usuario o contraseña incorrectos.',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Bienvenido <3\nInicia sesión',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF7B1FA2),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pantalla de login',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: 'Usuario',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (value) =>
                value == null || value.isEmpty ? 'Ingrese su usuario' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: Icon(Icons.vpn_key_outlined),
            ),
            validator: (value) =>
                value == null || value.isEmpty ? 'Ingrese su contraseña' : null,
          ),
          const SizedBox(height: 46),
SizedBox(
  width: double.infinity,
  child: ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF7B1FA2), // Un morado más vibrante
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 18), // Más alto
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Bordes más redondeados
      ),
      elevation: 8, // Sombra más pronunciada
      shadowColor: const Color(0xFF7B1FA2).withOpacity(0.5),
      textStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2, // Espaciado entre letras
      ),
    ),
    onPressed: _login,
    child: const Text(
      'ENTRAR',
      style: TextStyle(
        shadows: [
          Shadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(1, 1),)
        ],
      ),
    ),
  ),
),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
