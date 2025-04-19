import 'package:firebase_database/firebase_database.dart';

class User {
  final String username;
  final String password;
  final String displayName;
  final bool online; // Nueva clave


  User({
    required this.username,
    required this.password,
    required this.displayName,
    this.online = false, // Por defecto es false

  });

  // Método para verificar credenciales
  bool checkCredentials(String inputUsername, String inputPassword) {
    return username == inputUsername && password == inputPassword;
  }

  // Convertir un usuario a un mapa para Firebase
  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'password': password,
      'displayName': displayName,
      'online': online,

    };
  }

  // Crear un usuario desde un mapa de Firebase
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      username: map['username'],
      password: map['password'],
      displayName: map['displayName'],
      online: map['online'] ?? false,

    );
  }
}

// Clase para manejar usuarios en Firebase
class UserService {
  final DatabaseReference _usersRef =
      FirebaseDatabase.instance.ref().child('users');

  Future<void> setUserOnline(String username, bool isOnline) async {
    await _usersRef.child(username).update({'online': isOnline});
  }

  Stream<List<User>> getOnlineUsers(String currentUsername) {
    return _usersRef.onValue.map((event) {
      final usersMap = Map<String, dynamic>.from(event.snapshot.value as Map);
      return usersMap.entries
          .map((entry) => User.fromMap(Map<String, dynamic>.from(entry.value)))
          .where((user) => user.online && user.username != currentUsername)
          .toList();
    });
  }
  Future<User?> getUser(String username) async {
  final snapshot = await _usersRef.child(username).get();
  if (snapshot.exists) {
    return User.fromMap(Map<String, dynamic>.from(snapshot.value as Map));
  }
  return null; // Retorna null si el usuario no existe
}


}