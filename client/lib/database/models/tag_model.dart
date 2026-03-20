class Tag {
  final int? id;
  final int userId;
  final String name;
  final String color;

  Tag({
    this.id,
    required this.userId,
    required this.name,
    required this.color,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'color': color,
    };
  }

  factory Tag.fromMap(Map<String, dynamic> map) {
    return Tag(
      id: map['id'],
      userId: map['user_id'],
      name: map['name'],
      color: map['color'],
    );
  }
}