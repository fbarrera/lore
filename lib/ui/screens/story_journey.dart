import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/story.dart';
import '../../core/models/character.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/character_service.dart';
import '../../core/services/story_service.dart';
import '../../core/services/progression_service.dart';
import '../theme/lore_theme.dart';
import '../theme/responsive.dart';
import '../widgets/directors_panel.dart';
import '../widgets/lore_notification.dart';
import '../widgets/story_bookmark.dart';
import '../widgets/story_search.dart';
import '../widgets/story_chat_view.dart';
import 'character_builder.dart';
import 'character_progression.dart';

/// The main story journey screen with immersive chat, Director's Panel,
/// bookmarks, search, chapter progress, and character overlays.
class StoryJourneyScreen extends StatefulWidget {
  final Story story;

  const StoryJourneyScreen({super.key, required this.story});

  @override
  State<StoryJourneyScreen> createState() => _StoryJourneyScreenState();
}

class _StoryJourneyScreenState extends State<StoryJourneyScreen>
    with TickerProviderStateMixin {
  final _aiService = AIService();
  final _characterService = CharacterService();
  final _storyService = StoryService();
  final _progressionService = ProgressionService();
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _inputFocusNode = FocusNode();

  final List<Map<String, String>> _messages = [];
  List<Character> _storyCharacters = [];
  List<Character> _allCharacters = [];
  List<StoryBookmark> _bookmarks = [];
  bool _isLoading = false;
  bool _showSearch = false;
  bool _showCharacterOverlay = false;
  int _currentChapter = 1;
  int _messagesSinceChapter = 0;

  // Mutable story settings (updated via Director's Panel)
  late String _narrationStyle;
  late String _worldNotes;

  late final AnimationController _overlayAnimController;

  @override
  void initState() {
    super.initState();
    _narrationStyle = widget.story.narrationStyle;
    _worldNotes = widget.story.worldNotes;
    _overlayAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadCharacters();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    _overlayAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadCharacters() async {
    try {
      final chars = await _characterService.getCharacters('dummy_user');
      setState(() {
        _allCharacters = chars;
        _storyCharacters = chars
            .where((c) => widget.story.characterIds.contains(c.id))
            .toList();
      });
    } catch (e) {
      debugPrint('Failed to load characters: $e');
    }
  }

  List<Character> get _availableCharacters => _allCharacters
      .where((c) => !_storyCharacters.any((sc) => sc.id == c.id))
      .toList();

  Future<void> _addCharacterToStory(Character character) async {
    final updatedIds = List<String>.from(widget.story.characterIds)
      ..add(character.id);
    final updatedStory = Story(
      id: widget.story.id,
      title: widget.story.title,
      description: widget.story.description,
      introMessage: widget.story.introMessage,
      genre: widget.story.genre,
      narrationStyle: widget.story.narrationStyle,
      worldNotes: widget.story.worldNotes,
      isPublic: widget.story.isPublic,
      lastUpdated: DateTime.now(),
      characterIds: updatedIds,
    );

    try {
      await _storyService.updateStory('dummy_user', updatedStory);
      widget.story.characterIds.add(character.id);
      setState(() {
        _storyCharacters.add(character);
      });
      if (mounted) {
        LoreNotification.show(
          context,
          '${character.name} has joined your story.',
        );
      }
    } catch (e) {
      if (mounted) {
        LoreNotification.show(
          context,
          'Failed to add character: $e',
          isError: true,
        );
      }
    }
  }

  Future<void> _removeCharacterFromStory(Character character) async {
    final updatedIds = List<String>.from(widget.story.characterIds)
      ..remove(character.id);
    final updatedStory = Story(
      id: widget.story.id,
      title: widget.story.title,
      description: widget.story.description,
      introMessage: widget.story.introMessage,
      genre: widget.story.genre,
      narrationStyle: widget.story.narrationStyle,
      worldNotes: widget.story.worldNotes,
      isPublic: widget.story.isPublic,
      lastUpdated: DateTime.now(),
      characterIds: updatedIds,
    );

    try {
      await _storyService.updateStory('dummy_user', updatedStory);
      widget.story.characterIds.remove(character.id);
      setState(() {
        _storyCharacters.removeWhere((c) => c.id == character.id);
      });
      if (mounted) {
        LoreNotification.show(
          context,
          '${character.name} has left your story.',
        );
      }
    } catch (e) {
      if (mounted) {
        LoreNotification.show(
          context,
          'Failed to remove character: $e',
          isError: true,
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _inputController.clear();
      _isLoading = true;
      _messagesSinceChapter++;
    });

    _scrollToBottom();

    try {
      final response = await _aiService.processStorySegment(
        text: text,
        storyId: widget.story.id,
        narrationStyle: _narrationStyle,
        worldNotes: _worldNotes,
        userPersona: 'The Protagonist',
        characterIds: widget.story.characterIds,
      );

      setState(() {
        _messages.add({'role': 'ai', 'content': response});
        _isLoading = false;
        _messagesSinceChapter++;
      });

      _scrollToBottom();

      // Auto-advance chapter every ~10 exchanges
      if (_messagesSinceChapter >= 20) {
        setState(() {
          _currentChapter++;
          _messagesSinceChapter = 0;
        });
      }

      // Trigger progression analysis in background
      _progressionService
          .processProgression(
            userId: 'dummy_user',
            storyId: widget.story.id,
            lastInteraction: "User: $text\nAI: $response",
            characters: _storyCharacters,
          )
          .then((_) => _loadCharacters());
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        LoreNotification.show(
          context,
          'The story was interrupted: $e',
          isError: true,
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _addBookmark() {
    if (_messages.isEmpty) return;
    final lastMsg = _messages.last;
    final bookmark = StoryBookmark(
      id: const Uuid().v4(),
      title: 'Chapter $_currentChapter — Moment ${_bookmarks.length + 1}',
      preview: (lastMsg['content'] ?? '').length > 80
          ? '${(lastMsg['content'] ?? '').substring(0, 80)}...'
          : lastMsg['content'] ?? '',
      timestamp: DateTime.now(),
      messageIndex: _messages.length - 1,
    );
    setState(() => _bookmarks.add(bookmark));
    LoreNotification.show(
      context,
      'Moment bookmarked',
      duration: const Duration(seconds: 1),
    );
  }

  void _scrollToMessage(int index) {
    // Close search if open
    setState(() => _showSearch = false);
    // Scroll to approximate position
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final estimatedOffset = index * 120.0;
        _scrollController.animateTo(
          estimatedOffset.clamp(0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.deviceType(context) == DeviceType.desktop;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: LoreTheme.backgroundGradient,
        child: SafeArea(
          child: Stack(
            children: [
              // Main content
              Column(
                children: [
                  _buildAppBar(context),
                  // Chapter progress
                  ChapterProgressIndicator(
                    currentChapter: _currentChapter,
                    totalChapters: 10,
                    chapterTitle: _currentChapter == 1
                        ? 'The Beginning'
                        : 'Chapter $_currentChapter',
                    progress: (_messagesSinceChapter / 20).clamp(0.0, 1.0),
                  ),
                  // Chat area
                  Expanded(
                    child: isDesktop
                        ? _buildDesktopLayout(context)
                        : _buildMobileLayout(context),
                  ),
                ],
              ),
              // Search overlay
              if (_showSearch)
                StorySearchOverlay(
                  messages: _messages,
                  onResultTap: _scrollToMessage,
                  onClose: () => setState(() => _showSearch = false),
                ),
              // Character overlay
              if (_showCharacterOverlay) _buildCharacterOverlay(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Semantics(
      header: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Semantics(
              button: true,
              label: 'Go back',
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: LoreTheme.lightBrown),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: Text(
                widget.story.title.toUpperCase(),
                style: LoreTheme.sectionTitle(fontSize: 16),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Search button
            Semantics(
              button: true,
              label: 'Search story history',
              child: IconButton(
                icon: Icon(
                  Icons.search,
                  color: LoreTheme.goldAccent.withOpacity(0.7),
                ),
                onPressed: () => setState(() => _showSearch = true),
                tooltip: 'Search',
              ),
            ),
            // Bookmark button
            Semantics(
              button: true,
              label: 'Bookmark this moment',
              child: IconButton(
                icon: Icon(
                  Icons.bookmark_add_outlined,
                  color: LoreTheme.goldAccent.withOpacity(0.7),
                ),
                onPressed: _addBookmark,
                tooltip: 'Bookmark',
              ),
            ),
            // Director's Panel button
            Semantics(
              button: true,
              label: "Open Director's Panel",
              child: IconButton(
                icon: const Icon(Icons.tune, color: LoreTheme.goldAccent),
                onPressed: () => _openDirectorsPanel(context),
                tooltip: "Director's Panel",
              ),
            ),
            // Characters button
            Semantics(
              button: true,
              label: 'View characters',
              child: IconButton(
                icon: Icon(
                  Icons.people,
                  color: LoreTheme.goldAccent.withOpacity(0.7),
                ),
                onPressed: () {
                  setState(
                    () => _showCharacterOverlay = !_showCharacterOverlay,
                  );
                },
                tooltip: 'Characters',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        Expanded(child: _buildMessageList(context)),
        if (_isLoading) _buildLoadingIndicator(),
        _buildInputBar(context),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        // Main chat area
        Expanded(
          flex: 3,
          child: Column(
            children: [
              Expanded(child: _buildMessageList(context)),
              if (_isLoading) _buildLoadingIndicator(),
              _buildInputBar(context),
            ],
          ),
        ),
        // Side panel with bookmarks
        SizedBox(
          width: 280,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: LoreTheme.warmBrown.withOpacity(0.15)),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: StoryBookmarkPanel(
                bookmarks: _bookmarks,
                onBookmarkTap: (b) => _scrollToMessage(b.messageIndex),
                onBookmarkDelete: (b) {
                  setState(() => _bookmarks.remove(b));
                },
                onAddBookmark: _addBookmark,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageList(BuildContext context) {
    // Show intro message if available and no messages yet
    final showIntro = widget.story.introMessage.isNotEmpty && _messages.isEmpty;

    return Semantics(
      label: 'Story conversation with ${_messages.length} messages',
      child: ListView.builder(
        controller: _scrollController,
        padding: Responsive.contentPadding(context),
        itemCount: _messages.length + (showIntro ? 1 : 0),
        itemBuilder: (context, index) {
          // Show intro message at the top
          if (showIntro && index == 0) {
            return _buildIntroMessage();
          }
          final msgIndex = showIntro ? index - 1 : index;
          final msg = _messages[msgIndex];
          final isUser = msg['role'] == 'user';
          final content = msg['content'] ?? '';

          return Semantics(
            label: '${isUser ? "You said" : "The narrator says"}: $content',
            child: Align(
              alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.all(14),
                constraints: BoxConstraints(
                  maxWidth: Responsive.chatBubbleMaxWidth(context),
                ),
                decoration: isUser
                    ? LoreTheme.userBubble()
                    : LoreTheme.narratorBubble(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Role label
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isUser ? Icons.person : Icons.auto_stories,
                          size: 12,
                          color: isUser
                              ? Colors.white.withOpacity(0.5)
                              : LoreTheme.goldAccent.withOpacity(0.6),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isUser ? 'YOU' : 'NARRATOR',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isUser
                                ? Colors.white.withOpacity(0.5)
                                : LoreTheme.goldAccent.withOpacity(0.6),
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Message text
                    SelectableText(
                      content,
                      style: isUser
                          ? LoreTheme.userText()
                          : LoreTheme.narratorText(),
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

  Widget _buildIntroMessage() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            LoreTheme.goldAccent.withOpacity(0.15),
            LoreTheme.deepBrown.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LoreTheme.goldAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_stories, color: LoreTheme.goldAccent, size: 18),
              const SizedBox(width: 8),
              Text(
                'THE BEGINNING',
                style: TextStyle(
                  color: LoreTheme.goldAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SelectableText(
            widget.story.introMessage,
            style: LoreTheme.narratorText(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Semantics(
      label: 'The narrator is composing a response',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(children: [const TypingIndicator(), const Spacer()]),
      ),
    );
  }

  Widget _buildInputBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LoreTheme.inkBlack.withOpacity(0.8),
        border: Border(
          top: BorderSide(color: LoreTheme.warmBrown.withOpacity(0.15)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                textField: true,
                label: 'Type your action or dialogue',
                child: KeyboardListener(
                  focusNode: FocusNode(),
                  onKeyEvent: (event) {
                    // Ctrl+Enter to send on desktop
                    if (event is KeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.enter &&
                        HardwareKeyboard.instance.isControlPressed) {
                      _sendMessage();
                    }
                  },
                  child: TextField(
                    controller: _inputController,
                    focusNode: _inputFocusNode,
                    style: LoreTheme.userText(fontSize: 14),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    decoration: InputDecoration(
                      hintText: 'What do you do?',
                      hintStyle: TextStyle(
                        color: LoreTheme.warmBrown.withOpacity(0.4),
                        fontStyle: FontStyle.italic,
                        fontFamily: LoreTheme.serifFont,
                      ),
                      filled: true,
                      fillColor: LoreTheme.deepBrown.withOpacity(0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Semantics(
              button: true,
              label: 'Send message',
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: _isLoading
                      ? LoreTheme.deepBrown
                      : LoreTheme.goldAccent.withOpacity(0.8),
                  child: IconButton(
                    icon: Icon(
                      _isLoading ? Icons.hourglass_top : Icons.send_rounded,
                      color: _isLoading
                          ? LoreTheme.warmBrown
                          : LoreTheme.inkBlack,
                      size: 20,
                    ),
                    onPressed: _isLoading ? null : _sendMessage,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCharacterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: LoreTheme.inkBlack,
      builder: (context) => _buildAddCharacterSheet(context),
    );
  }

  Widget _buildAddCharacterSheet(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.person_add, color: LoreTheme.goldAccent),
              const SizedBox(width: 12),
              Text(
                'ADD CHARACTER',
                style: LoreTheme.sectionTitle(fontSize: 16),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: LoreTheme.lightBrown),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        Divider(color: LoreTheme.warmBrown.withValues(alpha: 0.2)),
        Expanded(
          child: _availableCharacters.isEmpty
              ? Center(
                  child: Text(
                    'All your characters are already in this story.',
                    style: TextStyle(
                      color: LoreTheme.warmBrown.withValues(alpha: 0.5),
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _availableCharacters.length,
                  itemBuilder: (context, index) {
                    final char = _availableCharacters[index];
                    return _buildSelectableCharacterCard(context, char);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSelectableCharacterCard(BuildContext context, Character char) {
    return Card(
      color: LoreTheme.deepBrown.withValues(alpha: 0.3),
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: LoreTheme.warmBrown.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          _addCharacterToStory(char);
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: LoreTheme.deepBrown,
                child: Text(
                  char.name.isNotEmpty ? char.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: LoreTheme.goldAccent,
                    fontWeight: FontWeight.bold,
                    fontFamily: LoreTheme.serifFont,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      char.name,
                      style: const TextStyle(
                        color: LoreTheme.parchment,
                        fontWeight: FontWeight.bold,
                        fontFamily: LoreTheme.serifFont,
                      ),
                    ),
                    Text(
                      '${char.race} · ${char.occupation}',
                      style: TextStyle(
                        color: LoreTheme.lightBrown.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.add_circle_outline,
                color: LoreTheme.goldAccent.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCharacterOverlay(BuildContext context) {
    return Positioned(
      right: 0,
      top: 0,
      bottom: 0,
      width: Responsive.value(context, mobile: 280.0, tablet: 320.0),
      child: GestureDetector(
        onTap: () {}, // Prevent tap-through
        child: Container(
          decoration: BoxDecoration(
            color: LoreTheme.inkBlack.withOpacity(0.95),
            border: Border(
              left: BorderSide(color: LoreTheme.warmBrown.withOpacity(0.2)),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(-4, 0),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.people, color: LoreTheme.goldAccent, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'CHARACTERS',
                        style: LoreTheme.sectionTitle(fontSize: 14),
                      ),
                      const Spacer(),
                      // Add character button
                      Semantics(
                        button: true,
                        label: 'Add character to story',
                        child: TextButton.icon(
                          onPressed: _showAddCharacterSheet,
                          icon: Icon(
                            Icons.add,
                            color: LoreTheme.goldAccent,
                            size: 18,
                          ),
                          label: Text(
                            'ADD',
                            style: TextStyle(
                              color: LoreTheme.goldAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Semantics(
                        button: true,
                        label: 'Close character panel',
                        child: IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: LoreTheme.lightBrown,
                            size: 20,
                          ),
                          onPressed: () =>
                              setState(() => _showCharacterOverlay = false),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(color: LoreTheme.warmBrown.withValues(alpha: 0.2)),
                // Story characters section
                if (_storyCharacters.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Text(
                      'IN THIS STORY',
                      style: TextStyle(
                        color: LoreTheme.warmBrown.withValues(alpha: 0.6),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
                // Story character list
                Expanded(
                  child: _storyCharacters.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 48,
                                color: LoreTheme.warmBrown.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No characters in this story yet.',
                                style: TextStyle(
                                  color: LoreTheme.warmBrown.withValues(
                                    alpha: 0.5,
                                  ),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: _showAddCharacterSheet,
                                icon: Icon(
                                  Icons.add,
                                  color: LoreTheme.goldAccent.withValues(
                                    alpha: 0.8,
                                  ),
                                ),
                                label: Text(
                                  'Add your first character',
                                  style: TextStyle(
                                    color: LoreTheme.goldAccent.withValues(
                                      alpha: 0.8,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _storyCharacters.length,
                          itemBuilder: (context, index) {
                            final char = _storyCharacters[index];
                            return _buildStoryCharacterCard(context, char);
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStoryCharacterCard(BuildContext context, Character char) {
    final topSkill = char.skills.isNotEmpty
        ? char.skills.values.reduce(
            (a, b) => a.currentLevel > b.currentLevel ? a : b,
          )
        : null;

    return Card(
      color: LoreTheme.deepBrown.withValues(alpha: 0.3),
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: LoreTheme.warmBrown.withValues(alpha: 0.15)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CharacterProgressionScreen(character: char),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Hero(
                tag: 'story_char_${char.id}',
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: LoreTheme.deepBrown,
                  child: Text(
                    char.name.isNotEmpty ? char.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: LoreTheme.goldAccent,
                      fontWeight: FontWeight.bold,
                      fontFamily: LoreTheme.serifFont,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      char.name,
                      style: const TextStyle(
                        color: LoreTheme.parchment,
                        fontWeight: FontWeight.bold,
                        fontFamily: LoreTheme.serifFont,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${char.race} · ${char.occupation}',
                      style: TextStyle(
                        color: LoreTheme.lightBrown.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                    ),
                    if (topSkill != null && topSkill.currentLevel > 0)
                      Text(
                        'Best: ${topSkill.name} (Lv.${topSkill.currentLevel})',
                        style: TextStyle(
                          color: LoreTheme.goldAccent.withValues(alpha: 0.5),
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ),
              // Remove button
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: LoreTheme.warmBrown.withValues(alpha: 0.5),
                  size: 20,
                ),
                color: LoreTheme.deepBrown,
                onSelected: (value) async {
                  if (value == 'remove') {
                    _removeCharacterFromStory(char);
                  } else if (value == 'edit') {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CharacterBuilderScreen(character: char),
                      ),
                    );
                    if (result == true) {
                      _loadCharacters(); // Refresh to get updated character data
                    }
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          color: LoreTheme.goldAccent.withOpacity(0.8),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Edit character',
                          style: TextStyle(color: LoreTheme.parchment),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(
                          Icons.remove_circle_outline,
                          color: Colors.red.shade300,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Remove from story',
                          style: TextStyle(color: LoreTheme.parchment),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Icon(
                Icons.chevron_right,
                color: LoreTheme.warmBrown.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDirectorsPanel(BuildContext context) {
    DirectorsPanel.show(
      context,
      story: widget.story,
      onSettingsChanged: ({String? narrationStyle, String? worldNotes}) {
        setState(() {
          if (narrationStyle != null) _narrationStyle = narrationStyle;
          if (worldNotes != null) _worldNotes = worldNotes;
        });
      },
    );
  }
}
