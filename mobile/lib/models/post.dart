class Post {
  final int id;
  final String title;
  final String content;
  final DateTime createdAt;
  final int authorId;
  final String authorName;
  final bool isMine;
  final int commentCount;
  final double avgRating;
  final int ratingCount;
  final int? myRating;

  const Post({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.authorId,
    required this.authorName,
    required this.isMine,
    required this.commentCount,
    required this.avgRating,
    required this.ratingCount,
    this.myRating,
  });

  factory Post.fromJson(Map<String, dynamic> json) => Post(
        id: json['id'] as int,
        title: json['title'] as String,
        content: json['content'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        authorId: json['author_id'] as int,
        authorName: json['author_name'] as String,
        isMine: json['is_mine'] as bool,
        commentCount: json['comment_count'] as int,
        avgRating: (json['avg_rating'] as num).toDouble(),
        ratingCount: json['rating_count'] as int,
        myRating: json['my_rating'] as int?,
      );
}
