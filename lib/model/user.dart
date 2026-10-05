class User {
  final int? id;
  final String name;
  final String email;
  final String password;
  final String? imagePath;

  User({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    this.imagePath,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      name: map['name'] as String,
      email: map['email'] as String,
      password: map['password'] as String,
      imagePath: map['imagePath'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'email': email,
      'password': password,
      'imagePath': imagePath,
    };
  }
}