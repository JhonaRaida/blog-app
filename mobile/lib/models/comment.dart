class Reaction {
  final String emoji;
  final int count;
  final bool reacted;

  const Reaction({required this.emoji, required this.count, required this.reacted});

  factory Reaction.fromJson(Map<String, dynamic> json) => Reaction(
        emoji: json['emoji'] as String,
        count: json['count'] as int,
        reacted: json['reacted'] as bool,
      );
}

class Comment {
  final int id;
  final int postId;
  final int authorId;
  final String authorName;
  final String content;
  final DateTime createdAt;
  final List<Reaction> reactions;

  const Comment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.createdAt,
    required this.reactions,
  });

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
        id: json['id'] as int,
        postId: json['post_id'] as int,
        authorId: json['author_id'] as int,
        authorName: json['author_name'] as String,
        content: json['content'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        reactions: (json['reactions'] as List<dynamic>)
            .map((r) => Reaction.fromJson(r as Map<String, dynamic>))
            .toList(),
      );
}
