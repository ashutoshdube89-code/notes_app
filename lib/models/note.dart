class Note {
  final String id;
  final String title;
  final String body;
  final DateTime updatedAt;

  Note({
    required this.id,
    required this.title,
    required this.body,
    required this.updatedAt,
  });

  Note copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}