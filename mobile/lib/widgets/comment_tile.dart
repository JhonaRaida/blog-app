import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/comment.dart';
import 'reaction_bar.dart';

class CommentTile extends StatelessWidget {
  const CommentTile({super.key, required this.comment, required this.onReact});

  final Comment comment;
  final ValueChanged<String> onReact;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd/MM/yyyy HH:mm').format(comment.createdAt);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            child: Text(comment.authorName.isEmpty ? '?' : comment.authorName[0].toUpperCase()),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(comment.authorName, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(date, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                const SizedBox(height: 4),
                Text(comment.content, style: const TextStyle(fontSize: 15)),
                const SizedBox(height: 6),
                ReactionBar(reactions: comment.reactions, onReact: onReact),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
