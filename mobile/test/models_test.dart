import 'package:blog_app/models/comment.dart';
import 'package:blog_app/models/post.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Post.fromJson lee valoración y datos del autor', () {
    final post = Post.fromJson({
      'id': 1,
      'title': 'Hola',
      'content': 'Contenido',
      'created_at': '2026-11-19T10:00:00',
      'author_id': 2,
      'author_name': 'Ana',
      'is_mine': false,
      'comment_count': 3,
      'avg_rating': 4.5,
      'rating_count': 2,
      'my_rating': null,
    });
    expect(post.avgRating, 4.5);
    expect(post.myRating, isNull);
    expect(post.authorName, 'Ana');
  });

  test('Comment.fromJson lee reacciones con emoji', () {
    final c = Comment.fromJson({
      'id': 5,
      'post_id': 1,
      'author_id': 2,
      'author_name': 'Beto',
      'content': 'Buen post 😀',
      'created_at': '2026-11-19T10:05:00',
      'reactions': [
        {'emoji': '❤️', 'count': 2, 'reacted': true}
      ],
    });
    expect(c.reactions.first.count, 2);
    expect(c.reactions.first.reacted, isTrue);
    expect(c.content, contains('😀'));
  });
}
