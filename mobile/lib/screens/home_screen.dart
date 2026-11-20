import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'create_post_screen.dart';
import 'posts_list_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _version = 0; // al cambiar, las listas se vuelven a crear y recargan

  Future<void> _newPost() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreatePostScreen()),
    );
    if (created == true && mounted) setState(() => _version++);
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que quieres salir?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Salir')),
        ],
      ),
    );
    if (ok == true && mounted) context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Hola, ${user?.name.split(' ').first ?? ''}'),
          actions: [
            IconButton(
              tooltip: 'Cerrar sesión',
              icon: const Icon(Icons.logout),
              onPressed: _confirmLogout,
            ),
          ],
          bottom: const TabBar(
            tabs: [Tab(text: 'Todos'), Tab(text: 'Mis posts')],
          ),
        ),
        body: TabBarView(
          children: [
            PostsListView(
              key: ValueKey('all-$_version'),
              loader: (s) => s.getPosts(),
              emptyText: 'Aún no hay publicaciones',
            ),
            PostsListView(
              key: ValueKey('mine-$_version'),
              loader: (s) => s.getMyPosts(),
              emptyText: 'Todavía no has publicado nada',
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _newPost,
          icon: const Icon(Icons.edit),
          label: const Text('Nuevo post'),
        ),
      ),
    );
  }
}
