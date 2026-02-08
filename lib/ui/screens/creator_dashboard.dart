import 'package:flutter/material.dart';
import '../../core/models/character.dart';
import '../../core/models/story.dart';
import '../../core/services/character_service.dart';
import '../../core/services/story_service.dart';
import '../theme/lore_theme.dart';
import '../theme/responsive.dart';
import '../widgets/lore_notification.dart';
import 'character_builder.dart';
import 'story_manager.dart';
import 'character_progression.dart';

/// Creator dashboard with quick actions, active story card,
/// and recent characters. Responsive and accessible.
class CreatorDashboard extends StatefulWidget {
  const CreatorDashboard({super.key});

  @override
  State<CreatorDashboard> createState() => _CreatorDashboardState();
}

class _CreatorDashboardState extends State<CreatorDashboard> {
  final _characterService = CharacterService();
  final _storyService = StoryService();
  final String _dummyUserId = 'dummy_user';

  List<Character> _recentCharacters = [];
  Story? _activeStory;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final characters = await _characterService.getCharacters(_dummyUserId);
      final stories = await _storyService.getStories(_dummyUserId);

      setState(() {
        _recentCharacters = characters.take(5).toList();
        if (stories.isNotEmpty) {
          _activeStory = stories.first;
        }
      });
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Semantics(
          header: true,
          child: Text(
            'THE LORE KEEPER',
            style: LoreTheme.sectionTitle(
              fontSize: 20,
            ).copyWith(letterSpacing: 4),
          ),
        ),
        centerTitle: true,
        actions: [
          Semantics(
            button: true,
            label: 'Refresh dashboard',
            child: IconButton(
              icon: Icon(
                Icons.refresh,
                color: LoreTheme.goldAccent.withOpacity(0.7),
              ),
              onPressed: _loadData,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: LoreTheme.goldAccent),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: LoreTheme.goldAccent,
              child: ContentConstraint(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: Responsive.contentPadding(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildActiveStoryCard(context),
                      const SizedBox(height: 24),
                      Text('QUICK ACTIONS', style: LoreTheme.labelStyle()),
                      const SizedBox(height: 12),
                      _buildQuickActionsGrid(context),
                      const SizedBox(height: 24),
                      Text('RECENT CHARACTERS', style: LoreTheme.labelStyle()),
                      const SizedBox(height: 12),
                      _buildRecentCharacters(context),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildActiveStoryCard(BuildContext context) {
    if (_activeStory == null) {
      return Semantics(
        label: 'No active stories. Begin a new journey.',
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: LoreTheme.glassmorphism(),
          child: Column(
            children: [
              Icon(
                Icons.auto_stories,
                size: 40,
                color: LoreTheme.warmBrown.withOpacity(0.3),
              ),
              const SizedBox(height: 12),
              Text(
                'No active stories. Begin a new journey below.',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: LoreTheme.warmBrown.withOpacity(0.6),
                  fontFamily: LoreTheme.serifFont,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Semantics(
      label: 'Active story: ${_activeStory!.title}, ${_activeStory!.genre}',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: LoreTheme.glassmorphism(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_stories,
                  color: LoreTheme.goldAccent.withOpacity(0.7),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text('ACTIVE STORY', style: LoreTheme.labelStyle(fontSize: 11)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _activeStory!.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: LoreTheme.serifFont,
                color: LoreTheme.parchment,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _activeStory!.genre,
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: LoreTheme.lightBrown.withOpacity(0.7),
                fontFamily: LoreTheme.serifFont,
              ),
            ),
            const SizedBox(height: 20),
            Semantics(
              button: true,
              label: 'Resume journey for ${_activeStory!.title}',
              child: ElevatedButton.icon(
                onPressed: () {
                  LoreNotification.show(
                    context,
                    'Switch to the Journey tab to continue.',
                  );
                },
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: const Text('RESUME JOURNEY'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: LoreTheme.goldAccent.withOpacity(0.8),
                  foregroundColor: LoreTheme.inkBlack,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    final columns = Responsive.gridColumns(context);
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: columns,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.5,
      children: [
        _buildActionCard(
          context,
          'New Story',
          Icons.history_edu,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StoryManagerScreen()),
          ).then((_) => _loadData()),
        ),
        _buildActionCard(
          context,
          'New Character',
          Icons.person_add_alt_1,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CharacterBuilderScreen()),
          ).then((_) => _loadData()),
        ),
        _buildActionCard(context, 'World Notes', Icons.menu_book, () {}),
        _buildActionCard(context, 'Library', Icons.local_library, () {}),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Semantics(
      button: true,
      label: title,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: LoreTheme.deepBrown.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: LoreTheme.warmBrown.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: LoreTheme.goldAccent.withOpacity(0.7),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: LoreTheme.serifFont,
                  color: LoreTheme.parchment,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentCharacters(BuildContext context) {
    if (_recentCharacters.isEmpty) {
      return Text(
        'No characters forged yet.',
        style: TextStyle(
          fontStyle: FontStyle.italic,
          color: LoreTheme.warmBrown.withOpacity(0.5),
          fontSize: 12,
        ),
      );
    }

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _recentCharacters.length,
        itemBuilder: (context, index) {
          final char = _recentCharacters[index];
          return Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Semantics(
              button: true,
              label: '${char.name}, tap to view progression',
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CharacterProgressionScreen(character: char),
                  ),
                ),
                child: Column(
                  children: [
                    Hero(
                      tag: 'character_${char.id}',
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: LoreTheme.deepBrown,
                        child: Text(
                          char.name.isNotEmpty
                              ? char.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: LoreTheme.goldAccent,
                            fontSize: 20,
                            fontFamily: LoreTheme.serifFont,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      char.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: LoreTheme.serifFont,
                        color: LoreTheme.parchment,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
