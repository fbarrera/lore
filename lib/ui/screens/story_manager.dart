import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/story.dart';
import '../../core/services/story_service.dart';
import '../theme/lore_theme.dart';
import '../theme/responsive.dart';
import '../widgets/lore_notification.dart';
import 'story_journey.dart';

/// Story library screen for managing stories.
/// Responsive and accessible.
class StoryManagerScreen extends StatefulWidget {
  const StoryManagerScreen({super.key});

  @override
  State<StoryManagerScreen> createState() => _StoryManagerScreenState();
}

class _StoryManagerScreenState extends State<StoryManagerScreen> {
  final _storyService = StoryService();
  final String _dummyUserId = 'dummy_user';
  bool _isLoading = false;
  List<Story> _stories = [];

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  Future<void> _loadStories() async {
    setState(() => _isLoading = true);
    try {
      final stories = await _storyService.getStories(_dummyUserId);
      setState(() => _stories = stories);
    } catch (e) {
      if (mounted) {
        LoreNotification.show(
          context,
          'Failed to load stories: $e',
          isError: true,
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showStoryDialog({Story? story}) async {
    final isEditing = story != null;
    final titleController = TextEditingController(text: story?.title ?? '');
    final introController = TextEditingController(
      text: story?.introMessage ?? '',
    );
    final genreController = TextEditingController(text: story?.genre ?? '');
    final styleController = TextEditingController(
      text: story?.narrationStyle ?? '',
    );
    final notesController = TextEditingController(
      text: story?.worldNotes ?? '',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: LoreTheme.inkBlack,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: LoreTheme.warmBrown.withOpacity(0.3)),
        ),
        title: Text(
          isEditing ? 'EDIT STORY ARC' : 'NEW STORY ARC',
          style: LoreTheme.sectionTitle(fontSize: 18),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogField(titleController, 'Title', 'The Neon Rain'),
              _buildDialogField(
                introController,
                'Introductory Message',
                'The city lights hummed with static...',
                maxLines: 4,
              ),
              _buildDialogField(genreController, 'Genre', 'Cyberpunk Noir'),
              _buildDialogField(
                styleController,
                'Narration Style',
                'Gritty, First-person',
              ),
              _buildDialogField(
                notesController,
                'World Notes',
                'Magic is radioactive...',
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          if (isEditing) ...[
            TextButton(
              onPressed: () => Navigator.pop(context, 'delete'),
              child: Text(
                'DELETE',
                style: TextStyle(color: Colors.red.shade300),
              ),
            ),
          ],
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'CANCEL',
              style: TextStyle(color: LoreTheme.warmBrown.withOpacity(0.6)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: LoreTheme.goldAccent,
              foregroundColor: LoreTheme.inkBlack,
            ),
            child: Text(isEditing ? 'SAVE' : 'INSCRIBE'),
          ),
        ],
      ),
    );

    if (result == true && titleController.text.isNotEmpty) {
      setState(() => _isLoading = true);

      if (isEditing) {
        // Update existing story
        final updatedStory = Story(
          id: story!.id,
          title: titleController.text,
          description: story.description,
          introMessage: introController.text,
          genre: genreController.text,
          narrationStyle: styleController.text,
          worldNotes: notesController.text,
          isPublic: story.isPublic,
          lastUpdated: DateTime.now(),
          characterIds: story.characterIds,
        );

        try {
          await _storyService.updateStory(_dummyUserId, updatedStory);
          _loadStories();
        } catch (e) {
          if (mounted) {
            LoreNotification.show(
              context,
              'Failed to update story: $e',
              isError: true,
            );
          }
        }
      } else {
        // Create new story
        final newStory = Story(
          id: const Uuid().v4(),
          title: titleController.text,
          description: '',
          introMessage: introController.text,
          genre: genreController.text,
          narrationStyle: styleController.text,
          worldNotes: notesController.text,
          lastUpdated: DateTime.now(),
        );

        try {
          await _storyService.createStory(_dummyUserId, newStory);
          _loadStories();
        } catch (e) {
          if (mounted) {
            LoreNotification.show(
              context,
              'Failed to create story: $e',
              isError: true,
            );
          }
        }
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } else if (result == 'delete' && story != null) {
      _deleteStory(story);
    }
  }

  Future<void> _deleteStory(Story story) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: LoreTheme.inkBlack,
        title: Text(
          'DELETE STORY?',
          style: LoreTheme.sectionTitle(fontSize: 16),
        ),
        content: Text(
          'Are you sure you want to delete "${story.title}"? This cannot be undone.',
          style: TextStyle(color: LoreTheme.parchment),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'CANCEL',
              style: TextStyle(color: LoreTheme.warmBrown.withOpacity(0.6)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade300,
              foregroundColor: LoreTheme.inkBlack,
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _storyService.deleteStory(_dummyUserId, story.id);
        _loadStories();
      } catch (e) {
        if (mounted) {
          LoreNotification.show(
            context,
            'Failed to delete story: $e',
            isError: true,
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Widget _buildDialogField(
    TextEditingController controller,
    String label,
    String hint, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        textField: true,
        label: label,
        child: TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(
            color: LoreTheme.parchment,
            fontFamily: LoreTheme.serifFont,
          ),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: LoreTheme.goldAccent.withOpacity(0.7)),
            hintText: hint,
            hintStyle: TextStyle(
              color: LoreTheme.warmBrown.withOpacity(0.4),
              fontSize: 12,
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: LoreTheme.warmBrown.withOpacity(0.3),
              ),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: LoreTheme.goldAccent),
            ),
          ),
        ),
      ),
    );
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
            'THE LIBRARY OF FATES',
            style: LoreTheme.sectionTitle(fontSize: 18),
          ),
        ),
        centerTitle: true,
        actions: [
          Semantics(
            button: true,
            label: 'Create new story',
            child: IconButton(
              icon: const Icon(Icons.add, color: LoreTheme.goldAccent),
              onPressed: () => _showStoryDialog(),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: LoreTheme.goldAccent),
            )
          : _stories.isEmpty
          ? Center(
              child: Text(
                'No stories found. Begin your journey.',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: LoreTheme.warmBrown.withOpacity(0.6),
                  fontFamily: LoreTheme.serifFont,
                ),
              ),
            )
          : ContentConstraint(
              child: ListView.builder(
                padding: Responsive.contentPadding(context),
                itemCount: _stories.length,
                itemBuilder: (context, index) {
                  final story = _stories[index];
                  return _buildStoryCard(story);
                },
              ),
            ),
    );
  }

  Widget _buildStoryCard(Story story) {
    return Semantics(
      button: true,
      label: '${story.title}, ${story.genre}. Tap to enter.',
      child: Card(
        color: LoreTheme.deepBrown.withOpacity(0.3),
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: LoreTheme.warmBrown.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(
                story.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: LoreTheme.serifFont,
                  color: LoreTheme.parchment,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'Genre: ${story.genre}',
                    style: TextStyle(
                      color: LoreTheme.lightBrown.withOpacity(0.7),
                    ),
                  ),
                  if (story.introMessage.isNotEmpty)
                    Text(
                      story.introMessage.length > 60
                          ? '${story.introMessage.substring(0, 60)}...'
                          : story.introMessage,
                      style: TextStyle(
                        color: LoreTheme.warmBrown.withOpacity(0.5),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  Text(
                    'Updated: ${story.lastUpdated.toString().split('.')[0]}',
                    style: TextStyle(
                      color: LoreTheme.warmBrown.withOpacity(0.4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Edit button
                  Semantics(
                    button: true,
                    label: 'Edit ${story.title}',
                    child: IconButton(
                      icon: Icon(
                        Icons.edit_outlined,
                        color: LoreTheme.goldAccent.withOpacity(0.7),
                      ),
                      onPressed: () => _showStoryDialog(story: story),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: LoreTheme.goldAccent.withOpacity(0.5),
                  ),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StoryJourneyScreen(story: story),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
