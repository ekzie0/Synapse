class Note {
  final int? id;
  final int userId;
  final String title;
  final String? content;
  final int createdAt;
  final int updatedAt;
  List<String>? tags;

  Note({
    this.id,
    required this.userId,
    required this.title,
    this.content,
    required this.createdAt,
    required this.updatedAt,
    this.tags,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'content': content,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      userId: map['user_id'],
      title: map['title'],
      content: map['content'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }
  
  Note copyWith({
    int? id,
    int? userId,
    String? title,
    String? content,
    int? createdAt,
    int? updatedAt,
    List<String>? tags,
  }) {
    return Note(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
    );
  }
}