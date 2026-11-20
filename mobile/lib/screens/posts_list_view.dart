import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/post.dart';
import '../services/post_service.dart';
import '../widgets/post_card.dart';
import 'post_detail_screen.dart';

/// Lista de posts. Recibe la función que los carga (todos o solo los míos).
class PostsListView extends StatefulWidget {
  const PostsListView({super.key, required this.loader, required this.emptyText});

  final Future<List<Post>> Function(PostService service) loader;
  final String emptyText;

  @override
  State<PostsListView> createState() => _PostsListViewState();
}

class _PostsListViewState extends State<PostsListView> {
  List<Post>? _posts;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _posts == null;
      _error = null;
    });
    try {
      final posts = await widget.loader(context.read<PostService>());
      if (mounted) setState(() => _posts = posts);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(Post post) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
    );
    if (mounted) _load(); // al volver puede haber cambiado la valoración o los comentarios
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null && _posts == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: _load, child: const Text('Reintentar')),
          ],
        ),
      );
    }
    final posts = _posts ?? [];
    return RefreshIndicator(
      onRefresh: _load,
      child: posts.isEmpty
          ? ListView(
              children: [
                const SizedBox(height: 120),
                Center(child: Text(widget.emptyText)),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 6, bottom: 80),
              itemCount: posts.length,
              itemBuilder: (_, i) => PostCard(post: posts[i], onTap: () => _open(posts[i])),
            ),
    );
  }
}
