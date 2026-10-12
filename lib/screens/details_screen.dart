import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../config.dart';
import '../theme.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/message_banner.dart';
import '../widgets/post_tile.dart';

/// Route '/details' - clean article-style reader for one post (Hive Create).
class DetailsScreen extends StatefulWidget {
  const DetailsScreen({super.key});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  String? _message;
  bool _messageIsError = false;

  /// One button: saves the post, or removes it if it's already saved.
  Future<void> _toggleFavorite(Map<String, dynamic> post) async {
    final key = post['id'].toString();
    if (Hive.box(kFavoritesBox).containsKey(key)) {
      await _removeFromFavorites(key);
    } else {
      _saveToFavorites(post);
    }
  }

  // DELETE: un-save the post (asks first only if a note would be lost)
  Future<void> _removeFromFavorites(String key) async {
    final box = Hive.box(kFavoritesBox);
    final saved = Map<String, dynamic>.from(box.get(key));
    final note = (saved['note'] ?? '').toString();

    if (note.isNotEmpty) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => const _RemoveNoteWarning(),
      );
      if (ok != true) return;
    }

    await box.delete(key);
    if (!mounted) return;
    setState(() {
      _message = 'Removed from favorites.';
      _messageIsError = false;
    });
  }

  void _saveToFavorites(Map<String, dynamic> post) {
    final box = Hive.box(kFavoritesBox);
    final key = post['id'].toString();

    // CREATE: id is the key so the same post is never saved twice
    box.put(key, {
      'id': post['id'],
      'title': post['title'],
      'body': post['body'],
      'note': '',
    });
    setState(() {
      _message = 'Saved to favorites!';
      _messageIsError = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Arguments passed from the Posts / Favorites screen
    final args =
        _readArgs(ModalRoute.of(context)?.settings.arguments);
    // Opened without a post (e.g. browser refresh / hot restart) -> safe screen
    if (args == null) return const _NoPostView();

    final box = Hive.box(kFavoritesBox);

    final String id = args['id'].toString();
    final String title = (args['title'] ?? '').toString();
    final String body = (args['body'] ?? '').toString().trim();

    // Real stats computed from the post itself
    final words = body.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final minutes = (words / 200).ceil().clamp(1, 99);

    final bodyStyle = Theme.of(context)
        .textTheme
        .bodyLarge
        ?.copyWith(color: Colors.white.withAlpha(225));

    return Scaffold(
      backgroundColor: kPrimary,
      appBar: AppTopBar(
        title: 'Article',
        dark: true,
        actions: [
          // Live favorites count; heart fills when THIS post is saved
          ValueListenableBuilder(
            valueListenable: box.listenable(),
            builder: (context, Box b, _) {
              final thisSaved = b.containsKey(id);
              return CircleIconButton(
                dark: true,
                tooltip: 'Favorites (${b.length})',
                icon: Badge(
                  isLabelVisible: b.isNotEmpty,
                  label: Text('${b.length}'),
                  backgroundColor: kGold,
                  textColor: kPrimary,
                  child: Icon(
                    thisSaved
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: thisSaved ? kGold : Colors.white,
                  ),
                ),
                onPressed: () => Navigator.pushNamed(context, '/favorites'),
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          if (_message != null)
            MessageBanner(
              message: _message!,
              isError: _messageIsError,
              onClose: () => setState(() => _message = null),
            ),

          // ---------- Headline ----------
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IdChip(id: id, color: kGold),
                const SizedBox(height: 10),
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(color: Colors.white)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    PostAvatar(title: title, size: 36),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Wrap(
                        spacing: 14,
                        runSpacing: 4,
                        children: [
                          _Meta(
                              icon: Icons.schedule_rounded,
                              text: '$minutes min read'),
                          _Meta(icon: Icons.notes_rounded, text: '$words words'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Divider(height: 1, color: Color(0x33FFFFFF)),
          ),

          // ---------- Body with drop-cap first letter ----------
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: body.isEmpty
                ? Text('This post has no content.',
                    style: TextStyle(color: Colors.white.withAlpha(180)))
                : SelectableText.rich(
                    TextSpan(
                      style: bodyStyle,
                      children: [
                        TextSpan(
                          text: body[0],
                          style: const TextStyle(
                            fontSize: 36,
                            height: 1.1,
                            fontWeight: FontWeight.w700,
                            color: kGold,
                          ),
                        ),
                        TextSpan(text: body.substring(1)),
                      ],
                    ),
                  ),
          ),
        ],
      ),

      // ---------- Sticky save bar ----------
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            // Rebuilds automatically when the box changes
            child: ValueListenableBuilder(
              valueListenable: box.listenable(),
              builder: (context, Box b, _) {
                final saved = b.containsKey(id);
                return SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: saved
                      // Saved: tapping again removes it from favorites
                      ? OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kSage,
                            side: const BorderSide(color: kSage, width: 1.4),
                          ),
                          onPressed: () => _toggleFavorite(args),
                          icon: const Icon(Icons.favorite_rounded),
                          label: const Text('Saved · Tap to remove'),
                        )
                      : FilledButton.icon(
                          style: FilledButton.styleFrom(
                              backgroundColor: kSage),
                          onPressed: () => _toggleFavorite(args),
                          icon: const Icon(Icons.favorite_border_rounded),
                          label: const Text('Save to Favorites'),
                        ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Asked only when removing a saved post that has a personal note.
class _RemoveNoteWarning extends StatelessWidget {
  const _RemoveNoteWarning();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: kSurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text('Remove from Favorites?',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 19)),
      content: Text(
        'This post has a personal note. Removing it from favorites will also delete the note.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          style: TextButton.styleFrom(foregroundColor: kMuted),
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Keep'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: kDanger),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Remove'),
        ),
      ],
    );
  }
}

/// Safely converts route arguments into a post map (or null if missing).
Map<String, dynamic>? _readArgs(Object? raw) {
  if (raw is Map) {
    final map = Map<String, dynamic>.from(raw);
    if (map['id'] != null) return map;
  }
  return null;
}

/// Shown when the details page has no post to display.
class _NoPostView extends StatelessWidget {
  const _NoPostView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimary,
      appBar: const AppTopBar(title: 'Article', dark: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.article_outlined,
                    size: 40, color: kGold),
              ),
              const SizedBox(height: 18),
              const Text('Post not available',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                'This page was opened without a post. Go back to the list and pick one.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white.withAlpha(190), fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                    backgroundColor: kGold, foregroundColor: kPrimary),
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context, '/', (route) => false),
                icon: const Icon(Icons.list_alt_rounded),
                label: const Text('Back to posts'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Meta({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.white.withAlpha(170)),
        const SizedBox(width: 4),
        Text(text,
            style: TextStyle(color: Colors.white.withAlpha(190), fontSize: 13)),
      ],
    );
  }
}