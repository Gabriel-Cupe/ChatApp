import '../models/user_model.dart';

class AuthService {
  // Verificar credenciales
  static User? authenticate(String username, String password) {
    for (var user in validUsers) {
      if (user.checkCredentials(username, password)) {
        return user;
      }
    }
    return null;
  }
}