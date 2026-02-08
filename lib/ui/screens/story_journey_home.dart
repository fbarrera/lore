import 'package:flutter/material.dart';
import '../../core/models/story.dart';
import '../../core/services/story_service.dart';
import '../../core/services/ai_service.dart';
import '../theme/lore_theme.dart';
import '../theme/responsive.dart';
import '../widgets/story_chat_view.dart';
import 'story_journey.dart';

/// Home screen for the Journey tab. Shows active stories and allows
/// entering a story journey, or uses the LlmChatView for quick play.
class StoryJourneyHome extends StatefulWidget {
  const StoryJourneyHome({super.key});

  @override
  State<StoryJourneyHome> createState() => _StoryJourneyHomeState();
}

class _StoryJourneyHomeState extends State<StoryJourneyHome> {
  final _storyService = StoryService();
  final _aiService = AIService();
  final String _dummyUserId = 'dummy_user';

  List<Story> _stories = [];
  bool _isLoading = true;
  Story? _quickPlayStory;

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  Future<void> _loadStories() async {
    setState(() => _isLoading = true);
    try {
      final stories = await _storyService.getStories(_dummyUserId);
      setState(() {
        _stories = stories;
        if (stories.isNotEmpty) {
          _quickPlayStory = stories.first;
        }
      });
    } catch (e) {
      debugPrint('Failed to load stories: $e');
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
            'THE JOURNEY',
            style: LoreTheme.sectionTitle(fontSize: 18),
          ),
        ),
        centerTitle: true,
        actions: [
          Semantics(
            button: true,
            label: 'Refresh stories',
            child: IconButton(
              icon: Icon(
                Icons.refresh,
                color: LoreTheme.goldAccent.withOpacity(0.7),
              ),
              onPressed: _loadStories,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: LoreTheme.goldAccent),
            )
          : _stories.isEmpty
          ? _buildEmptyState()
          : _buildContent(context),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_stories,
              size: 64,
              color: LoreTheme.warmBrown.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No stories await you yet.',
              style: TextStyle(
                color: LoreTheme.lightBrown.withOpacity(0.7),
                fontFamily: LoreTheme.serifFont,
                fontSize: 18,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a story in the Library to begin your journey.',
              style: TextStyle(
                color: LoreTheme.warmBrown.withOpacity(0.5),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return ContentConstraint(
      child: SingleChildScrollView(
        padding: Responsive.contentPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick play with AI Toolkit chat
            if (_quickPlayStory != null) ...[
              Text('QUICK PLAY', style: LoreTheme.labelStyle()),
              const SizedBox(height: 8),
              Container(
                height: 400,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: LoreTheme.warmBrown.withOpacity(0.2),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: StoryChatView(
                  story: _quickPlayStory!,
                  aiService: _aiService,
                  onMessageSent: (msg) {
                    debugPrint('Quick play message: $msg');
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Story list
            Text('YOUR STORIES', style: LoreTheme.labelStyle()),
            const SizedBox(height: 12),
            ..._stories.map((story) => _buildStoryCard(context, story)),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryCard(BuildContext context, Story story) {
    return Semantics(
      button: true,
      label: '${story.title}, ${story.genre}. Tap to enter journey.',
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => StoryJourneyScreen(story: story)),
          );
        },
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: LoreTheme.deepBrown.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: LoreTheme.warmBrown.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              // Story icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: LoreTheme.deepBrown.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.auto_stories,
                  color: LoreTheme.goldAccent.withOpacity(0.6),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      story.title,
                      style: const TextStyle(
                        color: LoreTheme.parchment,
                        fontWeight: FontWeight.bold,
                        fontFamily: LoreTheme.serifFont,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      story.genre.isNotEmpty ? story.genre : 'Uncharted',
                      style: TextStyle(
                        color: LoreTheme.lightBrown.withOpacity(0.6),
                        fontStyle: FontStyle.italic,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Updated: ${_formatDate(story.lastUpdated)}',
                      style: TextStyle(
                        color: LoreTheme.warmBrown.withOpacity(0.4),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: LoreTheme.goldAccent.withOpacity(0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
