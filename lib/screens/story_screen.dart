import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import '../services/story_service.dart';
import '../services/story_management_service.dart';
import '../models/story.dart';
import 'character_progression_screen.dart';
import 'responsive_layout.dart';

class StoryScreen extends StatefulWidget {
  final String storyId;

  const StoryScreen({super.key, required this.storyId});

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> {
  Story? _story;
  late StoryProvider _storyProvider;
  StreamSubscription? _segmentsSubscription;
  String _narrationStyle =
      'Standard third-person narrative, descriptive and engaging.';
  String _worldNotes = 'A generic fantasy world.';
  final Map<String, Map<String, dynamic>> _textMetadata = {};

  // Voice services
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _isListening = false;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _storyProvider = StoryProvider(
      storyService: Provider.of<StoryService>(context, listen: false),
      storyId: widget.storyId,
      getNarrationStyle: () => _narrationStyle,
      getWorldNotes: () => _worldNotes,
    );
    _loadStory();
    _subscribeToSegments();
    _initVoice();
  }

  Future<void> _initVoice() async {
    await _speech.initialize();
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.5);
  }

  Future<void> _speak(String text) async {
    if (_isSpeaking) {
      await _tts.stop();
      setState(() => _isSpeaking = false);
    } else {
      setState(() => _isSpeaking = true);
      await _tts.speak(text);
      _tts.setCompletionHandler(() {
        setState(() => _isSpeaking = false);
      });
    }
  }

  Future<void> _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            if (val.finalResult) {
              setState(() => _isListening = false);
              // We can't easily inject into LlmChatView's text field,
              // but we can send the message directly if we have access to the provider.
              _storyProvider
                  .sendMessageStream(val.recognizedWords)
                  .listen((_) {});
            }
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _loadStory() async {
    final storyManagementService = StoryManagementService();
    final story = await storyManagementService.getStory(widget.storyId);
    if (mounted) {
      setState(() {
        _story = story;
      });
    }
  }

  void _subscribeToSegments() {
    final storyService = Provider.of<StoryService>(context, listen: false);
    _segmentsSubscription = storyService
        .getStorySegments(widget.storyId)
        .listen((segments) {
          if (mounted) {
            // Reload story to get updated chapter/bookmark
            _loadStory();

            final chatMessages = <ChatMessage>[];
            _textMetadata.clear();
            for (var s in segments) {
              if (s.userPrompt != null) {
                chatMessages.add(
                  ChatMessage(
                    text: s.userPrompt!,
                    origin: MessageOrigin.user,
                    attachments: const [],
                  ),
                );
              }
              chatMessages.add(
                ChatMessage(
                  text: s.text,
                  origin: MessageOrigin.llm,
                  attachments: const [],
                ),
              );
              _textMetadata[s.text] = {
                'stateUpdates': s.stateUpdates,
                'choices': s.choices,
              };
            }
            setState(() {
              _storyProvider.history = chatMessages;
            });
          }
        });
  }

  @override
  void dispose() {
    _segmentsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black.withOpacity(0.7), Colors.transparent],
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_story?.title ?? 'Loreweaver Story'),
            if (_story != null)
              Text(
                'Chapter ${_story!.currentChapter}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.white70),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
            tooltip: 'Voice Input',
            onPressed: _listen,
          ),
          if (_story != null && _story!.characterIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.person),
              tooltip: 'Character Progression',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CharacterProgressionScreen(
                      characterId: _story!.characterIds.first,
                    ),
                  ),
                );
              },
            ),
          if (!isDesktop)
            Builder(
              builder: (context) {
                return IconButton(
                  icon: const Icon(Icons.tune),
                  tooltip: 'Director\'s Panel',
                  onPressed: () {
                    Scaffold.of(context).openEndDrawer();
                  },
                );
              },
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(
              begin: 0,
              end: (_story?.currentChapter ?? 1) / 10,
            ),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return LinearProgressIndicator(
                value: value,
                backgroundColor: Colors.white12,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFFD0BCFF),
                ),
              );
            },
          ),
        ),
      ),
      endDrawer: isDesktop
          ? null
          : DirectorPanel(
              initialNarrationStyle: _narrationStyle,
              initialWorldNotes: _worldNotes,
              onSave: (style, notes) {
                setState(() {
                  _narrationStyle = style;
                  _worldNotes = notes;
                });
              },
            ),
      body: Stack(
        children: [
          // Background Animation
          Positioned.fill(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(seconds: 10),
              builder: (context, value, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(
                        0.5 * (1 + 0.2 * math.sin(value * 2 * math.pi)),
                        0.5 * (1 + 0.2 * math.cos(value * 2 * math.pi)),
                      ),
                      radius: 1.5,
                      colors: const [
                        Color(0xFF1A1A2E),
                        Color(0xFF16213E),
                        Color(0xFF0F3460),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                flex: 7,
                child: Shortcuts(
                  shortcuts: <LogicalKeySet, Intent>{
                    LogicalKeySet(
                      LogicalKeyboardKey.control,
                      LogicalKeyboardKey.enter,
                    ): const SendMessageIntent(),
                  },
                  child: Actions(
                    actions: <Type, Action<Intent>>{
                      SendMessageIntent: CallbackAction<SendMessageIntent>(
                        onInvoke: (SendMessageIntent intent) {
                          // This is a bit tricky with flutter_ai_toolkit as it manages its own state
                          // but we can try to find the focus and trigger it if possible,
                          // or just rely on the toolkit's default behavior if it supports it.
                          return null;
                        },
                      ),
                    },
                    child: LlmChatView(
                      provider: _storyProvider,
                      style: LlmChatViewStyle(
                        backgroundColor: Colors.transparent,
                        userMessageStyle: UserMessageStyle(
                          textStyle: const TextStyle(color: Colors.white),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                        ),
                      ),
                      responseBuilder: (context, text) {
                        final metadata = _textMetadata[text];
                        final stateUpdates = metadata?['stateUpdates'];
                        final choices = metadata?['choices'] as List<dynamic>?;

                        return TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOut,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 20 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: Semantics(
                            label: 'Story segment: $text',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        text,
                                        style: GoogleFonts.merriweather(
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.volume_up,
                                        size: 20,
                                        color: Colors.white70,
                                      ),
                                      onPressed: () => _speak(text),
                                    ),
                                  ],
                                ),
                                if (stateUpdates != null) ...[
                                  const SizedBox(height: 8),
                                  _buildStateUpdates(stateUpdates),
                                ],
                                if (choices != null && choices.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    children: choices.asMap().entries.map((
                                      entry,
                                    ) {
                                      final index = entry.key;
                                      final choice = entry.value;
                                      return TweenAnimationBuilder<double>(
                                        tween: Tween<double>(begin: 0, end: 1),
                                        duration: Duration(
                                          milliseconds: 400 + (index * 100),
                                        ),
                                        curve: Curves.easeOutBack,
                                        builder: (context, value, child) {
                                          return Transform.scale(
                                            scale: value,
                                            child: child,
                                          );
                                        },
                                        child: ActionChip(
                                          label: Text(choice),
                                          backgroundColor: Colors.white
                                              .withOpacity(0.1),
                                          side: BorderSide(
                                            color: Colors.white.withOpacity(
                                              0.2,
                                            ),
                                          ),
                                          onPressed: () {
                                            _storyProvider
                                                .sendMessageStream(choice)
                                                .listen((_) {});
                                          },
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              if (isDesktop)
                VerticalDivider(width: 1, color: Colors.white.withOpacity(0.2)),
              if (isDesktop)
                SizedBox(
                  width: 350,
                  child: DirectorPanel(
                    initialNarrationStyle: _narrationStyle,
                    initialWorldNotes: _worldNotes,
                    showCloseButton: false,
                    onSave: (style, notes) {
                      setState(() {
                        _narrationStyle = style;
                        _worldNotes = notes;
                      });
                    },
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStateUpdates(Map<String, dynamic> updates) {
    final List<Widget> chips = [];

    if (updates.containsKey('health_change')) {
      final change = updates['health_change'] as num;
      chips.add(
        _AnimatedStatusChip(
          label: 'Health ${change >= 0 ? '+' : ''}${(change * 100).toInt()}%',
          icon: Icons.favorite,
          iconColor: change >= 0 ? Colors.green : Colors.red,
          semanticsLabel:
              'Health change: ${change >= 0 ? 'increased' : 'decreased'} by ${(change * 100).abs().toInt()}%',
        ),
      );
    }

    if (updates.containsKey('mood_change')) {
      final mood = updates['mood_change'];
      chips.add(
        _AnimatedStatusChip(
          label: 'Mood: $mood',
          icon: Icons.emoji_emotions,
          iconColor: Colors.orange,
          semanticsLabel: 'Mood changed to $mood',
        ),
      );
    }

    if (updates.containsKey('skill_usage')) {
      final skills = updates['skill_usage'] as List<dynamic>;
      for (var skill in skills) {
        chips.add(
          _AnimatedStatusChip(
            label: 'Skill: $skill +XP',
            icon: Icons.star,
            iconColor: Colors.amber,
            semanticsLabel: 'Skill improved: $skill',
          ),
        );
      }
    }

    if (updates.containsKey('relationship_change')) {
      final rel = updates['relationship_change'] as Map<String, dynamic>;
      final delta = rel['affinity_delta'] as num;
      chips.add(
        _AnimatedStatusChip(
          label: 'Relationship ${delta >= 0 ? '+' : ''}$delta',
          icon: Icons.people,
          iconColor: delta >= 0 ? Colors.blue : Colors.red,
          semanticsLabel:
              'Relationship with ${rel['character_id']} ${delta >= 0 ? 'improved' : 'worsened'} by $delta',
        ),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(spacing: 8.0, runSpacing: 4.0, children: chips);
  }
}

class _AnimatedStatusChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final String semanticsLabel;

  const _AnimatedStatusChip({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: Semantics(
        label: semanticsLabel,
        child: Chip(
          avatar: Icon(icon, size: 16, color: iconColor),
          label: Text(label),
          backgroundColor: Colors.white.withOpacity(0.05),
          side: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
    );
  }
}

class SendMessageIntent extends Intent {
  const SendMessageIntent();
}

class StoryProvider extends LlmProvider with ChangeNotifier {
  final StoryService storyService;
  final String storyId;
  final String Function() getNarrationStyle;
  final String Function() getWorldNotes;

  Iterable<ChatMessage> _history = [];

  StoryProvider({
    required this.storyService,
    required this.storyId,
    required this.getNarrationStyle,
    required this.getWorldNotes,
  });

  @override
  Iterable<ChatMessage> get history => _history;

  @override
  set history(Iterable<ChatMessage> value) {
    _history = value;
    notifyListeners();
  }

  @override
  Stream<String> sendMessageStream(
    String prompt, {
    Iterable<Attachment> attachments = const [],
  }) async* {
    final result = await storyService.processSegment(
      storyId: storyId,
      userPrompt: prompt,
      narrationSlot: getNarrationStyle(),
      worldNotesSlot: getWorldNotes(),
    );
    yield result['text'] as String;
  }

  @override
  Stream<String> generateStream(
    String prompt, {
    Iterable<Attachment> attachments = const [],
  }) async* {
    yield* sendMessageStream(prompt, attachments: attachments);
  }
}

class DirectorPanel extends StatefulWidget {
  final String initialNarrationStyle;
  final String initialWorldNotes;
  final bool showCloseButton;
  final Function(String, String) onSave;

  const DirectorPanel({
    super.key,
    required this.initialNarrationStyle,
    required this.initialWorldNotes,
    this.showCloseButton = true,
    required this.onSave,
  });

  @override
  State<DirectorPanel> createState() => _DirectorPanelState();
}

class _DirectorPanelState extends State<DirectorPanel> {
  late String _narrationStyle;
  late TextEditingController _worldNotesController;

  @override
  void initState() {
    super.initState();
    _narrationStyle = widget.initialNarrationStyle;
    _worldNotesController = TextEditingController(
      text: widget.initialWorldNotes,
    );
  }

  @override
  void dispose() {
    _worldNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Director\'s Panel',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (widget.showCloseButton)
                  IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: () {
                      widget.onSave(
                        _narrationStyle,
                        _worldNotesController.text,
                      );
                      Navigator.pop(context);
                    },
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.save),
                    onPressed: () {
                      widget.onSave(
                        _narrationStyle,
                        _worldNotesController.text,
                      );
                    },
                  ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Narration Style',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _narrationStyle,
              items:
                  [
                    'Standard third-person narrative, descriptive and engaging.',
                    'Gritty and dark, focusing on the harsh realities.',
                    'Whimsical and lighthearted, like a fairy tale.',
                    'Action-oriented, fast-paced and punchy.',
                    'First-person intimate, focusing on internal thoughts.',
                  ].map((style) {
                    return DropdownMenuItem(
                      value: style,
                      child: Text(
                        style,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    );
                  }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _narrationStyle = value);
                }
              },
              isExpanded: true,
            ),
            const SizedBox(height: 24),
            Text('World Notes', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Expanded(
              child: TextField(
                controller: _worldNotesController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  hintText: 'Enter world details, lore, or current setting...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (widget.showCloseButton) {
      return Drawer(child: content);
    } else {
      return Material(child: content);
    }
  }
}
