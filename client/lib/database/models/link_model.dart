class LinkModel {
  final int? id;
  final int sourceNoteId;
  final int targetNoteId;
  final int createdAt;

  LinkModel({
    this.id,
    required this.sourceNoteId,
    required this.targetNoteId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'source_note_id': sourceNoteId,
      'target_note_id': targetNoteId,
      'created_at': createdAt,
    };
  }

  factory LinkModel.fromMap(Map<String, dynamic> map) {
    return LinkModel(
      id: map['id'],
      sourceNoteId: map['source_note_id'],
      targetNoteId: map['target_note_id'],
      createdAt: map['created_at'],
    );
  }
}