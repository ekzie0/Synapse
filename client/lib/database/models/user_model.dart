class User {
  final int? id;
  final String username;
  final String email;
  final String password;
  final String? avatarColor;
  final String? avatarPath;
  final int createdAt;
  final int updatedAt;

  User({
    this.id,
    required this.username,
    required this.email,
    required this.password,
    this.avatarColor,
    this.avatarPath,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'password': password,
      'avatar_color': avatarColor,
      'avatar_path': avatarPath,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      email: map['email'],
      password: map['password'],
      avatarColor: map['avatar_color'],
      avatarPath: map['avatar_path'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }
  
  User copyWith({
    int? id,
    String? username,
    String? email,
    String? password,
    String? avatarColor,
    String? avatarPath,
    int? createdAt,
    int? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      avatarColor: avatarColor ?? this.avatarColor,
      avatarPath: avatarPath ?? this.avatarPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}