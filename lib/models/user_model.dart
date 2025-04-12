class User {
  final String username;
  final String password;
  final String displayName;
  

  User({
    required this.username,
    required this.password,
    required this.displayName,
  });

  // Método para verificar credenciales
  bool checkCredentials(String inputUsername, String inputPassword) {
    return username == inputUsername && password == inputPassword;
  }
}

// Usuarios predefinidos (variables globales)
final User user1 = User(
  username: 'Gabriel',
  password: '1234',
  displayName: 'Gabriel',
);

final User user2 = User(
  username: 'Jandy',
  password: 'kiki',
  displayName: 'Jandy',
);

// Lista de usuarios válidos
final List<User> validUsers = [user1, user2];