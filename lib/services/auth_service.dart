import '../models/user_model.dart';

class AuthService {
  final UserService _userService = UserService();

  Future<User?> authenticate(String username, String password) async {
    try {
      // Obtener el usuario desde Firebase
      final user = await _userService.getUser(username);

      if (user == null) {
        print('Usuario no encontrado: $username');
        return null;
      }

      // Verificar credenciales
      if (!user.checkCredentials(username, password)) {
        print('Credenciales incorrectas para el usuario: $username');
        return null;
      }

      // Marcar al usuario como en línea
      await _userService.setUserOnline(username, true);
      print('Usuario autenticado y marcado como en línea: $username');
      return user;
    } catch (e) {
      print('Error durante la autenticación: $e');
      return null;
    }
  }

  Future<void> logout(String username) async {
    try {
      // Marcar al usuario como desconectado
      await _userService.setUserOnline(username, false);
      print('Usuario marcado como desconectado: $username');
    } catch (e) {
      print('Error al cerrar sesión: $e');
    }
  }

  Future<void> handleAppClose(String username) async {
    try {
      // Marcar al usuario como desconectado al cerrar la aplicación
      await _userService.setUserOnline(username, false);
      print('Usuario marcado como desconectado al cerrar la aplicación: $username');
    } catch (e) {
      print('Error al manejar el cierre de la aplicación: $e');
    }
  }
}