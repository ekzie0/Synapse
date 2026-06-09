class User {
  final int? id; // В SQLite ID обычно автоинкрементный int
  final String username;
  final String email;
  final String password; // Здесь всегда будет храниться хэш
  final String? avatarPath;
  final int? createdAt;
  final int? updatedAt;

  const User({
    this.id,
    required this.username,
    required this.email,
    required this.password,
    this.avatarPath,
    this.createdAt,
    this.updatedAt,
  });

  // Преобразование из объекта в Map для записи в SQLite
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'username': username,
      'email': email,
      'password': password,
      'avatar_path': avatarPath,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  // Создание объекта из Map при чтении из SQLite
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      username: map['username'] as String? ?? '',
      email: map['email'] as String? ?? '',
      password: map['password'] as String? ?? '',
      avatarPath: map['avatar_path'] as String?,
      createdAt: map['created_at'] as int?,
      updatedAt: map['updated_at'] as int?,
    );
  }

  // Метод copyWith для безопасного обновления полей
  User copyWith({
    int? id,
    String? username,
    String? email,
    String? password,
    String? avatarPath,
    int? createdAt,
    int? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      avatarPath: avatarPath ?? this.avatarPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}