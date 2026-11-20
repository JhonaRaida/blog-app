import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/post.dart';
import 'star_rating.dart';

class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post, required this.onTap});

  final Post post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd/MM/yyyy').format(post.createdAt);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(post.title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                '${post.isMine ? 'Tú' : post.authorName} · $date',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              Text(post.content, maxLines: 3, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 10),
              Row(
                children: [
                  StarRating(rating: post.avgRating, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    post.ratingCount == 0 ? 'Sin votos' : '${post.avgRating} (${post.ratingCount})',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const Spacer(),
                  const Icon(Icons.chat_bubble_outline, size: 16),
                  const SizedBox(width: 4),
                  Text('${post.commentCount}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
