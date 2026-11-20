import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../config/constants.dart';
import '../models/comment.dart';
import '../models/post.dart';
import '../services/post_service.dart';
import '../widgets/comment_tile.dart';
import '../widgets/star_rating.dart';

class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({super.key, required this.post});

  final Post post;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late Post _post = widget.post;
  List<Comment> _comments = [];
  bool _loading = true;
  bool _sending = false;
  String? _error;
  final _commentCtrl = TextEditingController();

  PostService get _service => context.read<PostService>();

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _loadComments() async {
    try {
      final comments = await _service.getComments(_post.id);
      if (mounted) setState(() => _comments = comments);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _rate(int stars) async {
    try {
      final updated = await _service.ratePost(_post.id, stars);
      if (mounted) setState(() => _post = updated);
    } catch (e) {
      _showMessage(e.toString());
    }
  }

  Future<void> _sendComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final created = await _service.addComment(_post.id, text);
      if (!mounted) return;
      setState(() {
        _comments = [..._comments, created];
        _commentCtrl.clear();
      });
    } catch (e) {
      _showMessage(e.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _react(Comment comment, String emoji) async {
    try {
      final updated = await _service.toggleReaction(comment.id, emoji);
      if (!mounted) return;
      setState(() {
        _comments = [for (final c in _comments) c.id == updated.id ? updated : c];
      });
    } catch (e) {
      _showMessage(e.toString());
    }
  }

  void _insertEmoji(String emoji) {
    final sel = _commentCtrl.selection;
    final text = _commentCtrl.text;
    final start = sel.isValid ? sel.start : text.length;
    final end = sel.isValid ? sel.end : text.length;
    _commentCtrl.value = TextEditingValue(
      text: text.replaceRange(start, end, emoji),
      selection: TextSelection.collapsed(offset: start + emoji.length),
    );
  }

  Future<void> _deletePost() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar publicación'),
        content: const Text('Se borrarán también sus comentarios. ¿Continuar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.deletePost(_post.id);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      _showMessage(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd/MM/yyyy HH:mm').format(_post.createdAt);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Publicación'),
        actions: [
          if (_post.isMine)
            IconButton(
              tooltip: 'Eliminar',
              icon: const Icon(Icons.delete_outline),
              onPressed: _deletePost,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(_post.title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  '${_post.isMine ? 'Tú' : _post.authorName} · $date',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 16),
                Text(_post.content, style: const TextStyle(fontSize: 16, height: 1.4)),
                const SizedBox(height: 20),
                _buildRatingSection(),
                const Divider(height: 32),
                Text('Comentarios (${_comments.length})', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (_loading)
                  const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                else if (_error != null)
                  Text(_error!, style: const TextStyle(color: Colors.red))
                else if (_comments.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('Sé el primero en comentar'),
                  ),
                for (final c in _comments) CommentTile(comment: c, onReact: (e) => _react(c, e)),
              ],
            ),
          ),
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    final summary = _post.ratingCount == 0
        ? 'Sin valoraciones todavía'
        : '${_post.avgRating} de 5 · ${_post.ratingCount} voto(s)';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            StarRating(rating: _post.avgRating, size: 22),
            const SizedBox(width: 8),
            Text(summary),
          ],
        ),
        const SizedBox(height: 10),
        if (_post.isMine)
          Text('No puedes valorar tu propia publicación', style: TextStyle(color: Colors.grey.shade600))
        else
          Row(
            children: [
              const Text('Tu valoración: '),
              StarRating(rating: (_post.myRating ?? 0).toDouble(), size: 30, onChanged: _rate),
            ],
          ),
      ],
    );
  }

  Widget _buildCommentInput() {
    return Material(
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final e in kQuickEmojis)
                      InkWell(
                        onTap: () => _insertEmoji(e),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(e, style: const TextStyle(fontSize: 24)),
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentCtrl,
                      maxLength: 500,
                      maxLines: 3,
                      minLines: 1,
                      decoration: const InputDecoration(
                        hintText: 'Escribe un comentario...',
                        counterText: '',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _sending ? null : _sendComment,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
