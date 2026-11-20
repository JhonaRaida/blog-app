import 'package:flutter/material.dart';

import '../config/constants.dart';
import '../models/comment.dart';

/// Fila de reacciones de un comentario + botón para agregar una nueva.
class ReactionBar extends StatelessWidget {
  const ReactionBar({super.key, required this.reactions, required this.onReact});

  final List<Reaction> reactions;
  final ValueChanged<String> onReact;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final r in reactions)
          GestureDetector(
            onTap: () => onReact(r.emoji),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: r.reacted ? color.withAlpha(35) : Colors.grey.shade200,
                border: Border.all(color: r.reacted ? color : Colors.transparent),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text('${r.emoji} ${r.count}', style: const TextStyle(fontSize: 13)),
            ),
          ),
        PopupMenuButton<String>(
          tooltip: 'Reaccionar',
          padding: EdgeInsets.zero,
          onSelected: onReact,
          itemBuilder: (_) => [
            PopupMenuItem<String>(
              enabled: false,
              padding: EdgeInsets.zero,
              child: _EmojiPicker(onPick: onReact),
            ),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.add_reaction_outlined, size: 16),
          ),
        ),
      ],
    );
  }
}

class _EmojiPicker extends StatelessWidget {
  const _EmojiPicker({required this.onPick});

  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final e in kReactions)
          InkWell(
            onTap: () {
              Navigator.of(context).pop();
              onPick(e);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Text(e, style: const TextStyle(fontSize: 24)),
            ),
          ),
      ],
    );
  }
}
