import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../config.dart';
import '../theme.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/message_banner.dart';
import '../widgets/post_tile.dart';

enum _Filter { all, withNotes, noNotes }

/// Route '/favorites' - Read, Update (note) and Delete saved posts.
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final Box _box = Hive.box(kFavoritesBox);
  String? _message;
  _Filter _filter = _Filter.all;

  // UPDATE: save the personal note back to the box
  Future<void> _editNote(dynamic key, Map<String, dynamic> post) async {
    final note = await showDialog<String>(
      context: context,
      builder: (_) => _NoteDialog(initial: (post['note'] ?? '').toString()),
    );
    if (note == null) return;
    await _box.put(key, {...post, 'note': note});
    setState(() => _message = 'Note updated.');
  }

  // Ask before removing so it is never done by accident
  Future<bool> _confirmRemove(Map<String, dynamic> post) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _RemoveDialog(title: post['title'].toString()),
    );
    return ok ?? false;
  }

  Future<void> _removeWithConfirm(dynamic key, Map<String, dynamic> post) async {
    if (await _confirmRemove(post)) await _delete(key);
  }

  // DELETE: remove the post from the box
  Future<void> _delete(dynamic key) async {
    await _box.delete(key);
    setState(() => _message = 'Removed from favorites.');
  }

  void _openPost(Map<String, dynamic> post) {
    Navigator.pushNamed(context, '/details', arguments: {
      'id': post['id'],
      'title': post['title'],
      'body': post['body'],
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'Favorites'),
      body: Column(
        children: [
          if (_message != null)
            MessageBanner(
              message: _message!,
              onClose: () => setState(() => _message = null),
            ),
          Expanded(
            // READ: list everything stored in the box
            child: ValueListenableBuilder(
              valueListenable: _box.listenable(),
              builder: (context, Box box, _) {
                if (box.isEmpty) return _buildEmpty(context);

                // Read all saved posts
                final entries = box.keys
                    .map((k) =>
                        MapEntry(k, Map<String, dynamic>.from(box.get(k))))
                    .toList();
                final withNotes = entries
                    .where((e) => (e.value['note'] ?? '').toString().isNotEmpty)
                    .length;

                final visible = entries.where((e) {
                  final hasNote = (e.value['note'] ?? '').toString().isNotEmpty;
                  switch (_filter) {
                    case _Filter.withNotes:
                      return hasNote;
                    case _Filter.noNotes:
                      return !hasNote;
                    case _Filter.all:
                      return true;
                  }
                }).toList();

                return ListView(
                  padding: const EdgeInsets.only(bottom: 28),
                  children: [
                    _StatsCard(total: entries.length, withNotes: withNotes),
                    _buildFilters(),
                    if (visible.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(40),
                        child: Center(
                          child: Text(
                            'No posts match this filter.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    for (final e in visible)
                      Dismissible(
                        key: ValueKey(e.key),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          padding: const EdgeInsets.only(right: 24),
                          alignment: Alignment.centerRight,
                          decoration: BoxDecoration(
                            color: kDanger,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.delete_rounded, color: Colors.white),
                              SizedBox(width: 6),
                              Text('Remove',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        confirmDismiss: (_) => _confirmRemove(e.value),
                        onDismissed: (_) => _delete(e.key),
                        child: _FavoriteCard(
                          post: e.value,
                          onOpen: () => _openPost(e.value),
                          onEdit: () => _editNote(e.key, e.value),
                          onDelete: () => _removeWithConfirm(e.key, e.value),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    Widget chip(String label, _Filter value) {
      final selected = _filter == value;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          showCheckmark: false,
          selectedColor: kSage,
          backgroundColor: kSurface,
          side: BorderSide(color: selected ? kSage : kBorder),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          labelStyle: TextStyle(
            color: selected ? Colors.white : kInk,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          onSelected: (_) => setState(() => _filter = value),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            chip('All', _Filter.all),
            chip('With notes', _Filter.withNotes),
            chip('No notes', _Filter.noNotes),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                color: kSageLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bookmark_add_outlined,
                  size: 42, color: kPrimary),
            ),
            const SizedBox(height: 20),
            Text('Nothing saved yet',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              'Open any post and tap "Save to Favorites" to keep it here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.explore_outlined),
              label: const Text('Browse posts'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Deep green summary card at the top of the screen.
class _StatsCard extends StatelessWidget {
  final int total;
  final int withNotes;
  const _StatsCard({required this.total, required this.withNotes});

  @override
  Widget build(BuildContext context) {
    Widget stat(IconData icon, String number, String label) => Expanded(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: kGold),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(number,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          height: 1.1)),
                  Text(label,
                      style: TextStyle(
                          color: Colors.white.withAlpha(190), fontSize: 12.5)),
                ],
              ),
            ],
          ),
        );

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kPrimary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Color(0x330C3B2E), blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          stat(Icons.favorite_rounded, '$total',
              total == 1 ? 'Saved post' : 'Saved posts'),
          Container(width: 1, height: 40, color: Colors.white.withAlpha(45)),
          const SizedBox(width: 16),
          stat(Icons.sticky_note_2_rounded, '$withNotes',
              withNotes == 1 ? 'With a note' : 'With notes'),
        ],
      ),
    );
  }
}

/// One saved post (not tappable): note box with its own button, footer with Read / Remove.
class _FavoriteCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FavoriteCard({
    required this.post,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final title = post['title'].toString();
    final note = (post['note'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: cardDecoration(radius: 18),
      // Not tappable: use the "Read post" button to open the post
      child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PostAvatar(title: title, size: 40),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            IdChip(id: post['id'].toString()),
                            const SizedBox(height: 4),
                            Text(title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 4),
                            Text(post['body'].toString(),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ---------- Personal note (its own box + its own button) ----------
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(12, 8, 4, 12),
                    decoration: BoxDecoration(
                      color: note.isEmpty ? kBg : kSageSoft,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: note.isEmpty ? kBorder : kSageLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.sticky_note_2_outlined,
                                size: 16,
                                color: note.isEmpty ? kMuted : kSage),
                            const SizedBox(width: 6),
                            const Expanded(
                              child: Text('MY NOTE',
                                  style: TextStyle(
                                      color: kMuted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.6)),
                            ),
                            TextButton.icon(
                              onPressed: onEdit,
                              style: TextButton.styleFrom(
                                foregroundColor: kSage,
                                visualDensity: VisualDensity.compact,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                textStyle: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              icon: Icon(
                                  note.isEmpty
                                      ? Icons.add_rounded
                                      : Icons.edit_outlined,
                                  size: 16),
                              label: Text(note.isEmpty ? 'Add note' : 'Edit note'),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            note.isEmpty
                                ? 'No personal note yet.'
                                : note,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.45,
                              color: note.isEmpty ? kMuted : kInk,
                              fontStyle: note.isEmpty
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ---------- Card footer: about the whole post ----------
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Divider(height: 1),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: onOpen,
                      icon: const Icon(Icons.menu_book_outlined, size: 18),
                      label: const Text('Read post'),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: kDanger),
                      onPressed: onDelete,
                      icon: const Icon(Icons.heart_broken_outlined, size: 18),
                      label: const Text('Remove from Favorites'),
                    ),
                  ],
                ),
              ],
            ),
      ),
    );
  }
}

class _NoteDialog extends StatefulWidget {
  final String initial;
  const _NoteDialog({required this.initial});

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: kSurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text('Personal note',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 19)),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        maxLines: 3,
        maxLength: 120,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(hintText: 'Write a short note...'),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          style: TextButton.styleFrom(foregroundColor: kMuted),
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _ctrl.text.trim()),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// "Remove from favorites?" confirmation.
class _RemoveDialog extends StatelessWidget {
  final String title;
  const _RemoveDialog({required this.title});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: kSurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      icon: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
            color: kDangerLight, shape: BoxShape.circle),
        child: const Icon(Icons.heart_broken_rounded, color: kDanger),
      ),
      title: Text('Remove from Favorites?',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 19)),
      content: Text(
        '"$title" and its note will be removed from your favorites. '
        'The post itself is not deleted.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Keep'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: kDanger),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Remove'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}