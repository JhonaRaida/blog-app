import '../models/comment.dart';
import '../models/post.dart';
import 'api_client.dart';

/// Acceso a datos de posts, comentarios, estrellas y reacciones.
class PostService {
  PostService(this._api);

  final ApiClient _api;

  List<Post> _posts(dynamic data) =>
      (data as List<dynamic>).map((p) => Post.fromJson(p as Map<String, dynamic>)).toList();

  Future<List<Post>> getPosts() async => _posts(await _api.get('/posts'));

  Future<List<Post>> getMyPosts() async => _posts(await _api.get('/posts/mine'));

  Future<Post> getPost(int id) async => Post.fromJson(await _api.get('/posts/$id'));

  Future<Post> createPost(String title, String content) async =>
      Post.fromJson(await _api.post('/posts', {'title': title, 'content': content}));

  Future<void> deletePost(int id) async => _api.delete('/posts/$id');

  // ----- Opcional 1: estrellas -----
  Future<Post> ratePost(int id, int stars) async =>
      Post.fromJson(await _api.put('/posts/$id/rating', {'stars': stars}));

  // ----- Comentarios -----
  Future<List<Comment>> getComments(int postId) async {
    final data = await _api.get('/posts/$postId/comments');
    return (data as List<dynamic>).map((c) => Comment.fromJson(c as Map<String, dynamic>)).toList();
  }

  Future<Comment> addComment(int postId, String content) async =>
      Comment.fromJson(await _api.post('/posts/$postId/comments', {'content': content}));

  // ----- Opcional 2: reacciones con emoji -----
  Future<Comment> toggleReaction(int commentId, String emoji) async =>
      Comment.fromJson(await _api.put('/comments/$commentId/reactions', {'emoji': emoji}));
}
