import 'package:flutter/material.dart';

import '../theme.dart';

/// Clean post card: soft lavender avatar, "Post #id" chip, title, body.
class PostTile extends StatelessWidget {
  final String id;
  final String title;
  final String body;
  final VoidCallback? onTap;
  final Widget? footer;
  final Widget? trailing;
  final int bodyLines;

  const PostTile({
    super.key,
    required this.id,
    required this.title,
    required this.body,
    this.onTap,
    this.footer,
    this.trailing,
    this.bodyLines = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: cardDecoration(radius: 18),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PostAvatar(title: title, size: 44),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IdChip(id: id),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        body,
                        maxLines: bodyLines,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (footer != null) ...[
                        const SizedBox(height: 10),
                        footer!,
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Round avatar showing the first letter of the title (flat, no gradient).
class PostAvatar extends StatelessWidget {
  final String title;
  final double size;

  const PostAvatar({super.key, required this.title, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final t = title.trim();
    final initial = t.isEmpty ? '#' : t[0].toUpperCase();

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: kSageLight,
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Text(
        initial,
        style: TextStyle(
          color: kPrimaryDark,
          fontSize: size * 0.4,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Small "Post #id" label.
class IdChip extends StatelessWidget {
  final String id;
  final String prefix;
  final Color color;

  const IdChip({
    super.key,
    required this.id,
    this.prefix = 'Post',
    this.color = kBronze,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      '$prefix #$id'.toUpperCase(),
      style: TextStyle(
        color: color,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
      ),
    );
  }
}