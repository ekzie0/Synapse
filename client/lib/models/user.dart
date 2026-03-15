class User {
  final String id;
  final String email;
  final String? name;
  final String? avatarUrl;
  final bool isGuest;

  const User({
    required this.id,
    required this.email,
    this.name,
    this.avatarUrl,
    this.isGuest = false,
  });

  // Для гостя
  factory User.guest() {
    return User(
      id: 'guest',
      email: 'guest@synapse.local',
      name: 'Гость',
      isGuest: true,
    );
  }

  // Для сериализации
  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'avatarUrl': avatarUrl,
    'isGuest': isGuest,
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'],
    email: json['email'],
    name: json['name'],
    avatarUrl: json['avatarUrl'],
    isGuest: json['isGuest'] ?? false,
  );
}