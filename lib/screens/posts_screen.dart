import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

import '../config.dart';
import '../theme.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/message_banner.dart';
import '../widgets/post_tile.dart';

/// Route '/' - lists posts fetched from MockAPI.
class PostsScreen extends StatefulWidget {
  const PostsScreen({super.key});

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _posts = [];
  bool _loading = true;
  String? _error; // load error shown on screen
  String? _message; // POST result shown on screen
  bool _messageIsError = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ---------------- GET ----------------
  Future<void> _fetchPosts() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await http
          .get(Uri.parse(kPostsUrl))
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _posts = data
              .map((e) => <String, dynamic>{
                    'id': e['id'].toString(),
                    'title': (e['title'] ?? '').toString(),
                    'body': (e['body'] ?? '').toString(),
                  })
              .toList();
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load posts. Status code: ${response.statusCode}';
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Something went wrong while loading posts:\n$e';
        _loading = false;
      });
    }
  }

  // ---------------- POST ----------------
  Future<void> _createPost(String title, String body) async {
    try {
      final response = await http.post(
        Uri.parse(kPostsUrl),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'title': title, 'body': body}),
      );
      if (!mounted) return;

      if (response.statusCode == 201) {
        setState(() {
          _message = 'Success! Post created (status 201).';
          _messageIsError = false;
        });
        _fetchPosts(); // MockAPI really saves it, so refresh the list
      } else {
        setState(() {
          _message =
              'Failed to create post. Status code: ${response.statusCode}';
          _messageIsError = true;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _message = 'Failed to create post: $e';
        _messageIsError = true;
      });
    }
  }

  Future<void> _openNewPostDialog() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => const _NewPostDialog(),
    );
    if (result != null) {
      await _createPost(result['title']!, result['body']!);
    }
  }

  void _openDetails(Map<String, dynamic> post) {
    Navigator.pushNamed(
      context,
      '/details',
      arguments: {
        'id': post['id'],
        'title': post['title'],
        'body': post['body'],
      },
    );
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: 'Post Reader',
        actions: [
          // Favorites button with a live badge count from Hive
          ValueListenableBuilder(
            valueListenable: Hive.box(kFavoritesBox).listenable(),
            builder: (context, Box box, _) => CircleIconButton(
              tooltip: 'Favorites',
              icon: Badge(
                isLabelVisible: box.isNotEmpty,
                label: Text('${box.length}'),
                backgroundColor: kGold,
                textColor: kPrimary,
                child: const Icon(Icons.favorite_border_rounded),
              ),
              onPressed: () => Navigator.pushNamed(context, '/favorites'),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewPostDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Post'),
      ),
      body: Column(
        children: [
          if (_message != null)
            MessageBanner(
              message: _message!,
              isError: _messageIsError,
              onClose: () => setState(() => _message = null),
            ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) return _buildSkeleton();
    if (_error != null) return _buildError();

    // Search filter
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? _posts
        : _posts
            .where((p) =>
                p['title'].toString().toLowerCase().contains(q) ||
                p['body'].toString().toLowerCase().contains(q))
            .toList();

    // First post becomes the featured card (only when not searching)
    final Map<String, dynamic>? featured =
        (q.isEmpty && filtered.isNotEmpty) ? filtered.first : null;
    final rest = featured != null ? filtered.sublist(1) : filtered;

    return RefreshIndicator(
      color: kPrimary,
      onRefresh: _fetchPosts,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          if (featured != null)
            SliverToBoxAdapter(
              child: _FeaturedCard(
                post: featured,
                onTap: () => _openDetails(featured),
              ),
            ),
          if (filtered.isEmpty) SliverToBoxAdapter(child: _buildEmptyList()),
          if (rest.isNotEmpty)
            SliverToBoxAdapter(
              child: _SectionLabel(
                text: q.isEmpty ? 'Latest posts' : 'Results',
                count: rest.length,
              ),
            ),
          SliverList.builder(
            itemCount: rest.length,
            itemBuilder: (context, i) {
              final post = rest[i];
              return PostTile(
                id: post['id'],
                title: post['title'],
                body: post['body'],
                bodyLines: 2,
                trailing: const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.chevron_right_rounded,
                      color: kMuted, size: 22),
                ),
                onTap: () => _openDetails(post),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  /// Greeting + search bar
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Discover', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 2),
          Text(
            '${_posts.length} posts to read · save the ones you love',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search posts',
              prefixIcon: const Icon(Icons.search_rounded, color: kMuted),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded, color: kMuted),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyList() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration:
                const BoxDecoration(color: kSageLight, shape: BoxShape.circle),
            child:
                const Icon(Icons.search_off_rounded, size: 36, color: kPrimary),
          ),
          const SizedBox(height: 16),
          Text(
            _posts.isEmpty ? 'No posts yet' : 'No matches',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            _posts.isEmpty
                ? 'Tap "New Post" to add the first one.'
                : 'Nothing matches "$_query". Try another word.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  /// Placeholder cards while loading
  Widget _buildSkeleton() {
    Widget bar(double w, double h) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: kSageSoft,
            borderRadius: BorderRadius.circular(6),
          ),
        );

    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 12),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              bar(140, 24),
              const SizedBox(height: 10),
              bar(220, 12),
              const SizedBox(height: 18),
              bar(double.infinity, 48),
            ],
          ),
        ),
        for (int i = 0; i < 4; i++)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.all(16),
            decoration: cardDecoration(radius: 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: kSageSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      bar(60, 10),
                      const SizedBox(height: 10),
                      bar(180, 14),
                      const SizedBox(height: 10),
                      bar(double.infinity, 10),
                      const SizedBox(height: 6),
                      bar(120, 10),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                  color: kSageLight, shape: BoxShape.circle),
              child: const Icon(Icons.cloud_off_rounded,
                  size: 40, color: kPrimary),
            ),
            const SizedBox(height: 16),
            Text("Couldn't load posts",
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            MessageBanner(message: _error!, isError: true),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _fetchPosts,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Section title with a small count pill.
class _SectionLabel extends StatelessWidget {
  final String text;
  final int count;

  const _SectionLabel({required this.text, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
      child: Row(
        children: [
          Text(text, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: kSage,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('$count',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

/// Highlighted card for the top post (solid color, no gradient).
class _FeaturedCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final VoidCallback onTap;

  const _FeaturedCard({required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      decoration: BoxDecoration(
        color: kPrimary,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
              color: Color(0x330C3B2E), blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: kGold,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded, size: 14, color: kPrimary),
                          SizedBox(width: 4),
                          Text('Featured',
                              style: TextStyle(
                                  color: kPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text('#${post['id']}',
                        style: TextStyle(
                            color: Colors.white.withAlpha(200),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  post['title'].toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white, fontSize: 20, height: 1.3),
                ),
                const SizedBox(height: 6),
                Text(
                  post['body'].toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Colors.white.withAlpha(215),
                      fontSize: 13.5,
                      height: 1.5),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Text('Read now',
                        style: TextStyle(
                            color: kGold,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600)),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward_rounded, size: 16, color: kGold),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "New Post" dialog: clean header + validated title and body fields.
class _NewPostDialog extends StatefulWidget {
  const _NewPostDialog();

  @override
  State<_NewPostDialog> createState() => _NewPostDialogState();
}

class _NewPostDialogState extends State<_NewPostDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  // Neither field can be empty
  String? _required(String? v, String name) =>
      (v == null || v.trim().isEmpty) ? '$name cannot be empty' : null;

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, {
        'title': _titleCtrl.text.trim(),
        'body': _bodyCtrl.text.trim(),
      });
    }
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                color: kInk, fontSize: 13, fontWeight: FontWeight.w600)),
      );

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: kSurface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------- Header ----------
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: kSageLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.edit_note_rounded,
                        color: kPrimary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Create a post',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontSize: 19)),
                        Text('Share something with everyone',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontSize: 12.5)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: kMuted),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(height: 1),
              const SizedBox(height: 18),

              // ---------- Form ----------
              _label('Title'),
              TextFormField(
                controller: _titleCtrl,
                maxLength: 60,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'Give your post a catchy title',
                ),
                validator: (v) => _required(v, 'Title'),
              ),
              const SizedBox(height: 6),
              _label('Body'),
              TextFormField(
                controller: _bodyCtrl,
                maxLength: 300,
                minLines: 4,
                maxLines: 6,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'What do you want to say?',
                  alignLabelWithHint: true,
                ),
                validator: (v) => _required(v, 'Body'),
              ),
              const SizedBox(height: 14),

              // ---------- Buttons ----------
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: const Text('Publish'),
                    ),
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
