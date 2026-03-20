import 'package:synapse/database/models/note_model.dart';

class Folder {
  final int? id;
  final int userId;
  final int? parentId;
  final String name;
  final int createdAt;
  final int updatedAt;
  List<Folder>? subfolders;
  List<Note>? notes;

  Folder({
    this.id,
    required this.userId,
    this.parentId,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.subfolders,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'parent_id': parentId,
      'name': name,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Folder.fromMap(Map<String, dynamic> map) {
    return Folder(
      id: map['id'],
      userId: map['user_id'],
      parentId: map['parent_id'],
      name: map['name'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }

  Folder copyWith({
    int? id,
    int? userId,
    int? parentId,
    String? name,
    int? createdAt,
    int? updatedAt,
    List<Folder>? subfolders,
    List<Note>? notes,
  }) {
    return Folder(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      subfolders: subfolders ?? this.subfolders,
      notes: notes ?? this.notes,
    );
  }
}